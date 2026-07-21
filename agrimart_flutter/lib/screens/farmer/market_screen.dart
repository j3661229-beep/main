import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/agri_ui.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/providers/app_providers.dart';
import '../../../core/constants/app_constants.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import '../../../data/providers/auth_provider.dart';

final _selectedCategoryProvider = StateProvider<String?>((ref) => null);
final _marketTabProvider = StateProvider<int>((ref) => 0);

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
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FarmerTabHeader(
            emoji: '🛒',
            title: l10n.market,
            actions: [
              Stack(
                children: [
                  IconButton(
                    onPressed: () => context.push('/farmer/cart'),
                    icon: Icon(Icons.shopping_cart_outlined, color: Colors.white, size: r.rs(24)),
                  ),
                  if (cartCount > 0) Positioned(
                    right: 6, top: 6,
                    child: Container(
                      width: r.rs(18), height: 18,
                      decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                      child: Center(child: Text('$cartCount', style: GoogleFonts.inter(fontSize: r.sp(10), fontWeight: FontWeight.w700, color: Colors.white))),
                    ),
                  ),
                ],
              ),
            ],
            bottom: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(r.rs(14)),
              ),
              child: TabBar(
                controller: _tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                indicator: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(r.rs(12)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: l10n.buyInputsTab),
                  Tab(text: l10n.sellProduceTab),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _BuyTab(),
                _SellTab(),
              ],
            ),
          ),
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
    final r = context.r;
    final selectedCat = ref.watch(_selectedCategoryProvider);
    final productsAsync = ref.watch(productsProvider(selectedCat != null ? 'category=$selectedCat' : ''));

    return Column(
      children: [
        SizedBox(height: r.rs(12)),
        // Category filter chips
        FilterChipRow(
          options: ['All', ...AppConstants.categories.map((c) => c['label']!)],
          selected: selectedCat ?? 'All',
          onSelect: (val) => ref.read(_selectedCategoryProvider.notifier).state = val == 'All' ? null : val,
          accent: AppColors.farmerAccent,
        ),
        SizedBox(height: r.rs(12)),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.farmerAccent,
            onRefresh: () async => ref.invalidate(productsProvider),
            child: productsAsync.when(
              loading: () => GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding),
                gridDelegate: r.productGridDelegate(),
                itemCount: 6,
                itemBuilder: (_, __) => ShimmerBox(height: r.rs(200), radius: r.rs(16)),
              ),
              error: (e, _) => EmptyState(emoji: '⚠️', title: 'Could not load', subtitle: e.toString(), actionLabel: 'Retry', onAction: () => ref.invalidate(productsProvider)),
              data: (data) {
                final products = (data['data'] as List?) ?? [];
                if (products.isEmpty) return const EmptyState(emoji: '🛒', title: 'No products found', subtitle: 'Try a different category');
                return GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding),
                  gridDelegate: r.productGridDelegate(),
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
    final r = context.r;
    final List? images = product['images'] as List?;
    final imageUrl = product['imageUrl'] ?? (images != null && images.isNotEmpty ? images[0] : null);
    final name     = product['name'] ?? 'Product';
    final supplier = product['supplier']?['businessName'] ?? 'Supplier';
    final price    = (product['price'] as num?) ?? 0;
    final unit     = product['unit'] ?? 'kg';

    return GestureDetector(
      onTap: () => context.push('/farmer/market/product/${product['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(r.rs(16)),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(r.rs(16))),
              child: imageUrl != null
                  ? CachedNetworkImage(imageUrl: imageUrl, height: r.rh(120), width: double.infinity, fit: BoxFit.cover,
                      placeholder: (_, __) => ShimmerBox(height: r.rh(120), radius: 0),
                      errorWidget: (_, __, ___) => Container(height: r.rh(120), color: AppColors.farmerTint, child: Center(child: Text('🌱', style: TextStyle(fontSize: r.sp(40))))))
                  : Container(height: r.rh(120), color: AppColors.farmerTint, child: Center(child: Text('🌱', style: TextStyle(fontSize: r.sp(40))))),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(r.rs(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.inter(fontSize: r.sp(13), fontWeight: FontWeight.w500, color: AppColors.ink), maxLines: 2, overflow: TextOverflow.ellipsis),
                    SizedBox(height: r.rh(2)),
                    Text(supplier, style: GoogleFonts.inter(fontSize: r.sp(11), color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatRupee(price), style: GoogleFonts.spaceGrotesk(fontSize: r.sp(14), fontWeight: FontWeight.w700, color: AppColors.ink)),
                            Text('per $unit', style: GoogleFonts.inter(fontSize: r.sp(10), color: AppColors.muted)),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.rs(10))),
                            ));
                          },
                          child: Container(
                            width: r.rs(32), height: r.rh(32),
                            decoration: BoxDecoration(color: AppColors.farmerAccent, borderRadius: BorderRadius.circular(r.rs(10))),
                            child: Icon(Icons.add, color: Colors.white, size: r.sp(20)),
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

// ── Sell Tab — dealer rate comparison ─────────────────────

class _SellTab extends ConsumerWidget {
  const _SellTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.r;
    final l10n = AppLocalizations.of(context)!;
    final district = ref.watch(authProvider).user?.effectiveDistrict ?? 'Nashik';
    final rates = ref.watch(farmerDealerRatesProvider(district));

    return SingleChildScrollView(
      padding: EdgeInsets.all(r.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: r.rs(8)),
          Container(
            padding: EdgeInsets.all(r.rs(24)),
            decoration: BoxDecoration(
              gradient: AppColors.farmerGradient,
              borderRadius: BorderRadius.circular(r.rs(24)),
              boxShadow: AppColors.primaryShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💰', style: TextStyle(fontSize: r.sp(48))),
                SizedBox(height: r.rs(12)),
                Text(l10n.sellTabTitle, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(22), fontWeight: FontWeight.w800, color: Colors.white)),
                SizedBox(height: r.rs(8)),
                Text(l10n.sellTabSubtitle, style: GoogleFonts.inter(fontSize: r.sp(13), color: Colors.white.withValues(alpha: 0.85), height: 1.45)),
                SizedBox(height: r.rs(20)),
                rates.when(
                  loading: () => const ShimmerBox(height: 64, radius: 14),
                  error: (_, __) => Text(l10n.noRatesAvailable, style: GoogleFonts.inter(color: Colors.white70)),
                  data: (list) {
                    if (list.isEmpty) {
                      return Text(l10n.noRatesAvailable, style: GoogleFonts.inter(color: Colors.white70));
                    }
                    final sorted = List<Map>.from(list.map((e) => e as Map));
                    sorted.sort((a, b) {
                      final pa = (a['rate'] as num?) ?? (a['price'] as num?) ?? 0;
                      final pb = (b['rate'] as num?) ?? (b['price'] as num?) ?? 0;
                      return pb.compareTo(pa);
                    });
                    final top = sorted.first;
                    final crop = top['crop']?.toString() ?? top['commodity']?.toString() ?? 'Crop';
                    final rate = (top['rate'] as num?) ?? (top['price'] as num?) ?? 0;
                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(r.rs(16)),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(r.rs(16)),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.bestRateToday(district), style: GoogleFonts.inter(fontSize: r.sp(11), color: Colors.white70)),
                          SizedBox(height: r.rs(6)),
                          Row(
                            children: [
                              Text(crop, style: GoogleFonts.spaceGrotesk(fontSize: r.sp(18), fontWeight: FontWeight.w700, color: Colors.white)),
                              const Spacer(),
                              Text('${formatRupee(rate)}${l10n.perQuintalShort2}', style: GoogleFonts.spaceGrotesk(fontSize: r.sp(20), fontWeight: FontWeight.w800, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: r.rs(24)),
          AppButton(label: l10n.compareDealerRates, onTap: () => context.push('/farmer/dealer-rates'), color: AppColors.farmerAccent, icon: Icons.store_outlined),
          SizedBox(height: r.rs(12)),
          FarmerActionButton(label: l10n.myTradeBookings, icon: Icons.calendar_month_outlined, onTap: () => context.push('/farmer/trade/bookings'), isOutlined: true),
          SizedBox(height: r.rs(80)),
        ],
      ),
    );
  }
}

