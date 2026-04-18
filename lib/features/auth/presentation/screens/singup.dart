import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/core/widgets/gasp_button.dart';
import 'package:ne3ma/core/widgets/gasp_text_field.dart';
import 'package:ne3ma/features/auth/providers/auth_provider.dart';
import 'package:ne3ma/l10n/generated/app_localizations.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // ── Validation ─────────────────────────────────
  String? _validateName(String? value, AppLocalizations loc) {
    if (value == null || value.trim().isEmpty) {
      return loc.nameRequired;
    }
    if (value.trim().length < 3) {
      return loc.nameMin;
    }
    return null;
  }

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

  Future<void> _handleSignUp() async {
    // ── Validate form first ────────────────────
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ SignUp: Form validation failed');
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('📤 SignUp: Starting registration...');
    debugPrint(
      '📝 SignUp: Name = ${_nameController.text}, Email = ${_emailController.text}',
    );

    final success = await ref
        .read(authProvider.notifier)
        .register(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      debugPrint('✅ SignUp: Registration successful! Sending to verify...');

      // ── Save email for verify-code screen ──────────
      ref.read(otpEmailProvider.notifier).state = _emailController.text.trim();
      ref.read(otpTypeProvider.notifier).state = 'email';

      context.go('/verify-code', extra: '/lastintro'); // ← was '/lastintro'
    } else {
      final error = ref.read(authProvider).error;
      debugPrint('❌ SignUp Error: $error');
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? loc.signUpFailed),
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
    final loc = AppLocalizations.of(context);
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

              Text(
                loc.signUp,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                loc.createAccountDesc,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // ── Name ───────────────────────────
              GaspTextField(
                controller: _nameController,
                label: loc.name,
                hint: loc.nameHint,
                borderColor: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(25),
                backgroundColor: const Color(0xFFF2F2F2),
                textColor: Colors.grey,
                validator: (val) => _validateName(val, loc),
                onChanged: (_) {},
              ),
              const SizedBox(height: 16),

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

              // ── Password Rules Hint ────────────
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  loc.passwordRules,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Register Button ────────────────
              GaspButton(
                label: _isLoading ? loc.registering : loc.register,
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
                      TextSpan(
                        text: loc.haveAccount,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(
                        text: loc.signIn,
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
              Text(
                loc.agreeTerms,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Text(
                    loc.privacyPolicy,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
