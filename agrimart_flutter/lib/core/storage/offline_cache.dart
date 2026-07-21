import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class OfflineCache {
  static const _boxName = 'offline_fallback_cache';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static Future<void> saveProducts(List<dynamic> products) async {
    final box = Hive.box(_boxName);
    await box.put('products', jsonEncode(products));
    await box.put('products_cached_at', DateTime.now().toIso8601String());
  }

  static Future<List<dynamic>?> getProducts() async {
    final box = Hive.box(_boxName);
    final cachedStr = box.get('products');
    final cachedAtStr = box.get('products_cached_at');
    
    if (cachedStr == null || cachedAtStr == null) return null;
    
    final cachedAt = DateTime.parse(cachedAtStr);
    final age = DateTime.now().difference(cachedAt);
    
    // Provide offline data for up to 3 days
    if (age.inDays > 3) return null;
    
    return jsonDecode(cachedStr) as List<dynamic>;
  }

  static Future<void> saveOrders(List<dynamic> orders) async {
    final box = Hive.box(_boxName);
    await box.put('orders', jsonEncode(orders));
  }

  static Future<List<dynamic>?> getOrders() async {
    final box = Hive.box(_boxName);
    final cachedStr = box.get('orders');
    return cachedStr != null ? jsonDecode(cachedStr) as List<dynamic> : null;
  }

  static Future<void> saveSchemes(List<dynamic> schemes) async {
    final box = Hive.box(_boxName);
    await box.put('schemes', jsonEncode(schemes));
    await box.put('schemes_cached_at', DateTime.now().toIso8601String());
  }

  static Future<List<dynamic>?> getSchemes() async {
    final box = Hive.box(_boxName);
    final cachedStr = box.get('schemes');
    final cachedAtStr = box.get('schemes_cached_at');
    if (cachedStr == null || cachedAtStr == null) return null;
    final age = DateTime.now().difference(DateTime.parse(cachedAtStr));
    if (age.inDays > 7) return null;
    return jsonDecode(cachedStr) as List<dynamic>;
  }

  static Future<void> saveWeather(Map<String, dynamic> weather) async {
    final box = Hive.box(_boxName);
    await box.put('weather', jsonEncode(weather));
    await box.put('weather_cached_at', DateTime.now().toIso8601String());
  }

  static Future<Map<String, dynamic>?> getWeather() async {
    final box = Hive.box(_boxName);
    final cachedStr = box.get('weather');
    final cachedAtStr = box.get('weather_cached_at');
    if (cachedStr == null || cachedAtStr == null) return null;
    final age = DateTime.now().difference(DateTime.parse(cachedAtStr));
    if (age.inHours > 6) return null;
    return Map<String, dynamic>.from(jsonDecode(cachedStr) as Map);
  }

  static String _mandiKey(String? district) =>
      'mandi_${(district ?? 'default').trim().toLowerCase()}';

  static Future<void> saveMandiPrices(String? district, Map<String, dynamic> data) async {
    final box = Hive.box(_boxName);
    final key = _mandiKey(district);
    await box.put(key, jsonEncode(data));
    await box.put('${key}_cached_at', DateTime.now().toIso8601String());
  }

  static Future<Map<String, dynamic>?> getMandiPrices(String? district) async {
    final box = Hive.box(_boxName);
    final key = _mandiKey(district);
    final cachedStr = box.get(key);
    final cachedAtStr = box.get('${key}_cached_at');
    if (cachedStr == null || cachedAtStr == null) return null;
    final age = DateTime.now().difference(DateTime.parse(cachedAtStr));
    if (age.inHours > 24) return null;
    return Map<String, dynamic>.from(jsonDecode(cachedStr) as Map);
  }

  static String _newsKey(String? district, String language) =>
      'news_${(district ?? 'default').trim().toLowerCase()}_$language';

  static Future<void> saveNews(String? district, String language, List<dynamic> news) async {
    final box = Hive.box(_boxName);
    final key = _newsKey(district, language);
    await box.put(key, jsonEncode(news));
    await box.put('${key}_cached_at', DateTime.now().toIso8601String());
  }

  static Future<List<dynamic>?> getNews(String? district, String language) async {
    final box = Hive.box(_boxName);
    final key = _newsKey(district, language);
    final cachedStr = box.get(key);
    final cachedAtStr = box.get('${key}_cached_at');
    if (cachedStr == null || cachedAtStr == null) return null;
    final age = DateTime.now().difference(DateTime.parse(cachedAtStr));
    if (age.inHours > 12) return null;
    return jsonDecode(cachedStr) as List<dynamic>;
  }
}

