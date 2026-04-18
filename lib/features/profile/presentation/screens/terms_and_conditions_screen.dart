import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Terms and Policies',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Terms and Conditions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: April 2026',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            SizedBox(height: 24),
            Text(
              '1. Acceptance of Terms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'By accessing and using NE3MA, you agree to comply with and be bound by these terms. If you disagree with any part of these terms, you may not use our service.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            Text(
              '2. User Responsibilities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Users are responsible for ensuring all food donations are safe, unexpired, and accurately described. Bad-faith reservations or repeated cancellations may result in account suspension.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            Text(
              '3. Platform Role',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'NE3MA acts purely as a facilitator connecting donors and beneficiaries. We are not liable for the quality of items donated or any disputes arising between users.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
