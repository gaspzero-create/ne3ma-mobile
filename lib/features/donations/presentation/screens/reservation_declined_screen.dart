import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReservationDeclinedScreen extends StatelessWidget {
  const ReservationDeclinedScreen({super.key, required this.beneficiaryName});

  final String beneficiaryName;

  @override
  Widget build(BuildContext context) {
    final firstName = beneficiaryName.split(' ').first;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFDE8E8), // soft pink background
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── X Circle ──────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8B4B4).withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4A0A0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF4A2020),
                      size: 32,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Title ─────────────────────────────
              const Text(
                'Reservation Declined',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B1A1A),
                ),
              ),

              const SizedBox(height: 16),

              // ── Subtitle ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  '$firstName has been notified. Your\ndonation is now available again\nfor others to reserve.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF6B1A1A).withValues(alpha: 0.5),
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Back Button ───────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A0A0).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Center(
                      child: Text(
                        'Click to get back',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A2020),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 5),
            ],
          ),
        ),
      ),
    );
  }
}
