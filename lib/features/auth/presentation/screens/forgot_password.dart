import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/core/widgets/gasp_button.dart';
import 'package:ne3ma/core/widgets/gasp_text_field.dart';
import 'package:ne3ma/features/auth/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  String _selectedOption = 'email';
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    // ── Validation ─────────────────────────────────
    if (_selectedOption == 'email' && _emailController.text.trim().isEmpty) {
      debugPrint('❌ ForgotPassword: Email field is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    if (_selectedOption == 'phone' && _phoneController.text.trim().isEmpty) {
      debugPrint('❌ ForgotPassword: Phone field is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('📤 ForgotPassword: Sending OTP via $_selectedOption');

    try {
      bool success = false;

      if (_selectedOption == 'email') {
        // ── Email OTP ─────────────────────────────
        final email = _emailController.text.trim();
        debugPrint('📧 ForgotPassword: Email = $email');

        ref.read(otpEmailProvider.notifier).state = email;
        ref.read(otpTypeProvider.notifier).state  = 'email';
        debugPrint('💾 ForgotPassword: Email saved in provider = $email');

        success = await ref.read(authProvider.notifier).sendEmailOtp(
          email: email,
        );
        debugPrint('📬 ForgotPassword: sendEmailOtp result = $success');

      } else {
        // ── Phone OTP ─────────────────────────────
        final phone = _phoneController.text.trim();
        debugPrint('📱 ForgotPassword: Phone = $phone');

        ref.read(otpPhoneProvider.notifier).state = phone;
        ref.read(otpTypeProvider.notifier).state  = 'phone';
        debugPrint('💾 ForgotPassword: Phone saved in provider = $phone');

        success = await ref.read(authProvider.notifier).sendPhoneOtp(
          phoneNumber: phone,
        );
        debugPrint('📬 ForgotPassword: sendPhoneOtp result = $success');
      }

      if (!mounted) return;

      if (success) {
        debugPrint('✅ ForgotPassword: OTP sent! Navigating to /verify-code');
        context.go('/verify-code');
      } else {
        final error = ref.read(authProvider).error;
        debugPrint('❌ ForgotPassword: Failed - $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Failed to send OTP')),
        );
      }
    } catch (e) {
      debugPrint('💥 ForgotPassword: Exception - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SizedBox(
        width: 375,
        height: 812,
        child: Container(
          color: const Color(0xFFFAFAFA),
          margin: const EdgeInsets.only(top: 50, left: 24.0, right: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.arrow_back_ios_new_outlined),
              ),
              const SizedBox(height: 32),
              const Text(
                'Forgot Password',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              const Text(
                'Select which contact details should we use to reset your password',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // ── Email Option ───────────────────────
              GestureDetector(
                onTap: () => setState(() => _selectedOption = 'email'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedOption == 'email'
                          ? AppColors.primaryMid
                          : Colors.grey[300]!,
                      width: _selectedOption == 'email' ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Via Email',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '***@example.com',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_selectedOption == 'email') ...[
                const SizedBox(height: 16),
                GaspTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  borderColor: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(25),
                  backgroundColor: const Color(0xFFF2F2F2),
                  textColor: Colors.grey,
                  onChanged: (value) {},
                ),
              ],

              const SizedBox(height: 16),

              // ── Phone Option ───────────────────────
              GestureDetector(
                onTap: () => setState(() => _selectedOption = 'phone'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedOption == 'phone'
                          ? AppColors.primaryMid
                          : Colors.grey[300]!,
                      width: _selectedOption == 'phone' ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.phone_outlined,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Via Phone Number',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+213 (0) ***-**45',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_selectedOption == 'phone') ...[
                const SizedBox(height: 16),
                GaspTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  borderColor: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(25),
                  backgroundColor: const Color(0xFFF2F2F2),
                  textColor: Colors.grey,
                  onChanged: (value) {},
                ),
              ],

              const SizedBox(height: 32),

              GaspButton(
                label: _isLoading ? 'Sending OTP...' : 'Continue',
                onPressed: _isLoading ? null : _handleContinue,
                height: 60,
                borderRadius: 30,
                buttonColor: AppColors.primaryMid,
                textColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}