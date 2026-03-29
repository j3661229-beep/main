import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../core/constants/app_constants.dart';

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
        'Accept': 'application/json'
      },
    ),
  )
    ..interceptors.add(_AuthInterceptor(_storage))
    ..interceptors.add(PrettyDioLogger(
      requestHeader: false,
      requestBody: true,
      responseBody: true,
      error: true,
      compact: true,
    ));

  Dio get dio => _dio;

  // ── Auth ──────────────────────────────────────────────────
  Future<Map> sendOTP(String phone, String role) async {
    final r =
        await _dio.post('/auth/send-otp', data: {'phone': phone, 'role': role});
    return r.data['data'];
  }

  Future<Map> verifyOTP(
      {required String phone,
      required String otp,
      String? name,
      String? language,
      String? role}) async {
    final r = await _dio.post('/auth/verify-otp', data: {
      'phone': phone,
      'otp': otp,
      'name': name,
      'language': language,
      'role': role
    });
    return r.data['data'];
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
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
    final r = await _dio
        .get('/farmer/orders', queryParameters: {'page': page, 'limit': 10});
    return r.data['data'] ?? [];
  }

  // ── Products ──────────────────────────────────────────────
  Future<Map> getProducts(
      {String? category,
      String? search,
      String? sort,
      double? lat,
      double? lng,
      int page = 1}) async {
    final r = await _dio.get('/products', queryParameters: {
      if (category != null) 'category': category,
      if (search != null) 'search': search,
      if (sort != null) 'sort': sort,
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

  Future<List> getNearbyProducts(
      {required double lat, required double lng, double radius = 30}) async {
    final r = await _dio.get('/products/nearby',
        queryParameters: {'lat': lat, 'lng': lng, 'radius': radius});
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

  Future<Map> addToCart(
      {required String productId, required int quantity}) async {
    final r = await _dio.post('/cart/items',
        data: {'productId': productId, 'quantity': quantity});
    return r.data['data'];
  }

  Future<Map> updateCartItem(String itemId, int quantity) async {
    final r =
        await _dio.put('/cart/items/$itemId', data: {'quantity': quantity});
    return r.data['data'];
  }

  Future<Map> removeCartItem(String itemId) async {
    final r = await _dio.delete('/cart/items/$itemId');
    return r.data['data'];
  }

  Future clearCart() => _dio.delete('/cart');

  // ── Orders ────────────────────────────────────────────────
  Future<Map> createOrder(
      {required String deliveryAddress,
      double? lat,
      double? lng,
      String? notes}) async {
    final r = await _dio.post('/orders', data: {
      'deliveryAddress': deliveryAddress,
      'deliveryLat': lat,
      'deliveryLng': lng,
      'notes': notes
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

  // ── Payments ──────────────────────────────────────────────
  Future<Map> createRazorpayOrder(String orderId) async {
    final r =
        await _dio.post('/payments/create-order', data: {'orderId': orderId});
    return r.data['data'];
  }

  Future<Map> verifyPayment(
      {required String razorpayOrderId,
      required String razorpayPaymentId,
      required String signature}) async {
    final r = await _dio.post('/payments/verify', data: {
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': signature,
    });
    return r.data['data'];
  }

  Future<Map> confirmCashOnDelivery(String orderId) async {
    final r = await _dio.post('/payments/cod', data: {'orderId': orderId});
    return r.data['data'];
  }

  // ── AI ────────────────────────────────────────────────────
  Future<Map> analyzeSoil(String imagePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath, filename: 'soil.jpg')
    });
    final r = await _dio.post('/ai/soil-analysis',
        data: formData, options: Options(contentType: 'multipart/form-data'));
    return r.data['data'];
  }

  Future<Map> detectDisease(String imagePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath, filename: 'crop.jpg')
    });
    final r = await _dio.post('/ai/disease-detection',
        data: formData, options: Options(contentType: 'multipart/form-data'));
    return r.data['data'];
  }

  Future<Map> getCropRecommend(Map<String, dynamic> data) async {
    final r = await _dio.post('/ai/crop-recommend', data: data);
    return r.data['data'];
  }

  Future<Map> kisanChat({required String message, List? history}) async {
    final r = await _dio
        .post('/ai/chat', data: {'message': message, 'history': history ?? []});
    return r.data['data'];
  }

  Future<Map> getCropCalendar({String? month, String? district}) async {
    final r = await _dio.get('/ai/crop-calendar',
        queryParameters: {'month': month, 'district': district});
    return r.data['data'];
  }

  // ── Weather ───────────────────────────────────────────────
  Future<Map> getWeather({double? lat, double? lng}) async {
    final r = await _dio.get('/weather/current',
        queryParameters: {'lat': lat?.toString(), 'lng': lng?.toString()});
    return r.data['data'];
  }

  Future<Map> getWeatherAdvisory(
      {double? lat, double? lng, String? district}) async {
    final r = await _dio.get('/weather/advisory', queryParameters: {
      'lat': lat?.toString(),
      'lng': lng?.toString(),
      'district': district
    });
    return r.data['data'];
  }

  // ── Mandi Prices ──────────────────────────────────────────
  Future<Map> getMandiPrices({String? district, String? crop}) async {
    final r = await _dio.get('/mandi/prices',
        queryParameters: {'district': district, 'crop': crop});
    return r.data['data'];
  }

  Future<Map> getCropHistory(String crop) async {
    final r = await _dio.get('/mandi/prices/$crop');
    return r.data['data'];
  }

  // ── Notifications ─────────────────────────────────────────
  Future<Map> getNotifications() async {
    final r = await _dio.get('/notifications');
    return {'data': r.data['data'], 'unread': r.data['unread']};
  }

  Future saveFCMToken(String token) =>
      _dio.post('/notifications/fcm-token', data: {'token': token});

  // ── Schemes ───────────────────────────────────────────────
  Future<List> getSchemes() async {
    final r = await _dio.get('/schemes');
    return r.data['data'] ?? [];
  }

  Future<List> getEligibleSchemes() async {
    final r = await _dio.get('/schemes/eligible');
    return r.data['data'] ?? [];
  }

  // ── Supplier ──────────────────────────────────────────────
  Future<Map> getSupplierDashboard() async {
    final r = await _dio.get('/supplier/dashboard');
    return r.data['data'];
  }

  Future<List> getSupplierOrders({String? status, int page = 1}) async {
    final r = await _dio.get('/supplier/orders',
        queryParameters: {'status': status, 'page': page});
    return r.data['data'] ?? [];
  }

  Future<Map> updateOrderStatus(String itemId, String status) async {
    final r = await _dio
        .put('/supplier/orders/$itemId/status', data: {'status': status});
    return r.data['data'];
  }

  Future<Map> createProduct(Map<String, dynamic> data) async {
    final r = await _dio.post('/products', data: data);
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
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  _AuthInterceptor(this._storage);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _storage.deleteAll();
    }
    handler.next(err);
  }
}
