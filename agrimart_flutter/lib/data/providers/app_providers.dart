import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../../core/storage/offline_cache.dart';
import '../../core/utils/cache_manager.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/providers/app_language_provider.dart';
import 'auth_provider.dart';

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

  Future<void> syncWithServer() async {
    final serverCart = await ApiService.instance.getCart();
    final serverItems = (serverCart['items'] as List?) ?? [];
    if (serverItems.isNotEmpty) {
      state = AsyncValue.data(serverCart);
      await _saveLocal();
      return;
    }

    final localItems = (state.valueOrNull?['items'] as List?) ?? [];
    if (localItems.isEmpty) {
      state = AsyncValue.data(serverCart);
      return;
    }

    for (final item in localItems) {
      final productId = item['productId'] ?? item['product']?['id'];
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      if (productId != null) {
        await ApiService.instance.addToCart(productId: productId.toString(), quantity: qty);
      }
    }

    final refreshed = await ApiService.instance.getCart();
    state = AsyncValue.data(refreshed);
    await _saveLocal();
  }

  Future<void> clear() async {
    state = const AsyncValue.data({'items': []});
    await CacheManager.delete('local_cart');
    try { await ApiService.instance.clearCart(); } catch (_) {}
  }

  void clearLocal() {
    state = const AsyncValue.data({'items': []});
    CacheManager.delete('local_cart');
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
  ref.keepAlive();
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
  const cacheKey = 'weather_current';
  final online = ref.watch(isOnlineProvider);

  if (!online) {
    final offline = await OfflineCache.getWeather();
    if (offline != null) return offline;
    final cached = CacheManager.get(cacheKey, maxAge: const Duration(hours: 6));
    if (cached != null) return Map<String, dynamic>.from(cached as Map);
  }

  final cached = CacheManager.get(cacheKey, maxAge: const Duration(minutes: 30));
  if (cached != null && online) {
    _refreshWeather(cacheKey);
    return Map<String, dynamic>.from(cached as Map);
  }

  final farmer = ref.watch(authProvider).user?.farmer;
  final profileLat = (farmer?['latitude'] as num?)?.toDouble();
  final profileLng = (farmer?['longitude'] as num?)?.toDouble();
  final Map<String, dynamic> data;
  if (profileLat != null && profileLng != null) {
    data = Map<String, dynamic>.from(await ApiService.instance.getWeather(lat: profileLat, lng: profileLng));
  } else {
    data = Map<String, dynamic>.from(await ApiService.instance.getWeather(lat: 19.9975, lng: 73.7898));
  }
  await CacheManager.save(cacheKey, data);
  await OfflineCache.saveWeather(data);
  return data;
});

void _refreshWeather(String cacheKey) async {
  try {
    final cached = CacheManager.get(cacheKey);
    if (cached is! Map) return;
    final lat = (cached['lat'] as num?)?.toDouble() ?? 19.9975;
    final lng = (cached['lng'] as num?)?.toDouble() ?? 73.7898;
    final data = Map<String, dynamic>.from(await ApiService.instance.getWeather(lat: lat, lng: lng));
    await CacheManager.save(cacheKey, data);
    await OfflineCache.saveWeather(data);
  } catch (_) {}
}

final weatherAdvisoryProvider =
    FutureProvider.family<Map, String>((ref, district) async {
  ref.keepAlive();
  final weather = await ref.watch(weatherProvider.future);
  return ApiService.instance.getWeatherAdvisory(
    lat: (weather['lat'] as num?)?.toDouble(),
    lng: (weather['lng'] as num?)?.toDouble(),
    district: district.isNotEmpty ? district : (weather['location']?.toString() ?? 'Nashik'),
  );
});

// ── Mandi News ──────────────────────────────────────────────
final mandiNewsProvider = FutureProvider<List>((ref) async {
  ref.keepAlive();
  final user = ref.watch(authProvider).user;
  if (user == null) return [];
  final language = ref.watch(appLanguageProvider).backendCode;
  final district = user.effectiveDistrict;
  final state = user.state ?? 'Maharashtra';
  final online = ref.watch(isOnlineProvider);

  if (!online) {
    final cached = await OfflineCache.getNews(district, language);
    if (cached != null) return cached;
  }

  try {
    final r = await ApiService.instance.getMandiNews(
      district: district,
      state: state,
      language: language,
    );
    final news = r['data'] as List? ?? [];
    await OfflineCache.saveNews(district, language, news);
    return news;
  } catch (_) {
    final cached = await OfflineCache.getNews(district, language);
    if (cached != null) return cached;
    if (!online) return [];
    rethrow;
  }
});

/// Top headlines for the home screen carousel.
final mandiNewsPreviewProvider = FutureProvider<List>((ref) async {
  final news = await ref.watch(mandiNewsProvider.future);
  return news.take(5).toList();
});

/// Top mandi price rows for home ticker (no dedicated mandi prices screen).
final mandiTickerProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.keepAlive();
  final user = ref.watch(authProvider).user;
  final district = user?.effectiveDistrict ?? 'Nashik';
  final data = await ref.watch(mandiProvider(district).future);
  final prices = (data['prices'] as List?) ?? [];
  return prices.take(5).map((p) => Map<String, dynamic>.from(p as Map)).toList();
});

// ── Mandi ─────────────────────────────────────────────────
final mandiProvider =
    FutureProvider.family<Map, String?>((ref, district) async {
  ref.keepAlive();
  final cacheDistrict = district ?? 'default';
  final online = ref.watch(isOnlineProvider);
  if (!online) {
    final cached = await OfflineCache.getMandiPrices(cacheDistrict);
    if (cached != null) return cached;
  }
  try {
    final data = Map<String, dynamic>.from(
      await ApiService.instance.getMandiPrices(district: district),
    );
    await OfflineCache.saveMandiPrices(cacheDistrict, data);
    return data;
  } catch (_) {
    final cached = await OfflineCache.getMandiPrices(cacheDistrict);
    if (cached != null) return cached;
    rethrow;
  }
});

final cropHistoryProvider =
    FutureProvider.family<Map, String>((ref, crop) async {
  return ApiService.instance.getCropHistory(crop);
});

// ── Schemes ───────────────────────────────────────────────
final schemesProvider = FutureProvider<List>((ref) async {
  ref.keepAlive();
  final online = ref.watch(isOnlineProvider);
  if (!online) {
    final cached = await OfflineCache.getSchemes();
    if (cached != null) return cached;
  }
  try {
    final schemes = await ApiService.instance.getSchemes();
    await OfflineCache.saveSchemes(schemes);
    return schemes;
  } catch (_) {
    final cached = await OfflineCache.getSchemes();
    if (cached != null) return cached;
    rethrow;
  }
});

final eligibleSchemesProvider = FutureProvider<List>((ref) async {
  return ApiService.instance.getEligibleSchemes();
});

final priceAlertsProvider = FutureProvider<List>((ref) async {
  return ApiService.instance.getPriceAlerts();
});

/// Crop calendar keyed by month index (0–11). Farmer profile comes from auth token on backend.
final cropCalendarProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, monthIndex) async {
  ref.keepAlive();
  final language = ref.read(appLanguageProvider).aiName;
  final cacheKey = 'crop_calendar_${monthIndex}_$language';
  final cached = CacheManager.get(cacheKey, maxAge: const Duration(hours: 6));
  if (cached != null) {
    _refreshCropCalendar(monthIndex, language, cacheKey);
    return Map<String, dynamic>.from(cached);
  }
  final data = await ApiService.instance.getCropCalendar(month: monthIndex, language: language);
  final mapped = Map<String, dynamic>.from(data);
  await CacheManager.save(cacheKey, mapped);
  return mapped;
});

void _refreshCropCalendar(int monthIndex, String language, String cacheKey) async {
  try {
    final data = await ApiService.instance.getCropCalendar(month: monthIndex, language: language);
    await CacheManager.save(cacheKey, Map<String, dynamic>.from(data));
  } catch (_) {}
}

final equipmentProductsProvider = FutureProvider<List>((ref) async {
  final data = await ApiService.instance.getProducts(category: 'EQUIPMENT');
  return (data['data'] as List?) ?? [];
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

/// Dealer buying rates for farmers (Sell tab hero).
final farmerDealerRatesProvider =
    FutureProvider.family<List, String>((ref, district) async {
  if (district.isEmpty) return [];
  return ApiService.instance.getDealerRates(district: district);
});

final dealerBookingsProvider = FutureProvider<List>((ref) async {
  return ApiService.instance.getDealerMyBookings();
});

// ── Produce Board ─────────────────────────────────────────
final produceListingsProvider =
    FutureProvider.family<List, Map<String, String?>>((ref, filters) async {
  return ApiService.instance.getProduceListings(
    crop:     filters['crop'],
    district: filters['district'],
  );
});

// ── Dealer Deals ──────────────────────────────────────────
final dealerDealsProvider =
    FutureProvider.family<List, String?>((ref, status) async {
  return ApiService.instance.getDeals(status: status);
});
