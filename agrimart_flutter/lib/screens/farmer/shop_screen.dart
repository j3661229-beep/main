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
            IconButton(icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white), onPressed: () => context.push('/farmer/cart')),
            if (cartCount > 0) Positioned(right: 6, top: 6,
              child: Container(width: 16, height: 16, decoration: const BoxDecoration(color: AppColors.amberLight, shape: BoxShape.circle),
                child: Center(child: Text('$cartCount', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primaryDark))))),
          ]),
        ],
      ),
      body: Column(children: [
        // Search + filters
        Container(color: AppColors.primary, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Column(children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              fillColor: Colors.white,
              hintText: 'Search seeds, fertilizers…',
              prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
              suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppColors.textTertiary), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); }) : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 16),
          // Awesome Hero Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFF59E0B)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('KHARIF SPECIAL', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2)),
                SizedBox(height: 6),
                Text('Up to 40% Off\non Fertilizers', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.15)),
              ]),
              Text('🚜', style: TextStyle(fontSize: 54)),
            ]),
          ),
          const SizedBox(height: 16),
          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _CatChip('All', '', _category == '', () => setState(() => _category = '')),
              ...AppConstants.categories.map((c) => _CatChip(c['icon']! + ' ' + c['label']!, c['key']!, _category == c['key'], () => setState(() => _category = c['key']!))),
            ]),
          ),
        ])),

        // Products
        Expanded(child: products.when(
          loading: () => const AppShimmerGrid(),
          error: (e, _) => AppErrorState(message: 'Could not load products from the catalog', onRetry: () => ref.invalidate(productsProvider)),
          data: (data) {
            final list = data['data'] as List? ?? [];
            if (list.isEmpty) return const AppEmptyState(icon: '🌿', title: 'No products found', subtitle: 'Try clearing your search or category filters');
            return GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: list.length,
              itemBuilder: (ctx, i) => _ProductCard(product: list[i] as Map),
            );
          },
        )),
      ]),
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
        color: active ? AppColors.amberLight : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? AppColors.primaryDark : Colors.white)),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
          border: Border.all(color: AppColors.border.withOpacity(0.3))
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Container(
              height: 120, width: double.infinity,
              color: AppColors.primarySurface,
              child: product['images'] is List && (product['images'] as List).isNotEmpty
                ? Image.network(product['images'][0], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Text('🌿', style: TextStyle(fontSize: 40))))
                : const Center(child: Text('🌿', style: TextStyle(fontSize: 40))),
            ),
          ),
          Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (product['isOrganic'] == true) const Text('🌱 Organic', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
            Text(product['name'] ?? '', style: AppTextStyles.headingSM, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(product['brand'] ?? '', style: AppTextStyles.caption),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('₹${product['price']}', style: AppTextStyles.priceSmall),
                Text('/${product['unit']}', style: AppTextStyles.caption),
              ]),
              GestureDetector(
                onTap: () async {
                  try {
                    await ref.read(cartProvider.notifier).addItem(product['id'], 1);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart ✅'), backgroundColor: AppColors.primary, duration: Duration(seconds: 1)));
                  } catch (_) {}
                },
                child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18)),
              ),
            ]),
          ])),
        ]),
      ),
    );
  }
}
