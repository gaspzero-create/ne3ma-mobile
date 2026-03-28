import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/core/widgets/gasp_button.dart';
import 'package:ne3ma/core/widgets/gasp_text_field.dart';
import 'package:ne3ma/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // ── Validation ─────────────────────────────────
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Minimum 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Must contain at least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Must contain at least one special character (!@#\$%...)';
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

    final success = await ref.read(authProvider.notifier).login(
      email:    _emailController.text.trim(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Login failed'),
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
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 50, left: 24.0, right: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                'Welcome Back!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              const Text(
                'Enter your email and password to log in',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // ── Email ──────────────────────────
              GaspTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Your email',
                borderColor: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(25),
                backgroundColor: const Color(0xFFF2F2F2),
                textColor: Colors.grey,
                validator: _validateEmail,
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),

              // ── Password ───────────────────────
              GaspTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Your password',
                borderColor: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(25),
                backgroundColor: const Color(0xFFF2F2F2),
                textColor: Colors.grey,
                isPassword: true,
                validator: _validatePassword,
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),

              // ── Forgot Password ────────────────
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.go('/forgot-password'),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
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
                label: _isLoading ? 'Logging in...' : 'Login',
                onPressed: _isLoading ? null : _handleLogin,
                height: 60,
                borderRadius: 30,
                buttonColor: AppColors.primaryMid,
                textColor: Colors.white,
              ),
              const SizedBox(height: 24),

              // ── OR Divider ─────────────────────
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey, thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey, thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),

              // ── Google Button ──────────────────
              GaspButton(
                label: 'Continue with Google',
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
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
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