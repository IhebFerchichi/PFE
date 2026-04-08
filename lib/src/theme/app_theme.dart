import 'package:flutter/material.dart';

class AppColors {
  static const Color ink = Color(0xFF18324E);
  static const Color ocean = Color(0xFF4663B0);
  static const Color oceanDeep = Color(0xFF2E4C9A);
  static const Color sky = Color(0xFFC9D6F6);
  static const Color coral = Color(0xFFE52B2B);
  static const Color sand = Color(0xFFFFF2F2);
  static const Color mist = Color(0xFFF4F7FE);
  static const Color line = Color(0xFFD8E0F4);
  static const Color success = Color(0xFF1F8C5C);
  static const Color warning = Color(0xFFC87412);
  static const Color danger = Color(0xFFC44747);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.ocean,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.ocean,
      secondary: AppColors.coral,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.mist,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: AppColors.ink,
        height: 1.4,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: AppColors.ink.withOpacity(0.82),
        height: 1.4,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withOpacity(0.92),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.ocean, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.sky.withOpacity(0.85),
      labelTextStyle: MaterialStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(MaterialState.selected)
              ? AppColors.ocean
              : AppColors.ink.withOpacity(0.65),
          fontWeight: states.contains(MaterialState.selected)
              ? FontWeight.w700
              : FontWeight.w600,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: const BorderSide(color: AppColors.line),
      selectedColor: AppColors.ocean,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}
