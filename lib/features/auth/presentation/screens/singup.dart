import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/core/widgets/gasp_button.dart';
import 'package:ne3ma/core/widgets/gasp_text_field.dart';
import 'package:ne3ma/features/auth/providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey            = GlobalKey<FormState>();
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // ── Validation ─────────────────────────────────
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

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
      return 'Must contain at least one uppercase letter (A-Z)';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Must contain at least one number (0-9)';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Must contain at least one special character (!@#\$%...)';
    }
    return null;
  }

  Future<void> _handleSignUp() async {
    // ── Validate form first ────────────────────
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ SignUp: Form validation failed');
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('📤 SignUp: Starting registration...');
    debugPrint('📝 SignUp: Name = ${_nameController.text}, Email = ${_emailController.text}');

    final success = await ref.read(authProvider.notifier).register(
      fullName: _nameController.text.trim(),
      email:    _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
  debugPrint('✅ SignUp: Registration successful! Sending to verify...');

  // ── Save email for verify-code screen ──────────
  ref.read(otpEmailProvider.notifier).state = _emailController.text.trim();
  ref.read(otpTypeProvider.notifier).state  = 'email';

 context.go('/verify-code', extra: '/lastintro');// ← was '/lastintro'
} else {
      final error = ref.read(authProvider).error;
      debugPrint('❌ SignUp Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Sign up failed'),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.all(24.0),
        width: double.infinity,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Back Button ────────────────────
IconButton(
  onPressed: () {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  },
  icon: const Icon(Icons.arrow_back_ios_new_outlined),
),
              const SizedBox(height: 16),

              const Text(
                'Sign Up',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              const Text(
                'Create account and choose whatever',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // ── Name ───────────────────────────
              GaspTextField(
                controller: _nameController,
                label: 'Name',
                hint: 'Your name',
                borderColor: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(25),
                backgroundColor: const Color(0xFFF2F2F2),
                textColor: Colors.grey,
                validator: _validateName,
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),

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

              // ── Password Rules Hint ────────────
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '• Min 8 characters  • One uppercase  • One number  • One special char',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Register Button ────────────────
              GaspButton(
                label: _isLoading ? 'Registering...' : 'Register',
                onPressed: _isLoading ? null : _handleSignUp,
                height: 60,
                borderRadius: 30,
                buttonColor: AppColors.primaryMid,
                textColor: Colors.white,
              ),
              const SizedBox(height: 16),

              // ── Sign In Link ───────────────────
              Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(
                        text: 'Sign In',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => context.go('/login'),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // ── Terms ──────────────────────────
              const Text(
                'By clicking register, you agree to our Terms and Conditions',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}