// AgriMart Brand Colors — matches website primary #2d6a4f
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Green Palette
  static const Color primary = Color(0xFF2D6A4F);
  static const Color primaryLight = Color(0xFF4DAC7A);
  static const Color primaryDark = Color(0xFF1A4231);
  static const Color primarySurface = Color(0xFFF0FAF4);
  static const Color primaryBorder = Color(0xFFB7E1C9);

  // Accent / Highlight
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFBBF24);
  static const Color amberSurface = Color(0xFFFEF9C3);

  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color successSurface = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFEF9C3);
  static const Color error = Color(0xFFEF4444);
  static const Color errorSurface = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSurface = Color(0xFFDBEAFE);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF1F5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8FAF8);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Border
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFFD1D5DB);

  // Category Colors
  static const Color seeds = Color(0xFF10B981);
  static const Color fertilizer = Color(0xFF3B82F6);
  static const Color pesticide = Color(0xFFEF4444);
  static const Color organic = Color(0xFF22C55E);
  static const Color equipment = Color(0xFF8B5CF6);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A4231), Color(0xFF2D6A4F), Color(0xFF4DAC7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF112B1F), Color(0xFF2D6A4F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFFE5E7EB), Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
    stops: [0.0, 0.5, 1.0],
  );

  // ── Premium Shadow System ──────────────────────────────────
  static List<BoxShadow> softShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 4, offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> deepShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 10)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> primaryShadow = [
    BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
  ];

  // ── Glassmorphism Colors ────────────────────────────────────
  static const Color glassSurface = Color(0x99FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassPrimary = Color(0x1A2D6A4F);
}
