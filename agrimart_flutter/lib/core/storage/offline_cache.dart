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
}
