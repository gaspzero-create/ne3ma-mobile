import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/features/auth/presentation/screens/forgot_password.dart';
import 'package:ne3ma/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:ne3ma/features/auth/presentation/screens/verify_code_screen.dart';
import 'package:ne3ma/features/auth/presentation/screens/intro.dart';
import 'package:ne3ma/features/auth/presentation/screens/lastIntro.dart';
import 'package:ne3ma/features/auth/presentation/screens/login.dart';
import 'package:ne3ma/features/auth/presentation/screens/singup.dart';
import 'package:ne3ma/features/auth/presentation/screens/splash_screen.dart';
import 'package:ne3ma/features/auth/providers/auth_provider.dart';
import 'package:ne3ma/features/chat/presentation/screens/messages_tab.dart';
import 'package:ne3ma/features/donations/presentation/screens/add_donation_screen.dart';
import 'package:ne3ma/features/donations/presentation/screens/donation_detail_screen.dart';
import 'package:ne3ma/features/donations/data/models/donation_model.dart';
import 'package:ne3ma/features/donations/presentation/screens/special_tab.dart';
import 'package:ne3ma/features/home/presentation/screens/home_screen.dart';
import 'package:ne3ma/features/home/presentation/screens/home_tab.dart';
import 'package:ne3ma/features/leaderboard/presentation/screens/leaderboard_screen.dart';
import 'package:ne3ma/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:ne3ma/features/notifications/presentation/screens/push_debug_screen.dart';
import 'package:ne3ma/features/profile/presentation/screens/settings_screen.dart';
import 'package:ne3ma/features/profile/presentation/screens/profile_screens.dart';
import 'package:ne3ma/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:ne3ma/features/profile/presentation/screens/terms_and_conditions_screen.dart';
import 'package:ne3ma/features/profile/presentation/screens/help_and_support_screen.dart';
import 'package:ne3ma/features/reports/presentation/screens/report_donation_screen.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String intro = '/intro';
  static const String signup = '/signup';
  static const String signin = '/signin';
  static const String forgotPassword = '/forgot-password';
  static const String verifyCode = '/verify-code';
  static const String resetPassword = '/reset-password';
  static const String lastintro = '/lastintro';
  static const String login = '/login';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String home = '/home';
  static const String notifications = '/notifications';
  static const String pushDebug = '/push-debug';
  static const String reportDonation = '/report-donation';

  static final router = GoRouter(
    initialLocation: splash,
    routes: [
      // ── Splash — fade transition ───────────────
      GoRoute(
        path: splash,
        pageBuilder: (context, state) =>
            _fadePage(state: state, child: const SplashScreen()),
      ),

      GoRoute(
        path: intro,
        pageBuilder: (context, state) =>
            _slideRightPage(state: state, child: const IntroScreen()),
      ),

      GoRoute(
        path: lastintro,
        pageBuilder: (context, state) =>
            _slideRightPage(state: state, child: const Lastintro()),
      ),

      GoRoute(
        path: login,
        pageBuilder: (context, state) =>
            _loginPage(state: state, child: const LoginScreen()),
      ),

      GoRoute(
        path: signup,
        pageBuilder: (context, state) =>
            _slideRightPage(state: state, child: const SignUpScreen()),
      ),

      GoRoute(
        path: forgotPassword,
        pageBuilder: (context, state) =>
            _slideRightPage(state: state, child: const ForgotPasswordScreen()),
      ),

      GoRoute(
        path: verifyCode,
        pageBuilder: (context, state) {
          final redirect =
              state.uri.queryParameters['redirectTo'] ??
              (state.extra as String? ?? lastintro);
          return _slideRightPage(
            state: state,
            child: VerifyCodeScreen(redirectTo: redirect),
          );
        },
      ),

      GoRoute(
        path: resetPassword,
        pageBuilder: (context, state) => _slideRightPage(
          state: state,
          child: const ResetPasswordScreen(),
        ),
      ),

      GoRoute(
        path: settings,
        pageBuilder: (context, state) =>
            _slideUpPage(state: state, child: const SettingsScreen()),
      ),

      GoRoute(
        path: profile,
        pageBuilder: (context, state) =>
            _slideRightPage(state: state, child: const EditProfileScreen()),
      ),

      GoRoute(
        path: notifications,
        pageBuilder: (context, state) =>
            _slideRightPage(state: state, child: const NotificationsScreen()),
      ),

      GoRoute(
        path: pushDebug,
        pageBuilder: (context, state) =>
            _slideRightPage(state: state, child: const PushDebugScreen()),
      ),

      GoRoute(
        path: reportDonation,
        pageBuilder: (context, state) {
          final donation = state.extra as DonationModel;
          return _slideRightPage(
            state: state,
            child: ReportDonationScreen(donation: donation),
          );
        },
      ),

      GoRoute(
        path: '/privacy-policy',
        pageBuilder: (context, state) =>
            _slideRightPage(state: state, child: const PrivacyPolicyScreen()),
      ),

      GoRoute(
        path: '/terms-and-conditions',
        pageBuilder: (context, state) => _slideRightPage(
          state: state,
          child: const TermsAndConditionsScreen(),
        ),
      ),

      GoRoute(
        path: '/help-support',
        pageBuilder: (context, state) =>
            _slideRightPage(state: state, child: const HelpAndSupportScreen()),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                builder: (context, state) => const MessagesTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/add',
                builder: (context, state) => const AddDonationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/special',
                builder: (context, state) => const SpecialTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile-tab',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/donation/:id',
        pageBuilder: (context, state) {
          final donation = state.extra as DonationModel;
          return _slideRightPage(
            state: state,
            child: DonationDetailScreen(donation: donation),
          );
        },
      ),

      GoRoute(
        path: '/leaderboard',
        pageBuilder: (context, state) =>
            _slideRightPage(state: state, child: const LeaderboardScreen()),
      ),

      //       ShellRoute(
      //   builder: (context, state, child) {
      //     return HomeScreen(child: child);
      //   },
      //   routes: [
      //     GoRoute(
      //       path: '/home',
      //       pageBuilder: (context, state) => _fadePage(
      //         state: state,
      //         child: const HomeTab(),
      //       ),
      //     ),
      //     GoRoute(
      //       path: '/messages',
      //       pageBuilder: (context, state) => _fadePage(
      //         state: state,
      //         child: const MessagesTab(),
      //       ),
      //     ),
      //     GoRoute(
      //       path: '/special',
      //       pageBuilder: (context, state) => _fadePage(
      //         state: state,
      //         child: const SpecialTab(),
      //       ),
      //     ),
      //     GoRoute(
      //       path: '/profile-tab',
      //       pageBuilder: (context, state) => _fadePage(
      //         state: state,
      //         child: const ProfileTab(),
      //       ),
      //     ),
      //   ],
      // ),
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
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
    );
  }

  // ── Login Transition ───────────────────────────
  static CustomTransitionPage _loginPage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
        );
        final slide = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final scale = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart,
        );

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.06),
              end: Offset.zero,
            ).animate(slide),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1.0).animate(scale),
              child: child,
            ),
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
          child: FadeTransition(opacity: curved, child: child),
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
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  static GoRouter routerWithRef(WidgetRef ref) => GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: splash,
    // ── Auth redirect ──────────────────────────
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.isAuthenticated;
      final isCheckingSession = authState.isCheckingSession;
      final hasPendingVerification = authState.hasPendingVerification;
      final pendingRedirect = authState.pendingOtpRedirectTo ?? lastintro;

      // Still checking auth → stay on splash
      if (isCheckingSession) return splash;

      final goingToVerify = state.matchedLocation.startsWith(verifyCode);
      if (hasPendingVerification && !goingToVerify) {
        return '$verifyCode?redirectTo=$pendingRedirect';
      }

      final protectedRoutes = [
        '/home',
        '/messages',
        '/add',
        '/donation',
        '/notifications',
        '/report-donation',
        '/settings',
        '/profile',
        '/profile-tab',
        '/special',
      ];
      final isGoingToProtected = protectedRoutes.any(
        (r) => state.matchedLocation.startsWith(r),
      );

      // Not auth + going to protected → go to login
      if (!isAuth && isGoingToProtected) return login;

      // Auth + going to auth screens → go to home
      final authRoutes = ['/login', '/signup', '/intro'];
      final isGoingToAuth = authRoutes.any(
        (r) => state.matchedLocation.startsWith(r),
      );
      if (isAuth && isGoingToAuth && !hasPendingVerification) return home;

      return null; // no redirect
    },
    routes: router.configuration.routes,
  );
}
