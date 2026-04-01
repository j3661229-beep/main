import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Inter';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, height: 1.2, letterSpacing: -0.5,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily, fontSize: 26, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, height: 1.25,
  );
  static const TextStyle headingXL = TextStyle(
    fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3,
  );
  static const TextStyle headingLG = TextStyle(
    fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.35,
  );
  static const TextStyle headingMD = TextStyle(
    fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle headingSM = TextStyle(
    fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyLG = TextStyle(
    fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.5,
  );
  static const TextStyle bodyMD = TextStyle(
    fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.5,
  );
  static const TextStyle bodySM = TextStyle(
    fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.4,
  );
  static const TextStyle bodyXS = TextStyle(
    fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );
  static const TextStyle labelLG = TextStyle(
    fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: 0.1,
  );
  static const TextStyle labelMD = TextStyle(
    fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary, letterSpacing: 0.2,
  );
  static const TextStyle price = TextStyle(
    fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );
  static const TextStyle priceSmall = TextStyle(
    fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textTertiary, letterSpacing: 0.2,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: AppTextStyles.fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.amber,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.white,
        letterSpacing: -0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: AppTextStyles.button,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.button,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      hintStyle: AppTextStyles.bodyMD.copyWith(color: AppColors.textTertiary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontFamily: AppTextStyles.fontFamily, fontSize: 11),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primarySurface,
      selectedColor: AppColors.primary,
      labelStyle: AppTextStyles.labelMD.copyWith(color: AppColors.primary),
      side: const BorderSide(color: AppColors.primaryBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: AppTextStyles.bodyMD.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
