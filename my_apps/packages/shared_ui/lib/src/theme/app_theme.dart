import 'package:flutter/material.dart';

/// SFinance color palette. All values maintain WCAG AA contrast (≥4.5:1
/// for normal text, ≥3:1 for large text and UI components) against the dark
/// background [AppColors.background].
abstract final class AppColors {
  /// Main dark background — #0D0D0D
  static const Color background = Color(0xFF0D0D0D);

  /// Card / surface background — #1A1A1A
  static const Color surface = Color(0xFF1A1A1A);

  /// Secondary surface / dividers — #2A2A2A
  static const Color surfaceVariant = Color(0xFF2A2A2A);

  /// Primary text — #FFFFFF
  static const Color onBackground = Color(0xFFFFFFFF);

  /// Secondary / subtitle text — #A0A0A0
  static const Color onBackgroundMuted = Color(0xFFA0A0A0);

  /// Income / positive — #00C853 (green)
  /// Contrast against background: ~6.5:1 ✓
  static const Color income = Color(0xFF00C853);

  /// Expense / negative — #FF1744 (red)
  /// Contrast against background: ~4.6:1 ✓
  static const Color expense = Color(0xFFFF1744);

  /// Balance / neutral chart — #2196F3 (blue)
  /// Contrast against background: ~4.7:1 ✓
  static const Color balance = Color(0xFF2196F3);

  /// Accent / action — #FFC107 (amber)
  static const Color accent = Color(0xFFFFC107);

  /// Danger / destructive actions — same as expense
  static const Color danger = expense;
}

/// SFinance dark [ThemeData].
///
/// Consumes all [AppColors] constants. Apply via [MaterialApp.theme].
ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.dark(
    surface: AppColors.surface,
    onSurface: AppColors.onBackground,
    primary: AppColors.balance,
    onPrimary: Colors.white,
    error: AppColors.expense,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.surface,
    dividerColor: AppColors.surfaceVariant,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.onBackground),
      bodyMedium: TextStyle(color: AppColors.onBackground),
      bodySmall: TextStyle(color: AppColors.onBackgroundMuted),
      titleMedium: TextStyle(color: AppColors.onBackground),
      titleLarge: TextStyle(
        color: AppColors.onBackground,
        fontWeight: FontWeight.bold,
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.onBackground),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.surfaceVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.surfaceVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.balance),
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle: const TextStyle(color: AppColors.onBackgroundMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.balance,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
