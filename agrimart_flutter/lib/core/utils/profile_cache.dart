import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed profile cache for instant cold start (stale-while-revalidate).
class ProfileCache {
  ProfileCache._();

  static const _boxName = 'offline_fallback_cache';
  static const _userKey = 'profile_user_json';
  static const _farmSetupKey = 'profile_farm_setup';
  static const _atKey = 'profile_cached_at';

  static Box get _box => Hive.box(_boxName);

  static Future<void> save(Map<String, dynamic> userJson, {Map<String, dynamic>? farmSetup}) async {
    await _box.put(_userKey, jsonEncode(userJson));
    if (farmSetup != null) {
      await _box.put(_farmSetupKey, jsonEncode(farmSetup));
    }
    await _box.put(_atKey, DateTime.now().toIso8601String());
  }

  static ProfileCacheEntry? load() {
    final userStr = _box.get(_userKey) as String?;
    final atStr = _box.get(_atKey) as String?;
    if (userStr == null || atStr == null) return null;

    Map<String, dynamic>? farmSetup;
    final farmStr = _box.get(_farmSetupKey) as String?;
    if (farmStr != null) {
      farmSetup = Map<String, dynamic>.from(jsonDecode(farmStr) as Map);
    }

    return ProfileCacheEntry(
      userJson: Map<String, dynamic>.from(jsonDecode(userStr) as Map),
      farmSetup: farmSetup,
      cachedAt: DateTime.parse(atStr),
    );
  }

  static bool isFresh(DateTime cachedAt, {Duration maxAge = const Duration(minutes: 10)}) {
    return DateTime.now().difference(cachedAt) < maxAge;
  }

  static Future<void> clear() async {
    await _box.delete(_userKey);
    await _box.delete(_farmSetupKey);
    await _box.delete(_atKey);
  }
}

class ProfileCacheEntry {
  final Map<String, dynamic> userJson;
  final Map<String, dynamic>? farmSetup;
  final DateTime cachedAt;

  const ProfileCacheEntry({
    required this.userJson,
    this.farmSetup,
    required this.cachedAt,
  });
}
