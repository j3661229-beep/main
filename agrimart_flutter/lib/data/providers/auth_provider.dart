import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/constants/app_constants.dart';

import '../../core/utils/farm_profile_utils.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/profile_cache.dart';

// ── Auth State ────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isInitialized;
  final String? error;
  final bool isAuthenticated;
  final bool farmSetupComplete;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
    this.isAuthenticated = false,
    this.farmSetupComplete = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    bool? isAuthenticated,
    bool? farmSetupComplete,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      farmSetupComplete: farmSetupComplete ?? this.farmSetupComplete,
    );
  }
}

// ── Auth Notifier ─────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState()) {
    _init();
  }

  final Ref _ref;
  final _storage = const FlutterSecureStorage();
  final _api = ApiService.instance;

  String _farmSetupKey(String userId) => '${AppConstants.onboardingKey}_$userId';

  Future<bool> _resolveFarmSetupComplete(UserModel? user, {Map? farmSetupApi}) async {
    if (user == null || !user.isFarmer) return true;

    if (farmSetupApi != null) {
      final complete = farmSetupApi['isComplete'] == true;
      if (complete) {
        await _storage.write(key: _farmSetupKey(user.id), value: 'true');
      } else {
        await _storage.delete(key: _farmSetupKey(user.id));
      }
      return complete;
    }

    if (FarmProfileUtils.isSetupComplete(user)) {
      await _storage.write(key: _farmSetupKey(user.id), value: 'true');
      return true;
    }
    final local = await _storage.read(key: _farmSetupKey(user.id));
    return local == 'true';
  }

  Future<AuthState> _authStateForUser(UserModel user, {Map? farmSetupApi}) async {
    final setupComplete = await _resolveFarmSetupComplete(user, farmSetupApi: farmSetupApi);
    return AuthState(
      user: user,
      isAuthenticated: true,
      farmSetupComplete: setupComplete,
      isInitialized: true,
    );
  }

  void _syncLocaleFromUser(UserModel user) {
    final locale = LocaleNotifier.localeFromUserLanguage(user.language);
    if (locale != null) {
      _ref.read(localeProvider.notifier).setLocale(locale);
    }
  }

  Future<UserModel> _applySession({
    required String token,
    required String refreshToken,
    required Map userJson,
    Map? farmSetup,
  }) async {
    final user = UserModel.fromJson(Map<String, dynamic>.from(userJson));
    await Future.wait([
      _storage.write(key: AppConstants.tokenKey, value: token),
      _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken),
      _storage.write(key: AppConstants.userKey, value: jsonEncode(userJson)),
      ProfileCache.save(
        Map<String, dynamic>.from(userJson),
        farmSetup: farmSetup != null ? Map<String, dynamic>.from(farmSetup) : null,
      ),
    ]);
    _syncLocaleFromUser(user);
    state = (await _authStateForUser(user, farmSetupApi: farmSetup)).copyWith(isLoading: false);
    return user;
  }

  Future<void> _refreshProfileFromServer() async {
    try {
      final res = await _api.getMe();
      if (res['success'] != true || res['data'] == null) return;
      final data = res['data'] as Map;
      final freshUserJson = data['user'] ?? data;
      final farmSetup = data['farmSetup'] as Map?;
      final user = UserModel.fromJson(Map<String, dynamic>.from(freshUserJson as Map));
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(freshUserJson));
      await ProfileCache.save(
        Map<String, dynamic>.from(freshUserJson),
        farmSetup: farmSetup != null ? Map<String, dynamic>.from(farmSetup) : null,
      );
      _syncLocaleFromUser(user);
      state = await _authStateForUser(user, farmSetupApi: farmSetup);
    } catch (_) {}
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final reads = await Future.wait([
        _storage.read(key: AppConstants.tokenKey),
        _storage.read(key: AppConstants.userKey),
      ]);
      final token = reads[0];
      final userJsonStr = reads[1];
      final hiveProfile = ProfileCache.load();

      if (token != null) {
        Map<String, dynamic>? userMap;
        Map<String, dynamic>? farmSetupApi;

        if (userJsonStr != null) {
          userMap = Map<String, dynamic>.from(jsonDecode(userJsonStr) as Map);
          farmSetupApi = hiveProfile?.farmSetup;
        } else if (hiveProfile != null) {
          userMap = hiveProfile.userJson;
          farmSetupApi = hiveProfile.farmSetup;
        }

        if (userMap != null) {
          final user = UserModel.fromJson(userMap);
          _syncLocaleFromUser(user);
          state = (await _authStateForUser(user, farmSetupApi: farmSetupApi)).copyWith(isLoading: false);

          final needsRefresh = hiveProfile == null || !ProfileCache.isFresh(hiveProfile.cachedAt);
          if (needsRefresh) {
            // Stale-while-revalidate — UI already shown from cache
            // ignore: discarded_futures
            _refreshProfileFromServer();
          }
          return;
        }
      }
      state = const AuthState(isInitialized: true);
    } catch (_) {
      state = const AuthState(isInitialized: true);
    }
  }

  Future<UserModel> registerWithPassword(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.registerWithPassword(data);
      return _applySession(
        token: res['token'] as String,
        refreshToken: res['refreshToken']?.toString() ?? '',
        userJson: Map<String, dynamic>.from(res['user'] as Map),
        farmSetup: res['farmSetup'] as Map?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<UserModel> loginWithPassword({
    required String emailOrPhone,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.loginWithPassword(
        emailOrPhone: emailOrPhone,
        password: password,
        role: role,
      );
      return _applySession(
        token: data['token'] as String,
        refreshToken: data['refreshToken']?.toString() ?? '',
        userJson: Map<String, dynamic>.from(data['user'] as Map),
        farmSetup: data['farmSetup'] as Map?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<void> sendOTP({required String phone, required String role}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.sendOTP(phone: phone, role: role);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<UserModel> verifyOTP({
    required String phone,
    required String otp,
    String? name,
    String? role,
    String? language,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.verifyOTP(
        phone: phone,
        otp: otp,
        name: name,
        role: role,
        language: language,
      );

      var user = await _applySession(
        token: data['token'] as String,
        refreshToken: data['refreshToken']?.toString() ?? '',
        userJson: Map<String, dynamic>.from(data['user'] as Map),
        farmSetup: data['farmSetup'] as Map?,
      );

      if (_api.pendingSignupData != null) {
        try {
          final onboardData = Map<String, dynamic>.from(_api.pendingSignupData!);
          onboardData['role'] = role ?? user.role;
          await completeOnboarding(onboardData);
          _api.pendingSignupData = null;
          return state.user ?? user;
        } catch (_) {}
      }

      return state.user ?? user;
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

      final token = data['token'];
      if (token is! String || token.isEmpty) {
        throw Exception('Login failed: no token received from server');
      }
      final userJson = data['user'];
      if (userJson is! Map) {
        throw Exception('Login failed: invalid user data from server');
      }

      return _applySession(
        token: token,
        refreshToken: data['refreshToken']?.toString() ?? '',
        userJson: Map<String, dynamic>.from(userJson),
        farmSetup: data['farmSetup'] as Map?,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<void> completeOnboarding(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.completeOnboarding(data);
      final responseData = (res['data'] as Map?) ?? <String, dynamic>{};
      final freshUserJson = responseData['user'] ?? responseData;
      final farmSetup = responseData['farmSetup'] as Map?;

      final userData = Map<String, dynamic>.from(freshUserJson as Map);
      final user = UserModel.fromJson(userData);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(userData));
      await ProfileCache.save(userData, farmSetup: farmSetup != null ? Map<String, dynamic>.from(farmSetup) : null);
      state = (await _authStateForUser(user, farmSetupApi: farmSetup)).copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      rethrow;
    }
  }

  Future<void> refreshUser() async {
    await _refreshProfileFromServer();
  }

  Future<void> logout() async {
    state = const AuthState(isInitialized: true);
    try {
      await _api.logout();
      await Future.wait([
        _storage.deleteAll(),
        ProfileCache.clear(),
      ]);
    } catch (_) {}
  }

  String _parseError(dynamic e) {
    return extractUserFacingError(e is Exception ? e : Exception(e.toString()));
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));

final userProvider = Provider<UserModel?>((ref) => ref.watch(authProvider).user);

/// True when farm profile is complete — shorthand for guards and prefetch.
final farmSetupCompleteProvider = Provider<bool>((ref) => ref.watch(authProvider).farmSetupComplete);
