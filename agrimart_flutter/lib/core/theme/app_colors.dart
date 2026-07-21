import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Role Accents ────────────────────────────────────────
  static const Color farmerAccent = Color(0xFF3D6B35);
  static const Color farmerTint   = Color(0xFFE7F0E2);
  static const Color supplierAccent = Color(0xFF1D4E63);
  static const Color supplierTint   = Color(0xFFE3EDF1);
  static const Color dealerAccent = Color(0xFFA85C1A);
  static const Color dealerTint   = Color(0xFFF5E9DA);

  // ── Backgrounds ─────────────────────────────────────────
  static const Color background   = Color(0xFFF6F1E4);  // cream
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color surfaceCard  = Color(0xFFFAF8F2);

  // ── Text ────────────────────────────────────────────────
  static const Color ink          = Color(0xFF1E2A1A);
  static const Color muted        = Color(0xFF6B7568);
  static const Color placeholder  = Color(0xFFB0AFA8);

  // ── Semantic ────────────────────────────────────────────
  static const Color danger       = Color(0xFFB3402F);
  static const Color dangerTint   = Color(0xFFFDECE9);
  static const Color success      = Color(0xFF2F7D4F);
  static const Color successTint  = Color(0xFFE3F5EA);
  static const Color warning      = Color(0xFFD97706);
  static const Color warningTint  = Color(0xFFFEF3C7);
  static const Color info         = Color(0xFF1D4E63);
  static const Color infoTint     = Color(0xFFE3EDF1);

  // ── Border ──────────────────────────────────────────────
  static const Color border       = Color(0xFFE2DDD2);
  static const Color borderFocus  = Color(0xFF3D6B35);

  // ── Legacy aliases (keep for existing code) ──────────────
  static const Color primary      = farmerAccent;
  static const Color primaryLight = Color(0xFF4DAC7A);
  static const Color primaryDark  = Color(0xFF2A4C25);
  static const Color primarySurface = farmerTint;
  static const Color primaryBorder  = Color(0xFFB7D9AE);
  static const Color white        = Color(0xFFFFFFFF);
  static const Color textPrimary  = ink;
  static const Color textSecondary = muted;
  static const Color textTertiary  = placeholder;
  static const Color textInverse   = Color(0xFFFFFFFF);
  static const Color error         = danger;
  static const Color errorSurface  = dangerTint;
  static const Color successSurface = successTint;

  // ── Extra legacy aliases (unused v1 screens still reference these) ──
  static const Color amber          = warning;
  static const Color amberSurface   = warningTint;
  static const Color amberLight     = Color(0xFFFBBF24);
  static const Color surfaceVariant = surfaceCard;

  // ── Gradients ────────────────────────────────────────────
  static const LinearGradient farmerGradient = LinearGradient(
    colors: [Color(0xFF2A4C25), Color(0xFF3D6B35), Color(0xFF5A9247)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient supplierGradient = LinearGradient(
    colors: [Color(0xFF0F2E3D), Color(0xFF1D4E63), Color(0xFF2E6E87)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient dealerGradient = LinearGradient(
    colors: [Color(0xFF6B3A10), Color(0xFFA85C1A), Color(0xFFD4793A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient primaryGradient = farmerGradient;
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1A2E17), Color(0xFF3D6B35)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static LinearGradient shimmerGradient = const LinearGradient(
    colors: [Color(0xFFEDE8DA), Color(0xFFF6F1E4), Color(0xFFEDE8DA)],
    stops: [0.0, 0.5, 1.0],
  );

  // ── Shadows ──────────────────────────────────────────────
  static List<BoxShadow> softShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4,  offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> deepShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 24, offset: const Offset(0, 12)),
    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8,  offset: const Offset(0,  4)),
  ];
  static List<BoxShadow> primaryShadow = [
    BoxShadow(color: farmerAccent.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(0, 8)),
  ];

  // ── Glass ────────────────────────────────────────────────
  static const Color glassSurface = Color(0xCCFFFFFF);
  static const Color glassBorder  = Color(0x33FFFFFF);

  // ── Category Colors ──────────────────────────────────────
  static const Color seeds      = Color(0xFF3D6B35);
  static const Color fertilizer = Color(0xFF1D4E63);
  static const Color pesticide  = Color(0xFFB3402F);
  static const Color organic    = Color(0xFF2F7D4F);
  static const Color equipment  = Color(0xFFA85C1A);

  // ── Helpers ──────────────────────────────────────────────
  static Color accentFor(String role) {
    switch (role.toUpperCase()) {
      case 'SUPPLIER': return supplierAccent;
      case 'DEALER':   return dealerAccent;
      default:         return farmerAccent;
    }
  }
  static Color tintFor(String role) {
    switch (role.toUpperCase()) {
      case 'SUPPLIER': return supplierTint;
      case 'DEALER':   return dealerTint;
      default:         return farmerTint;
    }
  }
  static LinearGradient gradientFor(String role) {
    switch (role.toUpperCase()) {
      case 'SUPPLIER': return supplierGradient;
      case 'DEALER':   return dealerGradient;
      default:         return farmerGradient;
    }
  }
}

