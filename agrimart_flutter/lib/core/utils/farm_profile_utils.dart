import '../../data/models/user_model.dart';

/// Client-side farm profile completeness — mirrors backend `assessFarmerProfile`.
class FarmProfileUtils {
  FarmProfileUtils._();

  static bool hasText(dynamic v) =>
      v != null && v.toString().trim().isNotEmpty;

  static bool hasCoords(Map? farmer) {
    if (farmer == null) return false;
    final lat = farmer['latitude'];
    final lng = farmer['longitude'];
    return lat != null && lng != null;
  }

  static bool hasCrops(Map? farmer) {
    final crops = farmer?['currentCrops'];
    return crops is List && crops.isNotEmpty;
  }

  static bool hasFarmSize(Map? farmer) {
    final size = farmer?['farmSizeAcres'];
    if (size == null) return false;
    return (size is num ? size : double.tryParse(size.toString()) ?? 0) > 0;
  }

  static int setupScore(UserModel? user) {
    final f = user?.farmer;
    if (f == null) return 0;
    final checks = [
      hasText(f['village']),
      hasText(f['district']),
      hasText(f['taluka']),
      hasText(f['pincode']),
      hasCoords(f),
      hasFarmSize(f),
      hasCrops(f),
      hasText(f['soilType']),
      hasText(f['waterSource']),
    ];
    return ((checks.where((c) => c).length / checks.length) * 100).round();
  }

  static List<String> missingFields(UserModel? user) {
    final f = user?.farmer;
    final missing = <String>[];
    if (!hasText(f?['village'])) missing.add('village');
    if (!hasText(f?['district'])) missing.add('district');
    if (!hasFarmSize(f)) missing.add('farmSizeAcres');
    if (!hasCrops(f)) missing.add('currentCrops');
    if (!hasText(f?['soilType'])) missing.add('soilType');
    if (!hasText(f?['waterSource'])) missing.add('waterSource');
    if (!hasCoords(f)) missing.add('location');
    return missing;
  }

  static bool isSetupComplete(UserModel? user) {
    final score = setupScore(user);
    return score >= 80 && missingFields(user).isEmpty;
  }

  static String cropsDisplay(Map? farmer, {String locale = 'en'}) {
    final list = farmer?['currentCrops'];
    if (list is! List || list.isEmpty) return '—';
    return list.map((e) => e.toString()).join(', ');
  }

  static String farmSizeDisplay(Map? farmer) {
    final v = farmer?['farmSizeAcres'];
    if (v == null) return '—';
    final n = v is num ? v : double.tryParse(v.toString());
    if (n == null || n <= 0) return '—';
    return n % 1 == 0 ? '${n.toInt()}' : n.toStringAsFixed(1);
  }
}

/// Routes that require completed farm setup (AI & advisory).
const farmSetupGuardedPaths = [
  '/farmer/kisan-ai',
  '/farmer/diagnose',
  '/farmer/soil',
  '/farmer/crop-advisor',
  '/farmer/crop-calendar',
  '/farmer/advisory',
];

bool isFarmSetupGuardedPath(String location) =>
    farmSetupGuardedPaths.any((p) => location.startsWith(p));
