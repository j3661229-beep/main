import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';

// ── Products ──────────────────────────────────────────────
final productsProvider = FutureProvider.family<Map, String>((ref, queryParams) async {
  final uri = Uri(query: queryParams);
  return ApiService.instance.getProducts(
    category: uri.queryParameters['category'],
    search: uri.queryParameters['search'],
    sort: uri.queryParameters['sort'],
    page: int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1,
  );
});

final productDetailProvider = FutureProvider.family<Map, String>((ref, id) async {
  return ApiService.instance.getProduct(id);
});

final nearbyProductsProvider = FutureProvider.family<List, String>((ref, coordsStr) async {
  final parts = coordsStr.split(',');
  return ApiService.instance.getNearbyProducts(lat: double.parse(parts[0]), lng: double.parse(parts[1]));
});

final recommendedProductsProvider = FutureProvider<List>((ref) async {
  return ApiService.instance.getRecommendedProducts();
});

// ── Cart ──────────────────────────────────────────────────
class CartNotifier extends StateNotifier<AsyncValue<Map>> {
  CartNotifier() : super(const AsyncValue.loading()) {
    load();
  }
  final _api = ApiService.instance;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _api.getCart());
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addItem(String productId, int quantity) async {
    await _api.addToCart(productId: productId, quantity: quantity);
    await load();
  }

  Future<void> updateItem(String itemId, int quantity) async {
    await _api.updateCartItem(itemId, quantity);
    await load();
  }

  Future<void> removeItem(String itemId) async {
    await _api.removeCartItem(itemId);
    await load();
  }

  Future<void> clear() async {
    await _api.clearCart();
    await load();
  }

  int get itemCount {
    final data = state.valueOrNull;
    final items = data?['items'] as List? ?? [];
    return items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 0));
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<Map>>((ref) => CartNotifier());

final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.whenOrNull(data: (data) {
    final items = data['items'] as List? ?? [];
    return items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 0));
  }) ?? 0;
});

// ── Orders ────────────────────────────────────────────────
final ordersProvider = FutureProvider<List>((ref) async {
  return ApiService.instance.getOrders();
});

final orderTrackingProvider = FutureProvider.family<Map, String>((ref, orderId) async {
  return ApiService.instance.getOrderTracking(orderId);
});

// ── Farmer Dashboard ──────────────────────────────────────
final farmerDashboardProvider = FutureProvider<Map>((ref) async {
  return ApiService.instance.getFarmerDashboard();
});

// ── Weather ───────────────────────────────────────────────
final weatherProvider = FutureProvider<Map>((ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return ApiService.instance.getWeather(lat: 20.0, lng: 73.78); // Default Nashik
  
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return ApiService.instance.getWeather(lat: 20.0, lng: 73.78);
    }
  }
  
  Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
  return ApiService.instance.getWeather(lat: pos.latitude, lng: pos.longitude);
});

final weatherAdvisoryProvider = FutureProvider.family<Map, String>((ref, district) async {
  return ApiService.instance.getWeatherAdvisory(district: district);
});

// ── Mandi ─────────────────────────────────────────────────
final mandiProvider = FutureProvider.family<Map, String?>((ref, district) async {
  return ApiService.instance.getMandiPrices(district: district);
});

final cropHistoryProvider = FutureProvider.family<Map, String>((ref, crop) async {
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

final supplierOrdersProvider = FutureProvider.family<List, String?>((ref, status) async {
  return ApiService.instance.getSupplierOrders(status: status);
});

final supplierProductsProvider = FutureProvider<List>((ref) async {
  return ApiService.instance.getSupplierProducts();
});
