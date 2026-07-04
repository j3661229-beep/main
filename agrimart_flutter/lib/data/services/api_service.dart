import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';

class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();
  ApiService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )
    ..interceptors.add(_AuthInterceptor(_storage))
    ..interceptors.add(ErrorInterceptor())
    ..interceptors.add(PrettyDioLogger(
      requestHeader: false,
      requestBody: true,
      responseBody: true,
      error: true,
      compact: true,
    ));

  Dio get dio => _dio;

  // ── Auth ──────────────────────────────────────────────────

  Future<void> sendOTP({required String phone, required String role}) async {
    await _dio.post('/auth/send-otp', data: {'phone': phone, 'role': role});
  }

  Future<Map> verifyOTP({
    required String phone,
    required String otp,
    String? name,
    String? role,
    String? language,
  }) async {
    final r = await _dio.post('/auth/verify-otp', data: {
      'phone': phone,
      'otp': otp,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (language != null) 'language': language,
    });
    return r.data['data'];
  }

  Future<Map> loginWithPassword({required String emailOrPhone, required String password, required String role}) async {
    final r = await _dio.post('/auth/login', data: {
      'emailOrPhone': emailOrPhone,
      'password': password,
      'role': role,
    });
    return r.data['data'];
  }

  Future<Map> registerFarmer(Map<String, dynamic> data) async {
    final r = await _dio.post('/farmers/register', data: data);
    return r.data['data'];
  }

  Future<Map> registerSupplier(Map<String, dynamic> data) async {
    final r = await _dio.post('/suppliers/register', data: data);
    return r.data['data'];
  }

  Future<Map> registerDealer(Map<String, dynamic> data) async {
    final r = await _dio.post('/dealers/register', data: data);
    return r.data['data'];
  }

  Future<Map> completeOnboarding(Map<String, dynamic> data) async {
    final r = await _dio.post('/auth/onboarding', data: data);
    return r.data;
  }

  Future<Map> getMe() async {
    final r = await _dio.get('/auth/me');
    return r.data;
  }

  Future<void> logout() async {
    try { await _dio.post('/auth/logout'); } catch (_) {}
    await _storage.deleteAll();
  }

  // ── Farmer ────────────────────────────────────────────────

  Future<Map> getFarmerDashboard() async {
    final r = await _dio.get('/farmer/dashboard');
    return r.data['data'];
  }

  Future<Map> updateFarmDetails(Map<String, dynamic> data) async {
    final r = await _dio.put('/farmer/farm-details', data: data);
    return r.data['data'];
  }

  Future<List> getFarmerOrders({int page = 1}) async {
    final r = await _dio.get('/farmer/orders', queryParameters: {'page': page, 'limit': 10});
    return r.data['data'] ?? [];
  }

  // ── Products ──────────────────────────────────────────────

  Future<Map> getProducts({
    String? category,
    String? search,
    String? sort,
    double? lat,
    double? lng,
    int page = 1,
  }) async {
    final r = await _dio.get('/products', queryParameters: {
      if (category != null) 'category': category,
      if (search != null) 'search': search,
      if (sort != null) 'sort': sort,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'page': page,
      'limit': AppConstants.defaultPageSize,
    });
    return {'data': r.data['data'], 'pagination': r.data['pagination']};
  }

  Future<List> getProductsByQuery(String query) async {
    final r = await _dio.get('/products$query');
    return r.data['data'] ?? [];
  }

  Future<Map> getProduct(String id) async {
    final r = await _dio.get('/products/$id');
    return r.data['data'];
  }

  Future<List> getNearbyProducts({required double lat, required double lng, double radius = 30}) async {
    final r = await _dio.get('/products/nearby', queryParameters: {'lat': lat, 'lng': lng, 'radius': radius});
    return r.data['data'] ?? [];
  }

  Future<List> getNearbySuppliers({required double lat, required double lng, double radius = 25, int limit = 20}) async {
    final r = await _dio.get('/products/nearby-suppliers', queryParameters: {'lat': lat, 'lng': lng, 'radius': radius, 'limit': limit});
    return r.data['data'] ?? [];
  }

  Future<List> getRecommendedProducts() async {
    final r = await _dio.get('/products/recommended');
    return r.data['data'] ?? [];
  }

  // ── Cart ──────────────────────────────────────────────────

  Future<Map> getCart() async {
    final r = await _dio.get('/cart');
    return r.data['data'];
  }

  Future<Map> addToCart({required String productId, required int quantity}) async {
    final r = await _dio.post('/cart/items', data: {'productId': productId, 'quantity': quantity});
    return r.data['data'];
  }

  Future<Map> updateCartItem(String itemId, int quantity) async {
    final r = await _dio.put('/cart/items/$itemId', data: {'quantity': quantity});
    return r.data['data'];
  }

  Future<Map> removeCartItem(String itemId) async {
    final r = await _dio.delete('/cart/items/$itemId');
    return r.data['data'];
  }

  Future clearCart() => _dio.delete('/cart');

  // ── Orders ────────────────────────────────────────────────

  Future<Map> createOrder({required String deliveryAddress, double? lat, double? lng, String? notes, String paymentMethod = 'UPI'}) async {
    final r = await _dio.post('/orders', data: {
      'deliveryAddress': deliveryAddress,
      'deliveryLat': lat,
      'deliveryLng': lng,
      'notes': notes,
      'paymentMethod': paymentMethod,
    });
    return r.data['data'];
  }

  Future<List> getOrders({int page = 1}) async {
    final r = await _dio.get('/orders', queryParameters: {'page': page});
    return r.data['data'] ?? [];
  }

  Future<Map> getOrderTracking(String orderId) async {
    final r = await _dio.get('/orders/$orderId/tracking');
    return r.data['data'];
  }

  Future<Map> cancelOrder(String orderId) async {
    final r = await _dio.put('/orders/$orderId/cancel');
    return r.data['data'];
  }

  // ── Payments (COD + UPI only) ─────────────────────────────

  Future<Map> confirmCashOnDelivery(String orderId) async {
    final r = await _dio.post('/payments/cod', data: {'orderId': orderId});
    return r.data['data'];
  }

  Future<Map> verifyUpiPayment({required String orderId, required String utrNumber}) async {
    final r = await _dio.post('/payments/verify-upi', data: {
      'orderId': orderId,
      'utrNumber': utrNumber,
    });
    return r.data['data'];
  }

  Future<Map> getOrderUpiDetails(String orderId) async {
    final r = await _dio.get('/payments/$orderId/upi-details');
    return r.data['data'];
  }

  Future<Map> getPayment(String orderId) async {
    final r = await _dio.get('/payments/$orderId');
    return r.data['data'];
  }

  // ── AI ────────────────────────────────────────────────────

  Future<Map> diagnoseCrop(String imagePath, {String? language}) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath, filename: 'crop.jpg'),
      if (language != null) 'language': language,
    });
    final r = await _dio.post('/diagnose', data: formData, options: Options(contentType: 'multipart/form-data'));
    return r.data['data'];
  }

  Future<List> getDiagnoseHistory({int page = 1}) async {
    final r = await _dio.get('/diagnose/history', queryParameters: {'page': page});
    return r.data['data'] ?? [];
  }

  Future<Map> analyzeSoil(String imagePath, {String? location, String? language}) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath, filename: 'soil.jpg'),
      if (location != null) 'location': location,
      if (language != null) 'language': language,
    });
    final r = await _dio.post('/ai/soil-analysis', data: formData, options: Options(contentType: 'multipart/form-data'));
    return r.data['data'];
  }

  Future<Map> detectDisease(String imagePath, {String? language}) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath, filename: 'crop.jpg'),
      if (language != null) 'language': language,
    });
    final r = await _dio.post('/ai/disease-detection', data: formData, options: Options(contentType: 'multipart/form-data'));
    return r.data['data'];
  }

  Future<Map> getCropRecommend(Map<String, dynamic> data) async {
    final r = await _dio.post('/ai/crop-recommend', data: data);
    return r.data['data'];
  }

  Future<Map> kisanChat({required String message, List? history, String? language}) async {
    final r = await _dio.post('/ai/chat', data: {
      'message': message,
      'history': history ?? [],
      if (language != null) 'language': language,
    });
    return r.data['data'];
  }

  // ── Advisory ──────────────────────────────────────────────

  Future<List> getAdvisory({String? location}) async {
    final r = await _dio.get('/advisory', queryParameters: {if (location != null) 'location': location});
    return r.data['data'] ?? [];
  }

  // ── Weather ───────────────────────────────────────────────

  Future<Map> getWeather({double? lat, double? lng}) async {
    final r = await _dio.get('/weather/current', queryParameters: {'lat': lat?.toString(), 'lng': lng?.toString()});
    return r.data['data'];
  }

  Future<Map> getWeatherAdvisory({double? lat, double? lng, String? district}) async {
    final r = await _dio.get('/weather/advisory', queryParameters: {'lat': lat?.toString(), 'lng': lng?.toString(), 'district': district});
    return r.data['data'];
  }

  // ── Farmer Features ───────────────────────────────────────

  Future<Map> getMandiNews({String? district, String? state, int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (district != null) params['district'] = district;
      if (state != null) params['state'] = state;
      final r = await _dio.get('/news', queryParameters: params);
      return r.data;
    } catch (_) { return {'success': false, 'data': []}; }
  }

  // ── Mandi Prices ──────────────────────────────────────────

  Future<Map> getMandiPrices({String? district, String? crop}) async {
    final r = await _dio.get('/mandi/prices', queryParameters: {'district': district, 'crop': crop});
    return r.data['data'];
  }

  Future<Map> getCropHistory(String crop) async {
    final r = await _dio.get('/mandi/prices/$crop');
    return r.data['data'];
  }

  // ── Produce / Deals (via trade bookings) ──────────────────

  Future<List> getProduceListings({String? crop, String? district}) async {
    final bookings = await getDealerMyBookings();
    return bookings.where((b) {
      if (crop != null && crop.isNotEmpty && crop != 'All') {
        if ((b['cropName'] ?? '').toString().toLowerCase() != crop.toLowerCase()) return false;
      }
      return true;
    }).map((b) => {
      'id': b['id'],
      'crop': b['cropName'],
      'quantity': b['approxQuintals'],
      'expectedPrice': b['pricePerQuintal'],
      'farmerName': b['farmer']?['user']?['name'] ?? b['farmer']?['name'] ?? 'Farmer',
      'farmer': b['farmer'],
      'status': b['status'],
      'slotDate': b['slotDate'],
    }).toList();
  }

  Future<Map> createProduceListing(Map<String, dynamic> data) async {
    return bookTradeSlot({
      'dealerId': data['dealerId'],
      'cropName': data['crop'] ?? data['cropName'],
      'approxQuintals': data['quantity'] ?? data['approxQuintals'] ?? 1,
      'pricePerQuintal': data['expectedPrice'] ?? data['pricePerQuintal'] ?? 0,
      'slotDate': data['slotDate'] ?? DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      if (data['notes'] != null) 'notes': data['notes'],
    });
  }

  Future<List> getDeals({String? status, int page = 1}) async {
    final bookings = await getDealerMyBookings();
    if (status != null && status.isNotEmpty) {
      return bookings.where((b) => (b['status'] ?? '').toString().toUpperCase() == status.toUpperCase()).toList();
    }
    return bookings;
  }

  Future<Map> createDeal(Map<String, dynamic> data) async {
    final bookingId = data['bookingId'] ?? data['listingId'];
    if (bookingId != null) {
      return updateDealerBookingStatus(bookingId.toString(), 'ACCEPTED');
    }
    return bookTradeSlot(data);
  }

  Future<Map> updateDealStatus(String id, String status) async {
    return updateDealerBookingStatus(id, status);
  }

  // ── Supplier ──────────────────────────────────────────────

  Future<Map> getSupplierStats() async {
    final r = await _dio.get('/suppliers/stats');
    return r.data['data'];
  }

  Future<Map> getSupplierDashboard() async {
    final r = await _dio.get('/supplier/dashboard');
    return r.data['data'];
  }

  Future<List> getSupplierOrders({String? status, int page = 1}) async {
    final r = await _dio.get('/supplier/orders', queryParameters: {'status': status, 'page': page});
    return r.data['data'] ?? [];
  }

  Future<Map> updateOrderStatus(String itemId, String status) async {
    final r = await _dio.patch('/orders/$itemId', data: {'status': status});
    return r.data['data'];
  }

  Future<Map> createProduct(Map<String, dynamic> data) async {
    final r = await _dio.post('/products', data: data);
    return r.data['data'];
  }

  Future<Map> createProductWithImages(Map<String, dynamic> data, List<String> imagePaths) async {
    final formData = FormData.fromMap({
      ...data,
      'images': await Future.wait(imagePaths.map((p) async =>
          await MultipartFile.fromFile(p, filename: p.split('/').last))),
    });
    final r = await _dio.post('/products', data: formData, options: Options(contentType: 'multipart/form-data'));
    return r.data['data'];
  }

  Future<List> getSupplierProducts() async {
    final r = await _dio.get('/supplier/products');
    return r.data['data'] ?? [];
  }

  Future<Map> updateProduct(String id, Map<String, dynamic> data) async {
    final r = await _dio.put('/products/$id', data: data);
    return r.data['data'];
  }

  Future<Map> deleteProduct(String id) async {
    final r = await _dio.delete('/products/$id');
    return r.data['data'];
  }

  // ── Dealer ────────────────────────────────────────────────

  Future<Map> getDealerStats() async {
    final r = await _dio.get('/dealers/stats');
    return r.data['data'];
  }

  Future<Map> getDealerDashboard() async {
    final rates    = await getDealerMyRates();
    final bookings = await getDealerMyBookings();
    final pending  = (bookings as List).where((b) => b['status'] == 'PENDING').length;
    final today    = bookings.where((b) {
      final d = DateTime.tryParse(b['slotDate'] ?? '');
      return d != null && d.day == DateTime.now().day && d.month == DateTime.now().month;
    }).length;
    return {
      'activeRates': (rates as List).where((r) => r['isActive'] == true).length,
      'pendingBookings': pending,
      'todaySlots': today,
      'totalBookings': bookings.length,
      'rates': rates,
      'bookings': bookings,
    };
  }

  Future<List> getDealerMyRates() async {
    final r = await _dio.get('/dealer/rates');
    return r.data['data'] ?? [];
  }

  Future<Map> updateDealerRate(Map<String, dynamic> data) async {
    final r = await _dio.post('/dealer/rates', data: data);
    return r.data['rate'] ?? r.data['data'] ?? {};
  }

  Future<List> getDealerMyBookings() async {
    final r = await _dio.get('/dealer/bookings');
    return r.data['data'] ?? [];
  }

  Future<Map> updateDealerBookingStatus(String id, String status) async {
    final r = await _dio.patch('/dealer/bookings/$id', data: {'status': status});
    return r.data['booking'] ?? r.data['data'] ?? {};
  }

  // ── Trade ─────────────────────────────────────────────────

  Future<List> getDealerRates({required String district, String? crop}) async {
    final r = await _dio.get('/trade/rates', queryParameters: {'district': district, if (crop != null) 'crop': crop});
    return r.data['data'] ?? [];
  }

  Future<Map> bookTradeSlot(Map<String, dynamic> data) async {
    final r = await _dio.post('/trade/book', data: data);
    return r.data;
  }

  Future<List> getFarmerTradeBookings() async {
    final r = await _dio.get('/trade/bookings');
    return r.data['data'] ?? [];
  }

  // ── Notifications ─────────────────────────────────────────

  Future<Map> getNotifications() async {
    final r = await _dio.get('/notifications');
    return {'data': r.data['data'], 'unread': r.data['unread']};
  }

  Future saveFCMToken(String token) => _dio.post('/notifications/fcm-token', data: {'token': token});

  // ── Schemes ───────────────────────────────────────────────

  Future<List> getSchemes() async {
    final r = await _dio.get('/schemes');
    return r.data['data'] ?? [];
  }

  Future<List> getEligibleSchemes() async {
    final r = await _dio.get('/schemes/eligible');
    return r.data['data'] ?? [];
  }

  // ── Upload ────────────────────────────────────────────────

  Future<Map> uploadGovtDoc({required dynamic file, required String docType}) async {
    final path = file is String ? file : file.path as String;
    final formData = FormData.fromMap({
      'document': await MultipartFile.fromFile(path, filename: path.split('/').last),
      'docType': docType,
    });
    final r = await _dio.post('/upload/govt-doc', data: formData, options: Options(contentType: 'multipart/form-data'));
    return r.data['data'];
  }
}



// ── Auth Interceptor ──────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  _AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
          final res = await dio.post('/auth/refresh-token', data: {'refreshToken': refreshToken});
          if (res.statusCode == 200 && res.data['data'] != null) {
            final newToken = res.data['data']['token'];
            await _storage.write(key: AppConstants.tokenKey, value: newToken);
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';
            final retry = await dio.fetch(options);
            return handler.resolve(retry);
          }
        } catch (_) {}
      }
    }
    handler.next(err);
  }
}

