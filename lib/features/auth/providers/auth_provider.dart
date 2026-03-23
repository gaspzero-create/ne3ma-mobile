import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

// ── Repository provider ────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ── Auth State ─────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user:            user            ?? this.user,
      isLoading:       isLoading       ?? this.isLoading,
      error:           error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// ── Auth Notifier ──────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _checkAuth();
  }

  // ── Check existing token on app start ───────────
  Future<void> _checkAuth() async {
    final isAuth = await _repository.isAuthenticated();
    state = state.copyWith(isAuthenticated: isAuth);
  }

  // ── Register ─────────────────────────────────────
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final payload = await _repository.register(
        fullName: fullName,
        email:    email,
        password: password,
      );
      state = state.copyWith(
        isLoading:       false,
        user:            payload.user,
        isAuthenticated: true,
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
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Logout ───────────────────────────────────────
  Future<void> logout() async {
    await _repository.logout();
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
      );
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
    );
    return true;
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    return false;
  }
}

  // ── Clear error ──────────────────────────────────
  void clearError() => state = state.copyWith(error: null);
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