import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield* connectivity.onConnectivityChanged.map((results) {
    if (results.isEmpty) return false;
    return !results.every((r) => r == ConnectivityResult.none);
  });
});

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).maybeWhen(data: (v) => v, orElse: () => true);
});
