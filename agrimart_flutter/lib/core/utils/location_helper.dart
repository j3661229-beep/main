import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String village;
  final String district;
  final String state;
  final String address;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.village,
    required this.district,
    required this.state,
    required this.address,
  });
}

class LocationHelper {
  static Future<LocationResult?> getCurrent() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );

    String village = '';
    String district = '';
    String state = 'Maharashtra';
    String address = '';

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        village = [
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
        ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');
        district = place.subAdministrativeArea ?? place.locality ?? '';
        state = place.administrativeArea ?? state;
        address = [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
        ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).join(', ');
      }
    } catch (_) {}

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      village: village,
      district: district,
      state: state,
      address: address,
    );
  }
}
