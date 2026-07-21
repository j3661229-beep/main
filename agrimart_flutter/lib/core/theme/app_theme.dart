import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Typography ────────────────────────────────────────────
  static TextTheme _buildTextTheme() {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      // Display — Space Grotesk
      displayLarge:  GoogleFonts.spaceGrotesk(fontSize: 57, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -1.5),
      displayMedium: GoogleFonts.spaceGrotesk(fontSize: 45, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.5),
      displaySmall:  GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w600, color: AppColors.ink),
      // Headline — Space Grotesk
      headlineLarge:  GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.3),
      headlineSmall:  GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.ink),
      // Title — Space Grotesk
      titleLarge:  GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: -0.2),
      titleMedium: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
      titleSmall:  GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
      // Body — Inter
      bodyLarge:   GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.ink),
      bodyMedium:  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.ink),
      bodySmall:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.muted),
      // Label — Inter
      labelLarge:  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted),
      labelSmall:  GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted),
    );
  }

  static ThemeData get light {
    final tt = _buildTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.farmerAccent,
        brightness: Brightness.light,
        primary:    AppColors.farmerAccent,
        onPrimary:  Colors.white,
        secondary:  AppColors.dealerAccent,
        tertiary:   AppColors.supplierAccent,
        surface:    AppColors.surface,
        error:      AppColors.danger,
      ).copyWith(
        surfaceContainerHighest: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: tt,
      primaryTextTheme: tt,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        titleTextStyle: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
        iconTheme: const IconThemeData(color: AppColors.ink),
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.farmerAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.placeholder, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AppColors.muted, fontSize: 14),
        errorStyle: GoogleFonts.inter(color: AppColors.danger, fontSize: 12),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.farmerAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.muted,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.farmerAccent,
          side: const BorderSide(color: AppColors.farmerAccent, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.farmerAccent,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.farmerTint,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.farmerAccent,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
      ),

      // Divider
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.farmerAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Role-specific theme helpers ────────────────────────────
class RoleTheme {
  final Color accent;
  final Color tint;
  final LinearGradient gradient;
  final String role;

  const RoleTheme({
    required this.accent,
    required this.tint,
    required this.gradient,
    required this.role,
  });

  static const RoleTheme farmer = RoleTheme(
    accent: AppColors.farmerAccent,
    tint: AppColors.farmerTint,
    gradient: AppColors.farmerGradient,
    role: 'FARMER',
  );
  static const RoleTheme supplier = RoleTheme(
    accent: AppColors.supplierAccent,
    tint: AppColors.supplierTint,
    gradient: AppColors.supplierGradient,
    role: 'SUPPLIER',
  );
  static const RoleTheme dealer = RoleTheme(
    accent: AppColors.dealerAccent,
    tint: AppColors.dealerTint,
    gradient: AppColors.dealerGradient,
    role: 'DEALER',
  );

  static RoleTheme of(String role) {
    switch (role.toUpperCase()) {
      case 'SUPPLIER': return supplier;
      case 'DEALER':   return dealer;
      default:         return farmer;
    }
  }
}

// ── AppTextStyles — named text styles for legacy screens ──────────────────────
class AppTextStyles {
  AppTextStyles._();

  static final TextStyle headingXL = GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink,  letterSpacing: -0.5);
  static final TextStyle headingLG = GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink,  letterSpacing: -0.2);
  static final TextStyle headingMD = GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink);
  static final TextStyle headingSM = GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink);
  static final TextStyle headingXS = GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink);

  static final TextStyle bodyLG = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.ink);
  static final TextStyle bodyMD = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.ink);
  static final TextStyle bodySM = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.muted);
  static final TextStyle bodyXS = GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.muted);

  static final TextStyle labelLG = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink);
  static final TextStyle labelMD = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted);
  static final TextStyle labelSM = GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.muted);

  // Additional semantic styles
  static final TextStyle caption    = GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.muted);
  static final TextStyle priceSmall = GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink);
  static final TextStyle price      = GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.farmerAccent);
  static final TextStyle priceLG    = GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.farmerAccent);
}

