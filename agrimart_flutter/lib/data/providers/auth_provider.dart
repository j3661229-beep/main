import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
        // Load fast from cache
        var user = UserModel.fromJson(jsonDecode(userJson));
        state = AuthState(user: user, isAuthenticated: true);
        
        // Fetch fresh data in background to fix verification status loops
        try {
          final res = await _api.getMe();
          if (res['success'] == true && res['data'] != null) {
            final freshUserJson = res['data']['user'] ?? res['data'];
            user = UserModel.fromJson(freshUserJson);
            await _storage.write(key: AppConstants.userKey, value: jsonEncode(freshUserJson));
            state = AuthState(user: user, isAuthenticated: true);
          }
        } catch (_) {
          // Ignore network errors at init, keep cached data
        }
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
      await _api.sendOTP(phone: phone, role: role);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<UserModel?> signInWithGoogle(String role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return null;
      }

      final data = await _api.googleSignIn({
        'email': googleUser.email,
        'googleId': googleUser.id,
        'name': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
        'role': role,
      });

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
      final freshUserJson = res['data']?['user'] ?? res['data'] ?? res['user'] ?? res;
      
      final userData = Map<String, dynamic>.from(freshUserJson);
      final user = UserModel.fromJson(userData);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(userData));
      state = AuthState(user: user, isAuthenticated: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<void> logout() async {
    // Instant UI feedback: Reset state immediately to trigger GoRouter redirect
    state = const AuthState();
    
    // Cleanup in background
    try {
      await _api.logout();
      await _storage.deleteAll();
    } catch (e) {
      // Background cleanup error isn't fatal as state is already reset
    }
  }

  String _parseError(dynamic e) {
    if (e is Map) return e['message'] ?? 'An error occurred';
    return e.toString();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
