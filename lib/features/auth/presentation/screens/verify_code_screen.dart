import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:ne3ma/core/widgets/gasp_button.dart';
import 'package:ne3ma/features/auth/providers/auth_provider.dart';
import 'package:ne3ma/l10n/generated/app_localizations.dart';

class VerifyCodeScreen extends ConsumerStatefulWidget {
  const VerifyCodeScreen({
    super.key,
    this.redirectTo = '/lastintro', // default
  });

  final String redirectTo;

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  late List<TextEditingController> _codeControllers;
  late List<FocusNode> _focusNodes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeControllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in _codeControllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    // If user pasted a full code into one field, distribute it
    if (value.length > 1) {
      final chars = value.split('');
      for (var i = 0; i < chars.length; i++) {
        final pos = index + i;
        if (pos >= _codeControllers.length) break;
        _codeControllers[pos].text = chars[i];
      }
      final next = math.min(
        _codeControllers.length - 1,
        index + value.length - 1,
      );
      _focusNodes[next].requestFocus();
      return;
    }

    if (value.length == 1 && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String _getCode() => _codeControllers.map((c) => c.text).join();

  Future<void> _handleVerifyCode() async {
    final code = _getCode();
    if (code.length != 6) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.enterAllDigits)));
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('📤 VerifyCode: Starting OTP verification...');
    debugPrint('🔐 VerifyCode: Code = $code');

    try {
      // ── Read which method was used ───────────────
      final otpType = ref.read(otpTypeProvider);
      debugPrint('📋 VerifyCode: Type = $otpType');

      bool success = false;

      if (otpType == 'email') {
        // ── Verify Email OTP ─────────────────────
        final email = _resolvedEmail;
        debugPrint('📧 VerifyCode: Email = $email');

        success = await ref
            .read(authProvider.notifier)
            .verifyEmailOtp(email: email, otp: code);
        debugPrint('📬 VerifyCode: verifyEmailOtp result = $success');
      } else {
        // ── Verify Phone OTP ─────────────────────
        final phone = _resolvedPhone;
        debugPrint('📱 VerifyCode: Phone = $phone');

        success = await ref
            .read(authProvider.notifier)
            .verifyPhoneOtp(phoneNumber: phone, otp: code);
        debugPrint('📬 VerifyCode: verifyPhoneOtp result = $success');
      }

      if (!mounted) return;

      if (success) {
        debugPrint('✅ VerifyCode: Going to ${widget.redirectTo}');
        context.go(widget.redirectTo);
      } else {
        final error = ref.read(authProvider).error;
        debugPrint('❌ VerifyCode: Failed - $error');
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? loc.verificationFailed)),
        );
      }
    } catch (e) {
      debugPrint('💥 VerifyCode: Exception - $e');
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.error(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    final otpType = ref.read(otpTypeProvider);
    debugPrint('🔄 VerifyCode: Resending OTP via $otpType');

    try {
      if (otpType == 'email') {
        final email = _resolvedEmail;
        await ref.read(authProvider.notifier).sendEmailOtp(email: email);
        debugPrint('✅ VerifyCode: Email OTP resent');
      } else {
        final phone = _resolvedPhone;
        await ref.read(authProvider.notifier).sendPhoneOtp(phoneNumber: phone);
        debugPrint('✅ VerifyCode: Phone OTP resent');
      }

      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.codeResent),
            backgroundColor: AppColors.primaryMid,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ VerifyCode: Resend failed - $e');
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.resendFailed(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final otpType =
        ref.watch(otpTypeProvider).isNotEmpty
            ? ref.watch(otpTypeProvider)
            : (authState.pendingOtpType ?? 'email');
    final email =
        ref.watch(otpEmailProvider).isNotEmpty
            ? ref.watch(otpEmailProvider)
            : (authState.pendingOtpEmail ?? '');
    final phone =
        ref.watch(otpPhoneProvider).isNotEmpty
            ? ref.watch(otpPhoneProvider)
            : (authState.pendingOtpPhone ?? '');
    final loc = AppLocalizations.of(context);

    // Responsive sizing for code input fields
    final screenWidth = MediaQuery.of(context).size.width;
    final fieldWidth = math.min(70.0, (screenWidth - 48 - 60) / 6);
    const fieldHeight = 70.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SizedBox.expand(
        child: Container(
          color: const Color(0xFFFAFAFA),
          margin: const EdgeInsets.only(top: 50, left: 24.0, right: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.go('/signup'),
                icon: const Icon(Icons.arrow_back_ios_new_outlined),
              ),
              const SizedBox(height: 32),
              Text(
                loc.verifyCode,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // ── Show where code was sent ───────────
              Text(
                otpType == 'email'
                    ? loc.enterCodeEmail(email)
                    : loc.enterCodePhone(phone),
                textAlign: TextAlign.left,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 48),

              // ── Code Input Fields ──────────────────
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: math.max(40.0, fieldWidth),
                      height: fieldHeight,
                      child: TextField(
                        controller: _codeControllers[index],
                        focusNode: _focusNodes[index],
                        onChanged: (value) => _onCodeChanged(value, index),
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        maxLength: 1,
                        autofocus: index == 0,
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFF2F2F2),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFF2F2F2),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryMid,
                              width: 2.0,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF2F2F2),
                        ),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 48),

              // ── Resend Code ────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _handleResend,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: loc.didntReceiveCode,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(
                          text: loc.resend,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              GaspButton(
                label: _isLoading ? loc.verifying : loc.verifyCode,
                buttonColor: AppColors.primaryMid,
                onPressed: _isLoading ? null : _handleVerifyCode,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String get _resolvedEmail {
    final email = ref.read(otpEmailProvider);
    if (email.isNotEmpty) return email;
    return ref.read(authProvider).pendingOtpEmail ?? '';
  }

  String get _resolvedPhone {
    final phone = ref.read(otpPhoneProvider);
    if (phone.isNotEmpty) return phone;
    return ref.read(authProvider).pendingOtpPhone ?? '';
  }
}
