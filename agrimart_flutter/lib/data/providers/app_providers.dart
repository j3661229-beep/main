import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../../core/utils/cache_manager.dart';
import '../../core/storage/offline_cache.dart';
import 'package:geolocator/geolocator.dart';

// ── Search & Trending ─────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<Map>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty)
    return {
      'data': [],
      'pagination': {'total': 0}
    };

  // Debounce: Wait for 300ms before calling API
  await Future.delayed(const Duration(milliseconds: 300));
  if (ref.read(searchQueryProvider) != query)
    return {
      'data': [],
      'pagination': {'total': 0}
    };

  return ApiService.instance.getProducts(search: query);
});

final trendingSearchesProvider = Provider<List<String>>((ref) {
  return ['Onion', 'Tomato', 'Fertilizer', 'Organic Seeds', 'Nashik Mandi'];
});

// ── Products ──────────────────────────────────────────────
final productsProvider =
    FutureProvider.family<Map, String>((ref, queryParams) async {
  ref.keepAlive();
  final uri = Uri(query: queryParams);

  try {
    final latStr = uri.queryParameters['lat'];
    final lngStr = uri.queryParameters['lng'];
    final data = await ApiService.instance.getProducts(
      category: uri.queryParameters['category'],
      search: uri.queryParameters['search'],
      sort: uri.queryParameters['sort'],
      page: int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1,
      lat: latStr != null ? double.tryParse(latStr) : null,
      lng: lngStr != null ? double.tryParse(lngStr) : null,
    );

    // Save to offline cache if it's the main list
    if (queryParams.isEmpty || queryParams == 'page=1') {
      if (data['data'] != null) await OfflineCache.saveProducts(data['data']);
    }

    return data;
  } catch (e) {
    // Fallback to offline cache on error
    final offline = await OfflineCache.getProducts();
    if (offline != null)
      return {
        'data': offline,
        'pagination': {'page': 1, 'total': offline.length}
      };
    rethrow;
  }
});

final productDetailProvider =
    FutureProvider.family<Map, String>((ref, id) async {
  return ApiService.instance.getProduct(id);
});

final nearbyProductsProvider =
    FutureProvider.family<List, String>((ref, coordsStr) async {
  final cacheKey = 'nearby_products_$coordsStr';
  final cached = CacheManager.get(cacheKey, maxAge: const Duration(hours: 1));

  if (cached != null) {
    // Return cached and refresh in background
    _refreshNearbyProducts(cacheKey, coordsStr);
    return List.from(cached);
  }

  final data = await _fetchNearbyProducts(coordsStr);
  await CacheManager.save(cacheKey, data);
  return data;
});

final nearbySuppliersProvider =
    FutureProvider.family<List, String>((ref, coordsStr) async {
  final parts = coordsStr.split(',');
  return ApiService.instance.getNearbySuppliers(
    lat: double.parse(parts[0]),
    lng: double.parse(parts[1]),
  );
});

Future<List> _fetchNearbyProducts(String coordsStr) async {
  final parts = coordsStr.split(',');
  return ApiService.instance.getNearbyProducts(
      lat: double.parse(parts[0]), lng: double.parse(parts[1]));
}

void _refreshNearbyProducts(String key, String coordsStr) async {
  try {
    final data = await _fetchNearbyProducts(coordsStr);
    await CacheManager.save(key, data);
  } catch (_) {}
}

final recommendedProductsProvider = FutureProvider<List>((ref) async {
  return ApiService.instance.getRecommendedProducts();
});

// ── Cart ──────────────────────────────────────────────────
class CartNotifier extends StateNotifier<AsyncValue<Map>> {
  CartNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      // 1. Instant load from cache
      final cached = CacheManager.get('local_cart');
      if (cached != null) {
        state = AsyncValue.data(jsonDecode(jsonEncode(cached)));
      }

      // 2. Refresh from server (Source of Truth)
      final serverCart = await ApiService.instance.getCart();
      state = AsyncValue.data(serverCart);
      await CacheManager.save('local_cart', serverCart);
    } catch (e, s) {
      if (!state.hasValue) state = AsyncValue.error(e, s);
    }
  }

  Future<void> _saveLocal() async {
    if (state.hasValue) {
      await CacheManager.save('local_cart', state.value!);
    }
  }

  Future<void> addItem(Map<String, dynamic> product, int quantity) async {
    final previousState = state;
    final current = state.valueOrNull != null
        ? Map<String, dynamic>.from(state.value!)
        : {'items': []};
    final items = List<Map<String, dynamic>>.from(current['items'] ?? []);

    final productId = product['id'] ?? product['_id'];
    final index = items.indexWhere((item) =>
        (item['productId'] == productId) ||
        (item['product']?['id'] == productId));

    // 1. Optimistic Update
    if (index >= 0) {
      items[index] = {
        ...items[index],
        'quantity': (items[index]['quantity'] as int) + quantity
      };
    } else {
      items.add({
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'productId': productId,
        'product': product,
        'quantity': quantity,
      });
    }

    current['items'] = items;
    state = AsyncValue.data(current);
    HapticFeedback.lightImpact(); // Premium feel

    // 2. API Call in background
    try {
      final updatedCart = await ApiService.instance
          .addToCart(productId: productId, quantity: quantity);
      state = AsyncValue.data(updatedCart);
      await _saveLocal();
    } catch (e) {
      // 3. Rollback on failure
      state = previousState;
    }
  }

  Future<void> updateItem(String itemId, int quantity) async {
    final previousState = state;
    final current = state.valueOrNull != null
        ? Map<String, dynamic>.from(state.value!)
        : {'items': []};
    final items = List<Map<String, dynamic>>.from(current['items'] ?? []);

    final index = items.indexWhere((item) => item['id'] == itemId);
    if (index >= 0) {
      final productId = items[index]['productId'];

      // 1. Optimistic Update
      items[index] = {...items[index], 'quantity': quantity};
      current['items'] = items;
      state = AsyncValue.data(current);
      HapticFeedback.selectionClick();

      try {
        final updatedCart = await ApiService.instance.updateCartItem(itemId, quantity);
        state = AsyncValue.data(updatedCart);
        await _saveLocal();
      } catch (e) {
        state = previousState;
      }
    }
  }

  Future<void> removeItem(String itemId) async {
    final previousState = state;
    final current = state.valueOrNull != null
        ? Map<String, dynamic>.from(state.value!)
        : {'items': []};
    List<Map<String, dynamic>> items =
        List<Map<String, dynamic>>.from(current['items'] ?? []);

    // 1. Optimistic Update
    items.removeWhere((item) => item['id'] == itemId);
    current['items'] = items;
    state = AsyncValue.data(current);
    HapticFeedback.mediumImpact();

    try {
      final updatedCart = await ApiService.instance.removeCartItem(itemId);
      state = AsyncValue.data(updatedCart);
      await _saveLocal();
    } catch (e) {
      state = previousState;
    }
  }

  Future<void> clear() async {
    state = const AsyncValue.data({'items': []});
    await CacheManager.delete('local_cart');
  }

  int get itemCount {
    final data = state.valueOrNull;
    final items = data?['items'] as List? ?? [];
    return items.fold<int>(
        0, (sum, item) => sum + ((item['quantity'] as int?) ?? 0));
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<Map>>(
    (ref) => CartNotifier());

final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.whenOrNull(data: (data) {
        final items = data['items'] as List? ?? [];
        return items.fold<int>(
            0, (sum, item) => sum + ((item['quantity'] as int?) ?? 0));
      }) ??
      0;
});

// ── Orders ────────────────────────────────────────────────
final ordersProvider = FutureProvider<List>((ref) async {
  try {
    final orders = await ApiService.instance.getOrders();
    await OfflineCache.saveOrders(orders);
    return orders;
  } catch (e) {
    final offline = await OfflineCache.getOrders();
    if (offline != null) return offline;
    rethrow;
  }
});

final orderTrackingProvider =
    FutureProvider.family<Map, String>((ref, orderId) async {
  return ApiService.instance.getOrderTracking(orderId);
});

final farmerTradeBookingsProvider = FutureProvider<List>((ref) async {
  return ApiService.instance.getFarmerTradeBookings();
});

// ── Farmer Dashboard ──────────────────────────────────────
final farmerDashboardProvider = FutureProvider<Map>((ref) async {
  const cacheKey = 'farmer_dashboard';
  final cached =
      CacheManager.get(cacheKey, maxAge: const Duration(minutes: 30));

  if (cached != null) {
    _refreshFarmerDashboard();
    return Map.from(cached);
  }

  final data = await ApiService.instance.getFarmerDashboard();
  await CacheManager.save(cacheKey, data);
  return data;
});

void _refreshFarmerDashboard() async {
  try {
    final data = await ApiService.instance.getFarmerDashboard();
    await CacheManager.save('farmer_dashboard', data);
  } catch (_) {}
}

// ── Weather ───────────────────────────────────────────────
final weatherProvider = FutureProvider<Map>((ref) async {
  ref.keepAlive();
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled)
    return ApiService.instance
        .getWeather(lat: 20.0, lng: 73.78); // Default Nashik

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return ApiService.instance.getWeather(lat: 20.0, lng: 73.78);
    }
  }

  Position pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ));
  return ApiService.instance.getWeather(lat: pos.latitude, lng: pos.longitude);
});

final weatherAdvisoryProvider =
    FutureProvider.family<Map, String>((ref, district) async {
  return ApiService.instance.getWeatherAdvisory(district: district);
});

// ── Mandi ─────────────────────────────────────────────────
final mandiProvider =
    FutureProvider.family<Map, String?>((ref, district) async {
  ref.keepAlive();
  return ApiService.instance.getMandiPrices(district: district);
});

final cropHistoryProvider =
    FutureProvider.family<Map, String>((ref, crop) async {
  return ApiService.instance.getCropHistory(crop);
});

// ── Schemes ───────────────────────────────────────────────
final schemesProvider = FutureProvider<List>((ref) async {
  return ApiService.instance.getSchemes();
});

final eligibleSchemesProvider = FutureProvider<List>((ref) async {
  return ApiService.instance.getEligibleSchemes();
});

// ── Notifications ─────────────────────────────────────────
final notificationsProvider = FutureProvider<Map>((ref) async {
  return ApiService.instance.getNotifications();
});

// ── Supplier ──────────────────────────────────────────────
final supplierDashboardProvider = FutureProvider<Map>((ref) async {
  return ApiService.instance.getSupplierDashboard();
});

final supplierOrdersProvider =
    FutureProvider.family<List, String?>((ref, status) async {
  return ApiService.instance.getSupplierOrders(status: status);
});

final supplierProductsProvider = FutureProvider<List>((ref) async {
  return ApiService.instance.getSupplierProducts();
});

// ── Dealer ────────────────────────────────────────────────
final dealerDashboardProvider = FutureProvider<Map>((ref) async {
  return ApiService.instance.getDealerDashboard();
});

final dealerRatesProvider = FutureProvider<List>((ref) async {
  return ApiService.instance.getDealerMyRates();
});

final dealerBookingsProvider = FutureProvider<List>((ref) async {
  return ApiService.instance.getDealerMyBookings();
});

