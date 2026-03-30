import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

// ── Auth State ────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({this.user, this.isLoading = false, this.error, this.isAuthenticated = false});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error, bool? isAuthenticated}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// ── Auth Notifier ─────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final _storage = const FlutterSecureStorage();
  final _api = ApiService.instance;

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      final userJson = await _storage.read(key: AppConstants.userKey);
      if (token != null && userJson != null) {
        final user = UserModel.fromJson(jsonDecode(userJson));
        state = AuthState(user: user, isAuthenticated: true);
      } else {
        state = const AuthState();
      }
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<void> sendOTP(String phone, String role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.sendOTP(phone, role);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<UserModel> verifyOTP({required String phone, required String otp, String? name, String? language, String? role}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.verifyOTP(phone: phone, otp: otp, name: name, language: language, role: role);
      final token = data['token'] as String;
      final user = UserModel.fromJson(data['user']);
      await _storage.write(key: AppConstants.tokenKey, value: token);
      await _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken'] ?? '');
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(data['user']));
      state = AuthState(user: user, isAuthenticated: true);
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<void> completeOnboarding(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.completeOnboarding(data);
      // The API returns the full user object including the updated profile and isVerified: true
      // We don't get a new token here (don't strictly need one for `isVerified` change)
      // but we *do* need to update the cached user.
      if (res['user'] == null) {
          // If the backend returns wrapped or unwrapped user
          final user = UserModel.fromJson(res);
          await _storage.write(key: AppConstants.userKey, value: jsonEncode(res));
          state = AuthState(user: user, isAuthenticated: true);
      } else {
          final user = UserModel.fromJson(res['user']);
          await _storage.write(key: AppConstants.userKey, value: jsonEncode(res['user']));
          state = AuthState(user: user, isAuthenticated: true);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    state = const AuthState();
  }

  String _parseError(dynamic e) {
    if (e is Map) return e['message'] ?? 'An error occurred';
    return e.toString();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
