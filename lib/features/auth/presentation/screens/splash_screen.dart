import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/features/auth/providers/auth_provider.dart';


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  void _navigateAfterDelay() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;

      final authState = ref.read(authProvider);
      if (authState.isLoading) {
        _navigateAfterDelay();
        return;
      }

      context.go(authState.isAuthenticated ? '/home' : '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.markerFresh,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/animations/NE3MA-SVG 1.svg',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
