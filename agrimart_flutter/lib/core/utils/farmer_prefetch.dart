import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_providers.dart';
import '../../data/providers/auth_provider.dart';

/// Background prefetch for farmer home — never blocks UI.
void prefetchFarmerHomeData(WidgetRef ref) {
  if (!ref.read(farmSetupCompleteProvider)) return;

  final user = ref.read(authProvider).user;
  final district = user?.effectiveDistrict ?? 'Nashik';
  final month = DateTime.now().month - 1;

  Future.wait([
    ref.read(farmerDashboardProvider.future).catchError((_) => <String, dynamic>{}),
    ref.read(weatherProvider.future).catchError((_) => <String, dynamic>{}),
    ref.read(cropCalendarProvider(month).future).catchError((_) => <String, dynamic>{}),
    ref.read(mandiTickerProvider.future).catchError((_) => <Map<String, dynamic>>[]),
    ref.read(mandiNewsProvider.future).catchError((_) => <dynamic>[]),
    ref.read(weatherAdvisoryProvider(district).future).catchError((_) => <String, dynamic>{}),
  ]);
}

/// Prefetch public data for logged-out users.
void prefetchPublicData(WidgetRef ref) {
  ref.read(mandiNewsProvider.future).catchError((_) => <dynamic>[]);
  ref.read(schemesProvider.future).catchError((_) => <dynamic>[]);
}
