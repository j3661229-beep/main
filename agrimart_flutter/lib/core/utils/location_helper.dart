import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String village;
  final String taluka;
  final String district;
  final String state;
  final String pincode;
  final String address;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.village,
    this.taluka = '',
    required this.district,
    required this.state,
    this.pincode = '',
    required this.address,
  });
}

class LocationHelper {
  /// Best-match a geocoder string to a Maharashtra district name.
  static String matchMaharashtraDistrict(String raw, {List<String>? candidates}) {
    final list = candidates ?? AppConstants.maharashtraDistricts;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Nashik';

    bool matches(String a, String b) {
      final x = a.toLowerCase();
      final y = b.toLowerCase();
      return x == y || x.contains(y) || y.contains(x);
    }

    for (final d in list) {
      if (matches(trimmed, d)) return d;
    }

    // Geocoder sometimes returns "Nashik Division" etc.
    final cleaned = trimmed.replaceAll(RegExp(r'\s*(division|district|jilla)\s*', caseSensitive: false), '').trim();
    for (final d in list) {
      if (matches(cleaned, d)) return d;
    }
    return 'Nashik';
  }

  static LocationResult? _fromPlacemark(Placemark place, Position position) {
    final taluka = (place.subAdministrativeArea ?? '').trim();
    final locality = (place.locality ?? '').trim();
    final subLocality = (place.subLocality ?? '').trim();
    final village = [subLocality, locality].where((s) => s.isNotEmpty).join(', ');
    final pincode = (place.postalCode ?? '').trim();

    final districtCandidates = [
      place.subAdministrativeArea,
      place.locality,
      place.administrativeArea,
      place.name,
    ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty);

    String district = 'Nashik';
    for (final c in districtCandidates) {
      final matched = matchMaharashtraDistrict(c);
      if (matched != 'Nashik' || c.toLowerCase().contains('nashik')) {
        district = matched;
        break;
      }
    }
    if (district == 'Nashik' && districtCandidates.isNotEmpty) {
      district = matchMaharashtraDistrict(districtCandidates.first);
    }

    final state = (place.administrativeArea ?? 'Maharashtra').trim();
    final address = [
      place.street,
      place.subLocality,
      place.locality,
      place.postalCode,
    ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      village: village.isNotEmpty ? village : (taluka.isNotEmpty ? taluka : locality),
      taluka: taluka.isNotEmpty ? taluka : locality,
      district: district,
      state: state.isNotEmpty ? state : 'Maharashtra',
      pincode: pincode,
      address: address,
    );
  }

  static Future<LocationResult?> getCurrent({LocationAccuracy accuracy = LocationAccuracy.high}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        timeLimit: const Duration(seconds: 20),
      ),
    );

    try {
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        return _fromPlacemark(placemarks.first, position);
      }
    } catch (_) {}

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      village: '',
      district: 'Nashik',
      state: 'Maharashtra',
      address: '',
    );
  }
}

/// Current farming season from calendar month (Maharashtra).
String currentFarmingSeason() {
  final m = DateTime.now().month; // 1-12
  if (m >= 6 && m <= 10) return 'Kharif';
  if (m >= 11 || m <= 2) return 'Rabi';
  return 'Zaid';
}

/// Suggested crops for season when user has none selected.
List<String> suggestedCropsForSeason(String season) {
  switch (season) {
    case 'Kharif':
      return ['Soybean', 'Cotton', 'Onion'];
    case 'Rabi':
      return ['Wheat', 'Onion', 'Tomato'];
    case 'Zaid':
      return ['Tomato', 'Maize', 'Onion'];
    default:
      return ['Onion', 'Tomato'];
  }
}
