import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/providers/app_providers.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/app_constants.dart';

final _selectedCategoryProvider = StateProvider<String?>((ref) => null);
final _marketTabProvider = StateProvider<int>((ref) => 0);

// Sell produce providers
final _sellCropProvider = StateProvider<String?>((ref) => null);
final _sellQtyProvider  = StateProvider<String>((ref) => '');
final _sellPriceProvider = StateProvider<String>((ref) => '');

class MarketScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const MarketScreen({super.key, this.initialTab = 0});
  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _tab.addListener(() => ref.read(_marketTabProvider.notifier).state = _tab.index);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.farmerAccent,
        foregroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        title: Text('Market', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () => context.push('/farmer/cart'),
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              ),
              if (cartCount > 0) Positioned(
                right: 6, top: 6,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                  child: Center(child: Text('$cartCount', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(child: Text('Buy Inputs', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600))),
            Tab(child: Text('Sell Produce', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _BuyTab(),
          _SellTab(),
        ],
      ),
    );
  }
}

// ── Buy Tab ───────────────────────────────────────────────

class _BuyTab extends ConsumerWidget {
  const _BuyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCat = ref.watch(_selectedCategoryProvider);
    final productsAsync = ref.watch(productsProvider(selectedCat != null ? 'category=$selectedCat' : ''));

    return Column(
      children: [
        const SizedBox(height: 12),
        // Category filter chips
        FilterChipRow(
          options: ['All', ...AppConstants.categories.map((c) => c['label']!)],
          selected: selectedCat ?? 'All',
          onSelect: (val) => ref.read(_selectedCategoryProvider.notifier).state = val == 'All' ? null : val,
          accent: AppColors.farmerAccent,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.farmerAccent,
            onRefresh: () async => ref.invalidate(productsProvider),
            child: productsAsync.when(
              loading: () => GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.78, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: 6,
                itemBuilder: (_, __) => const ShimmerBox(height: 200, radius: 16),
              ),
              error: (e, _) => EmptyState(emoji: '⚠️', title: 'Could not load', subtitle: e.toString(), actionLabel: 'Retry', onAction: () => ref.invalidate(productsProvider)),
              data: (data) {
                final products = (data['data'] as List?) ?? [];
                if (products.isEmpty) return const EmptyState(emoji: '🛒', title: 'No products found', subtitle: 'Try a different category');
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: products.length,
                  itemBuilder: (_, i) => _ProductCard(product: products[i]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final Map product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = product['imageUrl'] ?? product['images']?[0];
    final name     = product['name'] ?? 'Product';
    final supplier = product['supplier']?['businessName'] ?? 'Supplier';
    final price    = (product['price'] as num?) ?? 0;
    final unit     = product['unit'] ?? 'kg';

    return GestureDetector(
      onTap: () => context.push('/farmer/market/product/${product['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl != null
                  ? CachedNetworkImage(imageUrl: imageUrl, height: 120, width: double.infinity, fit: BoxFit.cover,
                      placeholder: (_, __) => const ShimmerBox(height: 120, radius: 0),
                      errorWidget: (_, __, ___) => Container(height: 120, color: AppColors.farmerTint, child: const Center(child: Text('🌱', style: TextStyle(fontSize: 40)))))
                  : Container(height: 120, color: AppColors.farmerTint, child: const Center(child: Text('🌱', style: TextStyle(fontSize: 40)))),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(supplier, style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatRupee(price), style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                            Text('per $unit', style: GoogleFonts.inter(fontSize: 10, color: AppColors.muted)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            ref.read(cartProvider.notifier).addItem(Map<String, dynamic>.from(product), 1);
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Added to cart', style: GoogleFonts.inter(color: Colors.white)),
                              backgroundColor: AppColors.farmerAccent,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ));
                          },
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: AppColors.farmerAccent, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.add, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sell Tab ──────────────────────────────────────────────

class _SellTab extends ConsumerStatefulWidget {
  const _SellTab();
  @override
  ConsumerState<_SellTab> createState() => _SellTabState();
}

class _SellTabState extends ConsumerState<_SellTab> {
  final _formKey  = GlobalKey<FormState>();
  final _qtyCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  String? _selectedCrop;
  bool _isSubmitting = false;
  bool _submitted = false;

  final _crops = AppConstants.popularCrops.map((c) => c['name']!).toList();

  @override
  void dispose() { _qtyCtrl.dispose(); _priceCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ApiService.instance.createProduceListing({
        'crop': _selectedCrop,
        'quantity': double.tryParse(_qtyCtrl.text),
        'expectedPrice': double.tryParse(_priceCtrl.text),
      });
      setState(() { _isSubmitting = false; _submitted = true; });
      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: ${e.toString()}'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✅', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text('Listed!', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.success)),
              const SizedBox(height: 8),
              Text('Your produce has been listed.\nDealers will contact you soon.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              AppButton(label: 'List Another', onTap: () => setState(() => _submitted = false), color: AppColors.farmerAccent, width: 180),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.dealerTint, borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('💰', style: TextStyle(fontSize: 20)))),
                      const SizedBox(width: 12),
                      Text('Sell Your Produce', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Crop dropdown
                  Text('Crop *', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedCrop,
                    hint: Text('Select crop', style: GoogleFonts.inter(color: AppColors.placeholder)),
                    decoration: InputDecoration(prefixIcon: const Icon(Icons.grass_outlined, color: AppColors.farmerAccent, size: 20)),
                    items: _crops.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter(fontSize: 14)))).toList(),
                    onChanged: (v) => setState(() => _selectedCrop = v),
                    validator: (v) => v == null ? 'Select a crop' : null,
                  ),
                  const SizedBox(height: 16),

                  // Quantity
                  Text('Quantity (quintals) *', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: const InputDecoration(hintText: '0.00', prefixIcon: Icon(Icons.scale_outlined, color: AppColors.farmerAccent, size: 20), suffixText: 'qtl'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter quantity';
                      if (double.tryParse(v) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Expected price
                  Text('Expected Price / quintal *', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: const InputDecoration(hintText: '0.00', prefixText: '₹ ', suffixText: '/qtl'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter expected price';
                      if (double.tryParse(v) == null) return 'Enter a valid price';
                      return null;
                    },
                  ),

                  // Live total
                  if (_qtyCtrl.text.isNotEmpty && _priceCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.dealerTint, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Estimated Value', style: GoogleFonts.inter(fontSize: 13, color: AppColors.dealerAccent, fontWeight: FontWeight.w500)),
                          Text(
                            formatRupee(((double.tryParse(_qtyCtrl.text) ?? 0) * (double.tryParse(_priceCtrl.text) ?? 0))),
                            style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dealerAccent),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  AppButton(
                    label: 'List Produce',
                    onTap: _submit,
                    isLoading: _isSubmitting,
                    color: AppColors.dealerAccent,
                    icon: Icons.sell_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

