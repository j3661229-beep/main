import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:animate_do/animate_do.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_fallback.dart';
import '../../core/widgets/app_shimmer.dart';
import '../../core/widgets/app_snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:agrimart/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

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
  // Location toggle state
  String? _customLocationName;  // null = GPS mode
  double? _customLat;
  double? _customLng;

  static const List<Map<String, dynamic>> _maharashtraDistricts = [
    {'name': 'Nashik', 'lat': 20.0063, 'lng': 73.7895},
    {'name': 'Pune', 'lat': 18.5204, 'lng': 73.8567},
    {'name': 'Nagpur', 'lat': 21.1458, 'lng': 79.0882},
    {'name': 'Mumbai', 'lat': 19.0760, 'lng': 72.8777},
    {'name': 'Aurangabad', 'lat': 19.8762, 'lng': 75.3433},
    {'name': 'Kolhapur', 'lat': 16.7050, 'lng': 74.2433},
    {'name': 'Solapur', 'lat': 17.6599, 'lng': 75.9064},
    {'name': 'Sangli', 'lat': 16.8524, 'lng': 74.5815},
    {'name': 'Satara', 'lat': 17.6805, 'lng': 74.0183},
    {'name': 'Ahmednagar', 'lat': 19.0948, 'lng': 74.7480},
    {'name': 'Jalgaon', 'lat': 21.0077, 'lng': 75.5626},
    {'name': 'Dhule', 'lat': 20.9042, 'lng': 74.7749},
    {'name': 'Nanded', 'lat': 19.1383, 'lng': 77.3210},
    {'name': 'Latur', 'lat': 18.3968, 'lng': 76.5604},
    {'name': 'Amravati', 'lat': 20.9374, 'lng': 77.7796},
    {'name': 'Wardha', 'lat': 20.7453, 'lng': 78.6022},
    {'name': 'Chandrapur', 'lat': 19.9615, 'lng': 79.2961},
    {'name': 'Beed', 'lat': 18.9890, 'lng': 75.7600},
    {'name': 'Osmanabad', 'lat': 18.1860, 'lng': 76.0350},
    {'name': 'Parbhani', 'lat': 19.2610, 'lng': 76.7760},
    {'name': 'Hingoli', 'lat': 19.7200, 'lng': 77.1500},
    {'name': 'Jalna', 'lat': 19.8347, 'lng': 75.8816},
    {'name': 'Ratnagiri', 'lat': 16.9944, 'lng': 73.3000},
    {'name': 'Sindhudurg', 'lat': 16.3489, 'lng': 73.7555},
    {'name': 'Thane', 'lat': 19.2183, 'lng': 72.9781},
    {'name': 'Raigad', 'lat': 18.5166, 'lng': 73.1843},
    {'name': 'Yavatmal', 'lat': 20.3888, 'lng': 78.1204},
    {'name': 'Akola', 'lat': 20.7059, 'lng': 77.0025},
    {'name': 'Washim', 'lat': 20.1042, 'lng': 77.1332},
    {'name': 'Buldhana', 'lat': 20.5293, 'lng': 76.1843},
    {'name': 'Gondia', 'lat': 21.4602, 'lng': 80.1920},
    {'name': 'Bhandara', 'lat': 21.1669, 'lng': 79.6504},
    {'name': 'Gadchiroli', 'lat': 20.1809, 'lng': 80.0000},
    {'name': 'Nandurbar', 'lat': 21.3700, 'lng': 74.2400},
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Try to open settings if service not enabled
        if (mounted) {
          AppSnackbar.info(context, 'Please enable GPS/Location services');
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          AppSnackbar.info(context, 'Location permission denied. Go to Settings to enable.');
        }
        return;
      }
      // ✅ Use HIGH accuracy + timeout to get precise GPS fix (fixes Konkan Division bug)
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (mounted) setState(() => _position = pos);
      debugPrint('✅ Location: ${pos.latitude}, ${pos.longitude}');
    } on LocationServiceDisabledException {
      debugPrint('Location service disabled');
    } on PermissionDeniedException catch (e) {
      debugPrint('Permission denied: $e');
    } catch (e) {
      // Fallback: try with balanced power (less accurate but faster)
      try {
        final pos = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
              ),
            );
        if (mounted) setState(() => _position = pos);
      } catch (_) {
        debugPrint('Location fallback failed: $_');
      }
    }
  }

  double? get _effectiveLat => _customLat ?? _position?.latitude;
  double? get _effectiveLng => _customLng ?? _position?.longitude;
  String get _effectiveLocationName {
    if (_customLocationName != null) return _customLocationName!;
    if (_position != null) {
      // Show approximate coordinates label while geocoding not available
      // Use nearest district lookup for display
      return _findNearestDistrict(_position!.latitude, _position!.longitude) ?? 
             'GPS: ${_position!.latitude.toStringAsFixed(3)}, ${_position!.longitude.toStringAsFixed(3)}';
    }
    return 'Detecting location...';
  }

  String? _findNearestDistrict(double lat, double lng) {
    double minDist = double.infinity;
    String? nearest;
    for (final d in _maharashtraDistricts) {
      final dlat = (d['lat'] as double) - lat;
      final dlng = (d['lng'] as double) - lng;
      final dist = dlat * dlat + dlng * dlng;
      if (dist < minDist) {
        minDist = dist;
        nearest = d['name'] as String;
      }
    }
    // Only return if reasonably close (within ~50km)
    return minDist < 0.25 ? nearest : null;
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LocationPickerSheet(
        currentLocation: _customLocationName,
        districts: _maharashtraDistricts,
        onUseGPS: () {
          setState(() { _customLocationName = null; _customLat = null; _customLng = null; });
          Navigator.pop(ctx);
        },
        onSelectDistrict: (district) {
          setState(() {
            _customLocationName = district['name'] as String;
            _customLat = district['lat'] as double;
            _customLng = district['lng'] as double;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Map<String, dynamic>? _getCartItem(AsyncValue cart, String productId) {
    if (!cart.hasValue) return null;
    final data = cart.value;
    if (data is! Map) return null;
    final items = data['items'] as List? ?? [];
    for (var item in items) {
      if (item['productId'] == productId ||
          item['product']?['id'] == productId) {
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
      if (_effectiveLat != null) 'lat': _effectiveLat.toString(),
      if (_effectiveLng != null) 'lng': _effectiveLng.toString(),
    }).query;

    final products = ref.watch(productsProvider(q));
    final nearbySuppliers = _effectiveLat == null
        ? const AsyncValue<List>.data([])
        : ref.watch(nearbySuppliersProvider(
            '$_effectiveLat,$_effectiveLng',
          ));
    final cartAsync = ref.watch(cartProvider);

    int totalItems = 0;
    double totalPrice = 0;
    if (cartAsync.hasValue && cartAsync.value is Map) {
      final data = cartAsync.value as Map;
      final items = data['items'] as List? ?? [];
      for (var item in items) {
        totalItems += (item['quantity'] as int? ?? 1);
        totalPrice += ((item['product']?['price'] as num? ?? 0) *
            (item['quantity'] as num? ?? 1));
      }
    }

    final l10n = AppLocalizations.of(context)!;
    final locationName = _effectiveLocationName;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(productsProvider(q));
          if (_effectiveLat != null) {
            ref.invalidate(nearbySuppliersProvider(
              '$_effectiveLat,$_effectiveLng',
            ));
          }
          try {
            await ref.read(productsProvider(q).future);
          } catch (_) {}
        },
        child: Stack(
          children: [
            CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SwiggyHeaderDelegate(
                    locationName: locationName,
                    isCustomLocation: _customLocationName != null,
                    searchCtrl: _searchCtrl,
                    searchQuery: _search,
                    onSearchChanged: (v) => setState(() => _search = v),
                    onClearSearch: () {
                      _searchCtrl.clear();
                      setState(() => _search = '');
                    },
                    onLocationTap: _showLocationPicker,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Carousel / Hot Deals (Swiggy Horizontal Promos)
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        child: SizedBox(
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
                                  colors: const [
                                    Color(0xFFFFD700),
                                    Color(0xFFF59E0B)
                                  ]),
                              _PromoBanner(
                                  title: 'NEW ARRIVALS',
                                  subtitle: 'Hybrid Seeds for Better Yield',
                                  emoji: '🌱',
                                  colors: const [
                                    AppColors.success,
                                    Color(0xFF059669)
                                  ]),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // "Explore By Category" Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(l10n.exploreByCategory,
                            style: AppTextStyles.headingMD),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: AppConstants.categories.length + 1,
                        itemBuilder: (ctx, i) {
                          if (i == 0) {
                            return _CategoryGridItem(
                              label: l10n.all,
                              icon: '🏪',
                              color: Colors.grey.shade200,
                              iconColor: Colors.black87,
                              isSelected: _category == '',
                              onTap: () => setState(() => _category = ''),
                            );
                          }
                          final c = AppConstants.categories[i - 1];
                          return _CategoryGridItem(
                            label: c['label']!,
                            icon: c['icon']!,
                            color: AppColors.primarySurface,
                            iconColor: AppColors.primary,
                            isSelected: _category == c['key'],
                            onTap: () => setState(() => _category = c['key']!),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.sortBy,
                              style: AppTextStyles.labelMD.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _SortChip(
                                    label: l10n.nearest,
                                    selected: _sort == 'nearest',
                                    onTap: () {
                                      if (_position == null) {
                                        AppSnackbar.info(
                                          context,
                                          'Turn on location to sort by distance',
                                        );
                                        return;
                                      }
                                      setState(() => _sort = 'nearest');
                                    },
                                  ),
                                  _SortChip(
                                    label: l10n.newest,
                                    selected: _sort == 'createdAt',
                                    onTap: () =>
                                        setState(() => _sort = 'createdAt'),
                                  ),
                                  _SortChip(
                                    label: l10n.priceAsc,
                                    selected: _sort == 'price_asc',
                                    onTap: () =>
                                        setState(() => _sort = 'price_asc'),
                                  ),
                                  _SortChip(
                                    label: l10n.priceDesc,
                                    selected: _sort == 'price_desc',
                                    onTap: () =>
                                        setState(() => _sort = 'price_desc'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(l10n.availableNearYou,
                            style: AppTextStyles.headingMD),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 170,
                        child: nearbySuppliers.when(
                          loading: () => ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: List.generate(
                              3,
                              (_) => Container(
                                width: 220,
                                margin: const EdgeInsets.only(right: 12),
                                child: const AppShimmerCard(),
                              ),
                            ),
                          ),
                          error: (e, _) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(Icons.wifi_off_rounded,
                                    color: AppColors.textSecondary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Could not load nearby suppliers',
                                    style: AppTextStyles.bodySM.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                if (_effectiveLat != null) TextButton(
                                  onPressed: () => ref.invalidate(
                                    nearbySuppliersProvider(
                                      '$_effectiveLat,$_effectiveLng',
                                    ),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                          data: (suppliers) {
                            if (suppliers.isEmpty)
                              return const SizedBox.shrink();
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: suppliers.length,
                              itemBuilder: (context, i) => _NearbySupplierCard(
                                supplier: suppliers[i] as Map,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                // Products Grid
                SliverPadding(
                  padding:
                      EdgeInsets.fromLTRB(16, 0, 16, totalItems > 0 ? 180 : 100),
                  sliver: products.when(
                    loading: () =>
                        const SliverToBoxAdapter(child: AppShimmerGrid()),
                    error: (e, _) => SliverToBoxAdapter(
                        child: AppErrorState(
                            message: _extractErrorMessage(e),
                            onRetry: () =>
                                ref.invalidate(productsProvider(q)))),
                    data: (data) {
                      final list = data['data'] as List? ?? [];
                      if (list.isEmpty) {
                        return SliverToBoxAdapter(
                            child: AppEmptyState(
                                icon: '🌿',
                                title: l10n.noProductsFound,
                                subtitle: l10n.clearFiltersSubtitle));
                      }
                      return SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75, // Better space utilization
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
                                    HapticFeedback.mediumImpact();
                                    if (newQty == 0 && cartItemId != null) {
                                      await ref
                                          .read(cartProvider.notifier)
                                          .removeItem(cartItemId);
                                    } else if (cartItemId != null) {
                                      await ref
                                          .read(cartProvider.notifier)
                                          .updateItem(cartItemId, newQty);
                                    } else if (newQty > 0) {
                                      await ref
                                          .read(cartProvider.notifier)
                                          .addItem(Map<String, dynamic>.from(p),
                                              newQty);
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      AppSnackbar.error(
                                        context,
                                        'Could not update cart. Try again.',
                                      );
                                    }
                                  }
                                });
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
                bottom: 24,
                left: 16,
                right: 16,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      context.push('/farmer/cart');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981), // Swiggy green
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5))
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                               Text(
                                  '$totalItems ${totalItems > 1 ? l10n.itemsCount : l10n.itemCount}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text('₹${totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5)),
                            ],
                          ),
                          Row(
                            children: [
                              Text(l10n.viewCart,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_ios,
                                  color: Colors.white, size: 16),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  /// Extracts a clean user-facing message from any exception (avoids DioClientException dump)
  static String _extractErrorMessage(Object e) {
    final s = e.toString();
    // DioException wraps AppException in .message — extract it
    if (s.contains('DioException') || s.contains('DioError') || s.contains('ClientException')) {
      // Try to find our clean message after common prefixes
      final patterns = [
        RegExp(r'message: (.+?)(?:\.|,|\n|\]|$)'),
        RegExp(r'AppException: (.+?)(?:\.|,|\n|$)'),
        RegExp(r'ServerException: (.+?)(?:\.|,|\n|$)'),
        RegExp(r'NetworkException: (.+?)(?:\.|,|\n|$)'),
      ];
      for (final p in patterns) {
        final m = p.firstMatch(s);
        if (m != null && m.group(1) != null && m.group(1)!.trim().isNotEmpty) {
          return m.group(1)!.trim();
        }
      }
      if (s.contains('SocketException') || s.contains('connection')) {
        return 'No internet connection. Please check your network.';
      }
      return 'Server error. Please try again.';
    }
    // Already a clean AppException
    if (s.length < 120) return s;
    return 'Something went wrong. Please retry.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _ProductCardSwiggy extends StatelessWidget {
  final Map product;
  final int cartQty;
  final Function(int) onUpdateCart;

  const _ProductCardSwiggy(
      {required this.product,
      required this.cartQty,
      required this.onUpdateCart});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FadeInUp(
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 10),
              )
            ],
            border: Border.all(color: AppColors.border.withValues(alpha: 0.4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image Area
          Expanded(
            child: Stack(
              children: [
                Hero(
                  tag: 'product_${product['id']}',
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(23)),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface.withValues(alpha: 0.3),
                      ),
                      child: product['images'] is List &&
                              (product['images'] as List).isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product['images'][0],
                              memCacheWidth: 400,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Center(
                                  child: Text('🌿',
                                      style: TextStyle(fontSize: 40))),
                            )
                          : const Center(
                              child:
                                  Text('🌿', style: TextStyle(fontSize: 40))),
                    ),
                  ),
                ),
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
                if (product['isOrganic'] == true)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)
                            ]),
                        child: Row(
                          children: [
                            const Text('🌱', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 4),
                            Text(l10n.organic,
                                style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.success,
                                    letterSpacing: 0.5)),
                          ],
                        )),
                  ),
              ],
            ),
          ),

          // Details Area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'] ?? '',
                    style: AppTextStyles.headingSM
                        .copyWith(fontSize: 15, height: 1.2, fontWeight: FontWeight.w800),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text('${product['brand'] ?? 'Local'} • ${product['unit']}',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11, 
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    )),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${product['price']}',
                        style: AppTextStyles.priceSmall.copyWith(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5)),

                    // ADD BUTTON / QTY SELECTOR
                    if (cartQty == 0)
                      GestureDetector(
                        onTap: () => onUpdateCart(1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
                              ]),
                          child: Text(l10n.add,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 0.5)),
                        ),
                      )
                    else
                      Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))
                            ]
                          ),
                          child: Row(children: [
                            GestureDetector(
                              onTap: () => onUpdateCart(cartQty - 1),
                              child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.remove,
                                      color: Colors.white, size: 14)),
                            ),
                            Text('$cartQty',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13)),
                            GestureDetector(
                              onTap: () => onUpdateCart(cartQty + 1),
                              child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.add,
                                      color: Colors.white, size: 14)),
                            ),
                          ]))
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

  const _CategoryGridItem(
      {required this.label,
      required this.icon,
      required this.color,
      required this.iconColor,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryDark : color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: AppColors.amber, width: 2)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8)
                        ]
                      : null),
              child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 32))),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                  letterSpacing: -0.2),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          ],
        ));
  }
}

class _PromoBanner extends StatelessWidget {
  final String title, subtitle, emoji;
  final List<Color> colors;
  const _PromoBanner(
      {required this.title,
      required this.subtitle,
      required this.emoji,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: colors.last.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4))
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
                Text(title,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.15)),
              ],
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 48)),
        ],
      ),
    );
  }
}

class _NearbySupplierCard extends StatelessWidget {
  final Map supplier;
  const _NearbySupplierCard({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final products = supplier['products'] as List? ?? [];
    final l10n = AppLocalizations.of(context)!;

    return FadeInLeft(
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Supplier Info Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primarySurface.withValues(alpha: 0.3),
                      Colors.white,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Center(child: Text('🏬', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier['businessName']?.toString() ?? l10n.store,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headingSM.copyWith(fontSize: 15),
                          ),
                          Text(
                            '${supplier['distanceKm'] ?? '--'} km away',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Featured Products
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: products.isNotEmpty
                    ? Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: products.take(2).map((p) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🌱', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  p['name']?.toString() ?? 'Product',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    : Text(
                        l10n.noProductsAvailable,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                      ),
              ),
              
              // View Button
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      l10n.viewShop,
                      style: AppTextStyles.labelMD.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwiggyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String locationName;
  final bool isCustomLocation;
  final TextEditingController searchCtrl;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onLocationTap;

  _SwiggyHeaderDelegate(
      {required this.locationName,
      this.isCustomLocation = false,
      required this.searchCtrl,
      required this.searchQuery,
      required this.onSearchChanged,
      required this.onClearSearch,
      required this.onLocationTap});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = shrinkOffset / maxExtent;
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // Glassmorphism Background
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.95),
                    AppColors.primaryDark.withValues(alpha: 0.9),
                  ],
                ),
                boxShadow: progress > 0.8
                    ? [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]
                    : null,
              ),
            ),
          ),
        ),
        
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    FadeInLeft(
                      child: Icon(
                        isCustomLocation ? Icons.pin_drop : Icons.location_on,
                        color: isCustomLocation ? const Color(0xFFFBBF24) : Colors.white, 
                        size: 28
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: onLocationTap,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isCustomLocation ? l10n.browsing : l10n.pickupLocation,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16)
                                ),
                                const Icon(Icons.keyboard_arrow_down,
                                    color: Colors.white, size: 20),
                              ],
                            ),
                            Text(
                              locationName,
                              style: TextStyle(
                                  color: isCustomLocation ? const Color(0xFFFBBF24) : Colors.white70, 
                                  fontSize: 12
                              ),
                              overflow: TextOverflow.ellipsis
                            ),
                          ],
                        ),
                      ),
                    ),
                    FadeInRight(
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2), 
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1))
                        ),
                        child: const Icon(Icons.person_outline, color: Colors.white),
                      ),
                    )
                  ],
                ),
                
                // Content that fades out as we shrink
                if (progress < 0.5)
                  Expanded(
                    child: FadeIn(
                      duration: const Duration(milliseconds: 300),
                      child: const Center(
                        child: Text(
                          '', // Placeholder for potential tagline
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                
                // Search Bar
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: l10n.searchProducts,
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.primary, size: 24),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppColors.textTertiary),
                                onPressed: onClearSearch,
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  double get maxExtent => 180.0;
  @override
  double get minExtent => 140.0;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCATION PICKER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _LocationPickerSheet extends StatefulWidget {
  final String? currentLocation;
  final List<Map<String, dynamic>> districts;
  final VoidCallback onUseGPS;
  final Function(Map<String, dynamic>) onSelectDistrict;

  const _LocationPickerSheet({
    this.currentLocation,
    required this.districts,
    required this.onUseGPS,
    required this.onSelectDistrict,
  });

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  String _filter = '';
  final _filterCtrl = TextEditingController();

  List<Map<String, dynamic>> get _filtered {
    if (_filter.isEmpty) return widget.districts;
    return widget.districts.where((d) => (d['name'] as String).toLowerCase().contains(_filter.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Choose Location', style: AppTextStyles.headingXL),
              const SizedBox(height: 4),
              Text('Browse products from a different area', style: AppTextStyles.bodySM.copyWith(color: AppColors.textSecondary)),
            ]),
          ),
          const SizedBox(height: 20),

          // GPS option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: widget.onUseGPS,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.currentLocation == null ? AppColors.primarySurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: widget.currentLocation == null ? AppColors.primary : AppColors.border),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: widget.currentLocation == null ? AppColors.primary : AppColors.surfaceVariant, shape: BoxShape.circle),
                    child: Icon(Icons.my_location, color: widget.currentLocation == null ? Colors.white : AppColors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('📍 Use Current Location', style: AppTextStyles.headingSM),
                    Text('Products near your GPS location', style: AppTextStyles.caption),
                  ])),
                  if (widget.currentLocation == null) const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _filterCtrl,
              decoration: InputDecoration(
                hintText: 'Search district...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                suffixIcon: _filter.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _filterCtrl.clear(); setState(() => _filter = ''); }) : null,
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          const SizedBox(height: 12),

          // District list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final d = _filtered[i];
                final isSelected = widget.currentLocation == d['name'];
                return GestureDetector(
                  onTap: () => widget.onSelectDistrict(d),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primarySurface : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Row(children: [
                      Text('📌', style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(d['name'] as String, style: AppTextStyles.headingSM.copyWith(color: isSelected ? AppColors.primary : AppColors.textPrimary))),
                      if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
