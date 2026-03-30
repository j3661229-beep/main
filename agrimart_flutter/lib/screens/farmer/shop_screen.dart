import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/auth_provider.dart';
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
  Position? _position;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _position = pos);
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Map<String, dynamic>? _getCartItem(AsyncValue cart, String productId) {
    if (!cart.hasValue) return null;
    final data = cart.value;
    if (data is! Map) return null;
    final items = data['items'] as List? ?? [];
    for (var item in items) {
      if (item['productId'] == productId || item['product']?['id'] == productId) {
        return item as Map<String, dynamic>;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final q = Uri(queryParameters: {
      if (_category.isNotEmpty) 'category': _category,
      if (_search.isNotEmpty) 'search': _search,
      'sort': _sort,
      if (_position != null) 'lat': _position!.latitude.toString(),
      if (_position != null) 'lng': _position!.longitude.toString(),
    }).query;
    
    final products = ref.watch(productsProvider(q));
    final cartAsync = ref.watch(cartProvider);
    
    int totalItems = 0;
    double totalPrice = 0;
    if (cartAsync.hasValue && cartAsync.value is Map) {
      final data = cartAsync.value as Map;
      final items = data['items'] as List? ?? [];
      for (var item in items) {
         totalItems += (item['quantity'] as int? ?? 1);
         totalPrice += ((item['product']?['price'] as num? ?? 0) * (item['quantity'] as num? ?? 1));
      }
    }

    final user = ref.watch(authProvider).user;
    final locationName = user?.farmer?['village'] as String? ?? 'Your Farm';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: Stack(
          children: [
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SwiggyHeaderDelegate(
                    locationName: locationName,
                    searchCtrl: _searchCtrl,
                    searchQuery: _search,
                    onSearchChanged: (v) => setState(() => _search = v),
                    onClearSearch: () {
                      _searchCtrl.clear();
                      setState(() => _search = '');
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Carousel / Hot Deals (Swiggy Horizontal Promos)
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 140,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const BouncingScrollPhysics(),
                          children: [
                             _PromoBanner(
                                title: 'KHARIF SPECIAL',
                                subtitle: 'Up to 40% Off on Fertilizers',
                                emoji: '🚜',
                                colors: const [Color(0xFFFFD700), Color(0xFFF59E0B)]
                             ),
                             _PromoBanner(
                                title: 'NEW ARRIVALS',
                                subtitle: 'Hybrid Seeds for Better Yield',
                                emoji: '🌱',
                                colors: const [AppColors.success, Color(0xFF059669)]
                             ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    
                    // "Explore By Category" Grid
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Explore by Category', style: AppTextStyles.headingMD),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: AppConstants.categories.length + 1,
                      itemBuilder: (ctx, i) {
                        if (i == 0) {
                          return _CategoryGridItem(
                            label: 'All', icon: '🏪',
                            color: Colors.grey.shade200, iconColor: Colors.black87,
                            isSelected: _category == '',
                            onTap: () => setState(() => _category = ''),
                          );
                        }
                        final c = AppConstants.categories[i - 1];
                        return _CategoryGridItem(
                          label: c['label']!, icon: c['icon']!,
                          color: AppColors.primarySurface, iconColor: AppColors.primary,
                          isSelected: _category == c['key'],
                          onTap: () => setState(() => _category = c['key']!),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Available Near You', style: AppTextStyles.headingMD),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Products Grid
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, totalItems > 0 ? 100 : 20),
                sliver: products.when(
                  loading: () => const SliverToBoxAdapter(child: AppShimmerGrid()),
                  error: (e, _) => SliverToBoxAdapter(
                     child: AppErrorState(message: 'Could not load products', onRetry: () => ref.invalidate(productsProvider))
                  ),
                  data: (data) {
                    final list = data['data'] as List? ?? [];
                    if (list.isEmpty) {
                      return const SliverToBoxAdapter(
                         child: AppEmptyState(icon: '🌿', title: 'No products found', subtitle: 'Try clearing your search or category filters')
                      );
                    }
                    return SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final p = list[i] as Map;
                          final cartItem = _getCartItem(cartAsync, p['id']);
                          final qty = cartItem?['quantity'] as int? ?? 0;
                          final cartItemId = cartItem?['id'] as String?;
                          return _ProductCardSwiggy(
                            product: p,
                            cartQty: qty,
                            onUpdateCart: (int newQty) async {
                               try {
                                  if (newQty == 0 && cartItemId != null) {
                                     await ref.read(cartProvider.notifier).removeItem(cartItemId);
                                  } else if (cartItemId != null) {
                                     await ref.read(cartProvider.notifier).updateItem(cartItemId, newQty);
                                  } else if (newQty > 0) {
                                     await ref.read(cartProvider.notifier).addItem(p['id'], newQty);
                                  }
                               } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
                                  }
                               }
                            }
                          );
                        },
                        childCount: list.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // 2. Floating Persistent Cart Bar (Bottom)
          if (totalItems > 0)
            Positioned(
              bottom: 24, left: 16, right: 16,
              child: GestureDetector(
                onTap: () => context.push('/farmer/cart'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981), // Swiggy green
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$totalItems Item${totalItems > 1 ? 's' : ''}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('₹${totalPrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ],
                      ),
                      Row(
                        children: const [
                          Text('View Cart', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _ProductCardSwiggy extends StatelessWidget {
  final Map product;
  final int cartQty;
  final Function(int) onUpdateCart;

  const _ProductCardSwiggy({required this.product, required this.cartQty, required this.onUpdateCart});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/farmer/shop/product/${product['id']}'),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image Area
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Container(
                    width: double.infinity,
                    color: AppColors.primarySurface.withValues(alpha: 0.5),
                    child: product['images'] is List && (product['images'] as List).isNotEmpty
                        ? Image.network(product['images'][0],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(child: Text('🌿', style: TextStyle(fontSize: 40))))
                        : const Center(child: Text('🌿', style: TextStyle(fontSize: 40))),
                  ),
                ),
                if (product['isOrganic'] == true)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: const [
                          Text('🌱', style: TextStyle(fontSize: 10)),
                          SizedBox(width: 4),
                          Text('Organic', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.success)),
                        ],
                      )
                    ),
                  ),
              ],
            ),
          ),
          
          // Details Area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] ?? '',
                    style: AppTextStyles.headingSM.copyWith(fontSize: 13, height: 1.2),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${product['brand'] ?? 'Local'} • ${product['unit']}', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${product['price']}', style: AppTextStyles.priceSmall.copyWith(fontSize: 15)),
                    
                    // ADD BUTTON / QTY SELECTOR
                    if (cartQty == 0)
                      GestureDetector(
                        onTap: () => onUpdateCart(1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.primary.withValues(alpha: 0.05)
                          ),
                          child: const Text('ADD', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                      )
                    else
                      Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                           children: [
                              GestureDetector(
                                 onTap: () => onUpdateCart(cartQty - 1),
                                 child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.remove, color: Colors.white, size: 16)),
                              ),
                              Text('$cartQty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              GestureDetector(
                                 onTap: () => onUpdateCart(cartQty + 1),
                                 child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.add, color: Colors.white, size: 16)),
                              ),
                           ]
                        )
                      )
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _CategoryGridItem extends StatelessWidget {
  final String label, icon;
  final Color color, iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryGridItem({required this.label, required this.icon, required this.color, required this.iconColor, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
           Container(
             height: 64, width: 64,
             decoration: BoxDecoration(
               color: isSelected ? AppColors.primaryDark : color,
               shape: BoxShape.circle,
               border: isSelected ? Border.all(color: AppColors.amber, width: 2) : null,
               boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8)] : null
             ),
             child: Center(child: Text(icon, style: const TextStyle(fontSize: 32))),
           ),
           const SizedBox(height: 8),
           Text(
             label, 
             style: TextStyle(
               fontSize: 12, 
               fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
               color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
               letterSpacing: -0.2
             ),
             textAlign: TextAlign.center,
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
           )
        ],
      )
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final String title, subtitle, emoji;
  final List<Color> colors;
  const _PromoBanner({required this.title, required this.subtitle, required this.emoji, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colors.last.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.15)),
              ],
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 48)),
        ],
      ),
    );
  }
}

class _SwiggyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String locationName;
  final TextEditingController searchCtrl;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  _SwiggyHeaderDelegate({
    required this.locationName, required this.searchCtrl, required this.searchQuery, required this.onSearchChanged, required this.onClearSearch
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Calculate expansion ratio 0.0 -> 1.0 (1.0 is fully shrunk)
    final progress = shrinkOffset / maxExtent;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
        boxShadow: progress > 0.8 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)] : null,
      ),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 16),
      child: Stack(
         children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 28),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                           children: const [
                              Text('Pickup from Store', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                              Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20)
                           ],
                        ),
                        Text(locationName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ]
                    ),
                    const Spacer(),
                    Container(
                       width: 40, height: 40,
                       decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                       child: const Icon(Icons.person, color: Colors.white),
                    )
                  ],
                ),
                ScaleTransition(
                  scale: AlwaysStoppedAnimation(1.0 - (progress * 0.5)),
                  child: FadeTransition(
                     opacity: AlwaysStoppedAnimation(1.0 - progress),
                     child: const SizedBox(height: 20),
                  )
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: 'Search for seeds, fertilizers...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 24),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                                onPressed: onClearSearch)
                            : const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('🎙️', style: TextStyle(fontSize: 16)),
                              ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      onChanged: onSearchChanged,
                    ),
                  ),
                ),
              ],
            )
         ],
      )
    );
  }

  @override
  double get maxExtent => 180.0;
  @override
  double get minExtent => 140.0;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
