import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});
  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String _category = '';
  String _search = '';
  String _sort = 'createdAt';
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final q = Uri(queryParameters: {
      if (_category.isNotEmpty) 'category': _category,
      if (_search.isNotEmpty) 'search': _search,
      'sort': _sort,
    }).query;
    final products = ref.watch(productsProvider(q));
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('🛒 Agri Shop'),
        actions: [
          Stack(children: [
            IconButton(
                icon: const Icon(Icons.storefront_outlined,
                    color: Colors.white),
                onPressed: () => context.push('/farmer/cart')),
            if (cartCount > 0)
              Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                          color: AppColors.amberLight, shape: BoxShape.circle),
                      child: Center(
                          child: Text('$cartCount',
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark))))),
          ]),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false, // In tab
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: 'Search seeds, fertilizers…',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary, size: 20),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.clear, color: AppColors.textTertiary, size: 20),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _search = '');
                                })
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                    const SizedBox(height: 16),
                    // Awesome Hero Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFF59E0B)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('KHARIF SPECIAL',
                                      style: TextStyle(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                          letterSpacing: 1.2)),
                                  const SizedBox(height: 2),
                                  const Text('Up to 40% Off',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          height: 1.15)),
                                  Text('on Fertilizers',
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500)),
                                ]),
                            const Text('🚜', style: TextStyle(fontSize: 42)),
                          ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('🔥 Hot Deals',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _FeaturedItem('🍅', 'Hybrid Seeds', 'Flat 20% OFF'),
                      _FeaturedItem('🧪', 'Soil Test Kit', '₹299 Only'),
                      _FeaturedItem('⚙️', 'Sprayer', 'Bestseller'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Category chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    _CatChip('All', '', _category == '', () => setState(() => _category = '')),
                    ...AppConstants.categories.map((c) => _CatChip(
                        c['icon']! + ' ' + c['label']!,
                        c['key']!,
                        _category == c['key'],
                        () => setState(() => _category = c['key']!))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

        // Products
          SliverFillRemaining(
            child: products.when(
              loading: () => const AppShimmerGrid(),
              error: (e, _) => AppErrorState(
                  message: 'Could not load products from the catalog',
                  onRetry: () => ref.invalidate(productsProvider)),
              data: (data) {
                final list = data['data'] as List? ?? [];
                if (list.isEmpty) {
                  return const AppEmptyState(
                      icon: '🌿',
                      title: 'No products found',
                      subtitle: 'Try clearing your search or category filters');
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(), // Handled by CustomScrollView
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) => _ProductCard(product: list[i] as Map),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label, value;
  final bool active;
  final VoidCallback onTap;
  const _CatChip(this.label, this.value, this.active, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? Colors.white : AppColors.textSecondary)),
        ),
      );
}

class _ProductCard extends ConsumerWidget {
  final Map product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/farmer/shop/product/${product['id']}'),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Container(
              height: 120,
              width: double.infinity,
              color: AppColors.primarySurface,
              child: product['images'] is List &&
                      (product['images'] as List).isNotEmpty
                  ? Image.network(product['images'][0],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                          child: Text('🌿', style: TextStyle(fontSize: 40))))
                  : const Center(
                      child: Text('🌿', style: TextStyle(fontSize: 40))),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product['isOrganic'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('🌱 ORGANIC',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                                letterSpacing: 0.5)),
                      ),
                    Text(product['name'] ?? '',
                        style: AppTextStyles.headingSM.copyWith(fontSize: 13, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(product['brand'] ?? '', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    const SizedBox(height: 8),
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('₹${product['price']}',
                                    style: AppTextStyles.priceSmall.copyWith(fontSize: 15)),
                                Text('/${product['unit']}',
                                    style: AppTextStyles.caption.copyWith(fontSize: 10)),
                              ]),
                          GestureDetector(
                            onTap: () async {
                              try {
                                await ref
                                    .read(cartProvider.notifier)
                                    .addItem(product['id'], 1);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Added to cart ✅'),
                                          backgroundColor: AppColors.primary,
                                          duration: Duration(seconds: 1)));
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Failed: $e'),
                                          backgroundColor: AppColors.error,
                                          duration: const Duration(seconds: 2)));
                                }
                              }
                            },
                            child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.add_shopping_cart,
                                    color: AppColors.primary, size: 18)),
                          ),
                        ]),
                  ])),
        ]),
      ),
    );
  }
}

class _FeaturedItem extends StatelessWidget {
  final String icon, title, deal;
  const _FeaturedItem(this.icon, this.title, this.deal);
  @override
  Widget build(BuildContext context) => Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const Spacer(),
            Icon(Icons.arrow_forward, size: 14, color: AppColors.primary.withValues(alpha: 0.5))
          ]),
          const Spacer(),
          Text(title,
              style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 11,
                  letterSpacing: -0.2,
                  fontWeight: FontWeight.bold)),
          Text(deal,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900)),
        ]),
      );
}
