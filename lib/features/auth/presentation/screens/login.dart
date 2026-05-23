import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/core/widgets/gasp_button.dart';
import 'package:ne3ma/core/widgets/gasp_text_field.dart';
import 'package:ne3ma/features/auth/providers/auth_provider.dart';
import 'package:ne3ma/l10n/generated/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // ── Validation ─────────────────────────────────
  String? _validateEmail(String? value, AppLocalizations loc) {
    if (value == null || value.trim().isEmpty) {
      return loc.emailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return loc.emailInvalid;
    }
    return null;
  }

  String? _validatePassword(String? value, AppLocalizations loc) {
    if (value == null || value.isEmpty) {
      return loc.passwordRequired;
    }
    if (value.length < 8) {
      return loc.passwordMin;
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return loc.passwordUpper;
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return loc.passwordNumber;
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return loc.passwordSpecial;
    }
    return null;
  }

  Future<void> _handleLogin() async {
    // ── Validate form first ────────────────────
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Login: Form validation failed');
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('📤 Login: Starting login...');
    debugPrint('📝 Login: Email = ${_emailController.text.trim()}');

    final success = await ref
        .read(authProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      debugPrint('✅ Login: Successfully logged in!');
      context.go('/home');
    } else {
      final error = ref.read(authProvider).error;
      debugPrint('❌ Login Error: $error');
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? loc.loginFailed),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 50, left: 24.0, right: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.welcomeBack,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                loc.enterEmailPassword,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // ── Email ──────────────────────────
              GaspTextField(
                controller: _emailController,
                label: loc.email,
                hint: loc.emailHint,
                textDirection: TextDirection.ltr,
                borderColor: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(25),
                backgroundColor: const Color(0xFFF2F2F2),
                textColor: Colors.grey,
                validator: (val) => _validateEmail(val, loc),
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),

              // ── Password ───────────────────────
              GaspTextField(
                controller: _passwordController,
                label: loc.password,
                hint: loc.passwordHint,
                textDirection: TextDirection.ltr,
                borderColor: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(25),
                backgroundColor: const Color(0xFFF2F2F2),
                textColor: Colors.grey,
                isPassword: true,
                validator: (val) => _validatePassword(val, loc),
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),

              // ── Forgot Password ────────────────
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.go('/forgot-password'),
                  child: Text(
                    loc.forgotPassword,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryMid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Login Button ───────────────────
              GaspButton(
                label: loc.login,
                onPressed: _isLoading ? null : _handleLogin,
                height: 60,
                borderRadius: 30,
                buttonColor: AppColors.primaryMid,
                textColor: Colors.white,
              ),
              const SizedBox(height: 24),

              // ── OR Divider ─────────────────────
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: Colors.grey, thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      loc.or,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: Colors.grey, thickness: 1),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Google Button ──────────────────
              GaspButton(
                label: loc.continueWithGoogle,
                onPressed: () {
                  // TODO: Google OAuth
                },
                height: 60,
                borderRadius: 30,
                buttonColor: Colors.white,
                textColor: Colors.black,
                icon: FontAwesomeIcons.google,
              ),

              const SizedBox(height: 24),

              // ── Sign Up Link ───────────────────
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/signup'),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: loc.dontHaveAccount,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        TextSpan(
                          text: loc.signUp,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
