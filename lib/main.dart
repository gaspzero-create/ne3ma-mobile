import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ne3ma/l10n/generated/app_localizations.dart';
import 'package:ne3ma/core/network/graphql_client.dart';
import 'package:ne3ma/core/router/app_router.dart';
import 'package:ne3ma/core/theme/app_theme.dart';
import 'package:ne3ma/features/auth/providers/auth_provider.dart';
import 'package:ne3ma/core/providers/locale_provider.dart';

import 'package:ne3ma/core/services/push_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase & Notifications ────────────────────
  try {
    await Firebase.initializeApp();
    await PushNotificationService().init();
  } catch (e) {
    debugPrint('Firebase init failed: \$e');
  }

  _configureImageErrorFiltering();

  // ── Wake up Render server ──────────────────────
  _wakeUpServer();
  runApp(ProviderScope(child: const MyApp()));
}

void _configureImageErrorFiltering() {
  final previousOnError = FlutterError.onError;
  final previousPresentError = FlutterError.presentError;

  FlutterError.onError = (FlutterErrorDetails details) {
    if (_shouldIgnoreImage404(details.exception)) {
      return;
    }

    previousOnError?.call(details);
  };

  FlutterError.presentError = (FlutterErrorDetails details) {
    if (_shouldIgnoreImage404(details.exception)) {
      return;
    }

    previousPresentError(details);
  };
}

bool _shouldIgnoreImage404(Object exception) {
  return exception is NetworkImageLoadException && exception.statusCode == 404;
}

Future<void> _wakeUpServer() async {
  try {
    debugPrint('🔄 main: Waking up server...');
    await GraphQLClient.query(document: '{ ping }');
    debugPrint('✅ main: Server is awake!');
  } catch (e) {
    // Don't block the app if ping fails
    debugPrint('⚠️ main: Server wake up failed - $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      final becameAuthenticated =
          next.isAuthenticated &&
          next.user != null &&
          (previous?.isAuthenticated != true ||
              previous?.user?.id != next.user?.id);

      if (becameAuthenticated) {
        unawaited(PushNotificationService().syncTokenWithBackend());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(PushNotificationService().processPendingLaunchNotification());
      if (authState.isAuthenticated && authState.user != null) {
        unawaited(PushNotificationService().syncTokenWithBackend());
      }
    });

    return MaterialApp.router(
      title: "NEJMA",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.routerWithRef(ref), // ← pass ref
      locale: ref.watch(localeProvider),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar'), Locale('fr')],
    );
  }
}
