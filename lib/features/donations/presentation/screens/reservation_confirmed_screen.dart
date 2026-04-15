import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ne3ma/core/constants/app_colors.dart';
import 'package:ne3ma/features/chat/presentation/screens/chat_screen.dart';

class ReservationConfirmedScreen extends StatelessWidget {
  const ReservationConfirmedScreen({
    super.key,
    required this.beneficiaryName,
    required this.reservationId,
    this.donationTitle,
  });

  final String beneficiaryName;
  final String reservationId;
  final String? donationTitle;

  @override
  Widget build(BuildContext context) {
    final firstName = beneficiaryName.split(' ').first;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D5A3F), Color(0xFF1E4D35), Color(0xFF1A4530)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── Checkmark Circle ──────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF7FA668).withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7FA668),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF1E4D35),
                      size: 36,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Title ─────────────────────────────
              const Text(
                'Reservation Confirmed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // ── Subtitle ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  '$beneficiaryName has been notified.\nShe\'ll arrive within 30 minutes at\nyour pickup point.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Points Badge ──────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Text(
                  '+10 pts earned',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Open Chat Button ──────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversationId: reservationId,
                          otherUserName: beneficiaryName,
                          donationTitle: donationTitle ?? 'Donation',
                          donationStatus: 'CONFIRMED',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Open chat with $firstName',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 4),

              // ── Back to Home Button ────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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
