import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ne3ma/core/network/graphql_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

// ── Repository provider ────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ── Auth State ─────────────────────────────────────────
class AuthState {
  static const Object _unset = Object();

  final UserModel? user;
  final bool isCheckingSession;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final String? pendingOtpEmail;
  final String? pendingOtpPhone;
  final String? pendingOtpType;
  final String? pendingOtpRedirectTo;

  const AuthState({
    this.user,
    this.isCheckingSession = false,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.pendingOtpEmail,
    this.pendingOtpPhone,
    this.pendingOtpType,
    this.pendingOtpRedirectTo,
  });

  bool get hasPendingVerification =>
      (pendingOtpType == 'email' &&
          pendingOtpEmail != null &&
          pendingOtpEmail!.trim().isNotEmpty) ||
      (pendingOtpType == 'phone' &&
          pendingOtpPhone != null &&
          pendingOtpPhone!.trim().isNotEmpty);

  AuthState copyWith({
    Object? user = _unset,
    bool? isCheckingSession,
    bool? isLoading,
    Object? error = _unset,
    bool? isAuthenticated,
    Object? pendingOtpEmail = _unset,
    Object? pendingOtpPhone = _unset,
    Object? pendingOtpType = _unset,
    Object? pendingOtpRedirectTo = _unset,
  }) {
    return AuthState(
      user: identical(user, _unset) ? this.user : user as UserModel?,
      isCheckingSession: isCheckingSession ?? this.isCheckingSession,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      pendingOtpEmail: identical(pendingOtpEmail, _unset)
          ? this.pendingOtpEmail
          : pendingOtpEmail as String?,
      pendingOtpPhone: identical(pendingOtpPhone, _unset)
          ? this.pendingOtpPhone
          : pendingOtpPhone as String?,
      pendingOtpType: identical(pendingOtpType, _unset)
          ? this.pendingOtpType
          : pendingOtpType as String?,
      pendingOtpRedirectTo: identical(pendingOtpRedirectTo, _unset)
          ? this.pendingOtpRedirectTo
          : pendingOtpRedirectTo as String?,
    );
  }
}

// ── Auth Notifier ──────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  static const _pendingOtpEmailKey = 'pending_otp_email';
  static const _pendingOtpPhoneKey = 'pending_otp_phone';
  static const _pendingOtpTypeKey = 'pending_otp_type';
  static const _pendingOtpRedirectKey = 'pending_otp_redirect';

  final AuthRepository _repository;

  AuthNotifier(this._repository)
    : super(const AuthState(isCheckingSession: true)) {
    _checkAuth();
  }

  // ── Check existing session on app start ─────────
  Future<void> _checkAuth() async {
    debugPrint('🔄 AuthProvider: Checking saved session...');
    state = state.copyWith(isCheckingSession: true, error: null);

    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOtpEmail = prefs.getString(_pendingOtpEmailKey);
      final pendingOtpPhone = prefs.getString(_pendingOtpPhoneKey);
      final pendingOtpType = prefs.getString(_pendingOtpTypeKey);
      final pendingOtpRedirect = prefs.getString(_pendingOtpRedirectKey);

      final accessToken = await GraphQLClient.getAccessToken();
      final refreshToken = await GraphQLClient.getRefreshToken();

      if (pendingOtpType != null &&
          ((pendingOtpType == 'email' &&
                  pendingOtpEmail != null &&
                  pendingOtpEmail.trim().isNotEmpty) ||
              (pendingOtpType == 'phone' &&
                  pendingOtpPhone != null &&
                  pendingOtpPhone.trim().isNotEmpty))) {
        debugPrint('🕒 AuthProvider: Found pending OTP verification');
        state = state.copyWith(
          isCheckingSession: false,
          isLoading: false,
          isAuthenticated: false,
          user: null,
          error: null,
          pendingOtpEmail: pendingOtpEmail,
          pendingOtpPhone: pendingOtpPhone,
          pendingOtpType: pendingOtpType,
          pendingOtpRedirectTo: pendingOtpRedirect ?? '/lastintro',
        );
        return;
      }

      if (accessToken == null && refreshToken == null) {
        debugPrint('❌ AuthProvider: No saved session found');
        state = const AuthState(isCheckingSession: false);
        return;
      }

      debugPrint('✅ AuthProvider: Saved session found, restoring user...');
      final user = await _repository.getMe();
      debugPrint('✅ AuthProvider: Welcome back ${user.fullName}');

      state = state.copyWith(
        isCheckingSession: false,
        isLoading: false,
        isAuthenticated: true,
        user: user,
        error: null,
        pendingOtpEmail: null,
        pendingOtpPhone: null,
        pendingOtpType: null,
        pendingOtpRedirectTo: null,
      );
    } catch (e) {
      debugPrint('❌ AuthProvider: Session restore failed - $e');
      await GraphQLClient.clearTokens();
      final prefs = await SharedPreferences.getInstance();
      final pendingOtpEmail = prefs.getString(_pendingOtpEmailKey);
      final pendingOtpPhone = prefs.getString(_pendingOtpPhoneKey);
      final pendingOtpType = prefs.getString(_pendingOtpTypeKey);
      final pendingOtpRedirect = prefs.getString(_pendingOtpRedirectKey);

      state = AuthState(
        isCheckingSession: false,
        pendingOtpEmail: pendingOtpEmail,
        pendingOtpPhone: pendingOtpPhone,
        pendingOtpType: pendingOtpType,
        pendingOtpRedirectTo: pendingOtpRedirect,
      );
    }
  }

  // ── Register ─────────────────────────────────────
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.register(
        fullName: fullName,
        email:    email,
        password: password,
      );
      await GraphQLClient.clearTokens();
      await _persistPendingVerification(
        type: 'email',
        email: email,
        redirectTo: '/lastintro',
      );
      state = state.copyWith(
        isLoading: false,
        user: null,
        isAuthenticated: false,
        error: null,
        pendingOtpEmail: email,
        pendingOtpPhone: null,
        pendingOtpType: 'email',
        pendingOtpRedirectTo: '/lastintro',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Login ────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final payload = await _repository.login(
        email:    email,
        password: password,
      );
      state = state.copyWith(
        isLoading:       false,
        user:            payload.user,
        isAuthenticated: true,
        error: null,
        pendingOtpEmail: null,
        pendingOtpPhone: null,
        pendingOtpType: null,
        pendingOtpRedirectTo: null,
      );
      await clearPendingVerification();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Logout ───────────────────────────────────────
  Future<void> logout() async {
    await _repository.logout();
    await clearPendingVerification();
    state = const AuthState();
  }

  // ── Send Email OTP ───────────────────────────────
  Future<bool> sendEmailOtp({required String email}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.sendEmailOtp(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Verify Email OTP ─────────────────────────────
  Future<bool> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final payload = await _repository.verifyEmailOtp(
        email: email,
        otp:   otp,
      );
      state = state.copyWith(
        isLoading:       false,
        user:            payload.user,
        isAuthenticated: true,
        error: null,
        pendingOtpEmail: null,
        pendingOtpPhone: null,
        pendingOtpType: null,
        pendingOtpRedirectTo: null,
      );
      await clearPendingVerification();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  // ── Send Phone OTP ────────────────────────────────
Future<bool> sendPhoneOtp({required String phoneNumber}) async {
  state = state.copyWith(isLoading: true, error: null);
  try {
    await _repository.sendPhoneOtp(phoneNumber: phoneNumber);
    await _persistPendingVerification(
      type: 'phone',
      phone: phoneNumber,
      redirectTo: '/home',
    );
    state = state.copyWith(
      pendingOtpEmail: null,
      pendingOtpPhone: phoneNumber,
      pendingOtpType: 'phone',
      pendingOtpRedirectTo: '/home',
    );
    state = state.copyWith(isLoading: false);
    return true;
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    return false;
  }
}

// ── Verify Phone OTP ──────────────────────────────
Future<bool> verifyPhoneOtp({
  required String phoneNumber,
  required String otp,
}) async {
  state = state.copyWith(isLoading: true, error: null);
  try {
    final payload = await _repository.verifyPhoneOtp(
      phoneNumber: phoneNumber,
      otp:         otp,
    );
    state = state.copyWith(
      isLoading:       false,
      user:            payload.user,
      isAuthenticated: true,
      error: null,
      pendingOtpEmail: null,
      pendingOtpPhone: null,
      pendingOtpType: null,
      pendingOtpRedirectTo: null,
    );
    await clearPendingVerification();
    return true;
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    return false;
  }
}

  // ── Clear error ──────────────────────────────────
  void clearError() => state = state.copyWith(error: null);

  Future<void> persistPendingEmailVerification({
    required String email,
    String redirectTo = '/lastintro',
  }) async {
    await _persistPendingVerification(
      type: 'email',
      email: email,
      redirectTo: redirectTo,
    );
    state = state.copyWith(
      pendingOtpEmail: email,
      pendingOtpPhone: null,
      pendingOtpType: 'email',
      pendingOtpRedirectTo: redirectTo,
      isAuthenticated: false,
      user: null,
    );
  }

  Future<void> clearPendingVerification() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingOtpEmailKey);
    await prefs.remove(_pendingOtpPhoneKey);
    await prefs.remove(_pendingOtpTypeKey);
    await prefs.remove(_pendingOtpRedirectKey);
    state = state.copyWith(
      pendingOtpEmail: null,
      pendingOtpPhone: null,
      pendingOtpType: null,
      pendingOtpRedirectTo: null,
    );
  }

  Future<void> _persistPendingVerification({
    required String type,
    String? email,
    String? phone,
    required String redirectTo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingOtpTypeKey, type);
    await prefs.setString(_pendingOtpRedirectKey, redirectTo);
    if (email != null) {
      await prefs.setString(_pendingOtpEmailKey, email);
      await prefs.remove(_pendingOtpPhoneKey);
    }
    if (phone != null) {
      await prefs.setString(_pendingOtpPhoneKey, phone);
      await prefs.remove(_pendingOtpEmailKey);
    }
  }
}

// ── Provider ──────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// ── Convenience providers ─────────────────────────────
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

// ── OTP shared state (ForgotPassword → VerifyCode) ────
final otpEmailProvider = StateProvider<String>((ref) => '');
final otpPhoneProvider = StateProvider<String>((ref) => '');
final otpTypeProvider  = StateProvider<String>((ref) => 'email');
