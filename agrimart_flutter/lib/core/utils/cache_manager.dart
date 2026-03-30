import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CacheManager {
  static final _box = Hive.box('app_cache');

  static Future<void> save(String key, dynamic data) async {
    await _box.put(key, {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static dynamic get(String key, {Duration? maxAge}) {
    final entry = _box.get(key);
    if (entry == null) return null;

    if (maxAge != null) {
      final timestamp = entry['timestamp'] as int;
      final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
      if (age > maxAge) return null;
    }

    return entry['data'];
  }

  static Future<void> delete(String key) async {
    await _box.delete(key);
  }

  static Future<void> clear() async {
    await _box.clear();
  }
}
