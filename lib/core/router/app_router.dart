import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/features/auth/presentation/screens/forgot_password.dart';
import 'package:ne3ma/features/auth/presentation/screens/verify_code_screen.dart';
import 'package:ne3ma/features/auth/presentation/screens/intro.dart';
import 'package:ne3ma/features/auth/presentation/screens/lastIntro.dart';
import 'package:ne3ma/features/auth/presentation/screens/login.dart';
import 'package:ne3ma/features/auth/presentation/screens/singup.dart';
import 'package:ne3ma/features/auth/presentation/screens/splash_screen.dart';
import 'package:ne3ma/features/profile/presentation/screens/settings_screen.dart';
import 'package:ne3ma/features/profile/presentation/screens/profile_screens.dart';

class AppRouter {
  AppRouter._();

  static const String splash         = '/';
  static const String intro          = '/intro';
  static const String signup         = '/signup';
  static const String signin         = '/signin';
  static const String forgotPassword = '/forgot-password';
  static const String verifyCode     = '/verify-code';
  static const String lastintro      = '/lastintro';
  static const String login          = '/login';
  static const String settings       = '/settings';
  static const String profile        = '/profile';
  static const String home           = '/home';

  static final router = GoRouter(
    initialLocation: splash,
    routes: [

      // ── Splash — fade transition ───────────────
      GoRoute(
        path: splash,
        pageBuilder: (context, state) => _fadePage(
          state: state,
          child: const SplashScreen(),
        ),
      ),

      // ── Intro — slide from right ───────────────
      GoRoute(
        path: intro,
        pageBuilder: (context, state) => _slideRightPage(
          state: state,
          child: const IntroScreen(),
        ),
      ),

      // ── Last Intro — slide from right ──────────
      GoRoute(
        path: lastintro,
        pageBuilder: (context, state) => _slideRightPage(
          state: state,
          child: const Lastintro(),
        ),
      ),

      // ── Login — fade + scale ───────────────────
      GoRoute(
        path: login,
        pageBuilder: (context, state) => _fadeScalePage(
          state: state,
          child: const LoginScreen(),
        ),
      ),

      // ── Sign Up — slide from right ─────────────
      GoRoute(
        path: signup,
        pageBuilder: (context, state) => _slideRightPage(
          state: state,
          child: const SignUpScreen(),
        ),
      ),

      // ── Forgot Password — slide from right ─────
      GoRoute(
        path: forgotPassword,
        pageBuilder: (context, state) => _slideRightPage(
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),

      // ── Verify Code — slide from right ─────────
      GoRoute(
        path: verifyCode,
        pageBuilder: (context, state) => _slideRightPage(
          state: state,
          child: const VerifyCodeScreen(),
        ),
      ),

      // ── Settings — slide from bottom ───────────
      GoRoute(
        path: settings,
        pageBuilder: (context, state) => _slideUpPage(
          state: state,
          child: const SettingsScreen(),
        ),
      ),

      // ── Profile — slide from right ─────────────
      GoRoute(
        path: profile,
        pageBuilder: (context, state) => _slideRightPage(
          state: state,
          child: const EditProfileScreen(),
        ),
      ),
    ],
  );

  // ── Fade ────────────────────────────────────────
  static CustomTransitionPage _fadePage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
    );
  }

  // ── Fade + Scale ────────────────────────────────
  static CustomTransitionPage _fadeScalePage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  // ── Slide from Right ────────────────────────────
  static CustomTransitionPage _slideRightPage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0), // ← comes from right
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
      },
    );
  }

  // ── Slide from Bottom ───────────────────────────
  static CustomTransitionPage _slideUpPage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0), // ← comes from bottom
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
      },
    );
  }
}