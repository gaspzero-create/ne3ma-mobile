import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary — Forest Green (Figma) ─────────────
  static const Color primary        = Color(0xFF1E4D35);
  static const Color primaryMid     = Color(0xFF7FA668);
  static const Color primaryLight   = Color(0xFFA8C89A);
  static const Color primarySurface = Color(0xFFD4E8C2);
  static const Color primaryPale    = Color(0xFFEFF6E8);

  // ── Accent — Peach / Salmon (Figma) ────────────
  static const Color accent         = Color(0xFFF0A898);
  static const Color accentLight    = Color(0xFFF7CFC9);
  static const Color accentSurface  = Color(0xFFFDEFEC);

  // ── Secondary — Soft Purple (Figma) ────────────
  static const Color secondary      = Color(0xFF9B7FA6);
  static const Color secondaryLight = Color(0xFFC4A8D0);
  static const Color secondarySurface = Color(0xFFF0E8F5);

  // ── Neutrals ────────────────────────────────────
  static const Color background     = Color(0xFFF8F8F8);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2F2F2);
  static const Color textPrimary    = Color(0xFF1A1A1A);
  static const Color textSecondary  = Color(0xFF6B7280);
  static const Color textHint       = Color(0xFFB0B7BF);
  static const Color border         = Color(0xFFE8E8E8);
  static const Color divider        = Color(0xFFF0F0F0);

  // ── Status ──────────────────────────────────────
  static const Color success        = Color(0xFF7FA668);
  static const Color warning        = Color(0xFFF5C842);
  static const Color error          = Color(0xFFE05252);
  static const Color errorSurface   = Color(0xFFFEE8E8);

  // ── Map Markers ─────────────────────────────────
  static const Color markerFresh    = Color(0xFF7FA668);
  static const Color markerDry      = Color(0xFFF0A898);
  static const Color markerUrgent   = Color(0xFFE05252);

  // ── Gradients ───────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E4D35), Color(0xFF7FA668)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E4D35), Color(0xFF2D6A4F), Color(0xFF7FA668)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0A898), Color(0xFFF7CFC9)],
  );
}
