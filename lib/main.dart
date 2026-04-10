import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ne3ma/core/network/graphql_client.dart';
import 'package:ne3ma/core/router/app_router.dart';
import 'package:ne3ma/core/theme/app_theme.dart';
import 'package:ne3ma/features/auth/providers/auth_provider.dart';

void main() {
    WidgetsFlutterBinding.ensureInitialized();
  
  // ── Wake up Render server ──────────────────────
  _wakeUpServer();
  runApp(ProviderScope(child: const MyApp()));
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
    ref.watch(authProvider);

    return MaterialApp.router(
      title: "NEJMA",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.routerWithRef(ref), // ← pass ref
    );
  }
}
