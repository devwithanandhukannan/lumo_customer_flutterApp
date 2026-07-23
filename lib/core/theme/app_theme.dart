import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF080B11);
  static const Color surface = Color(0xFF0E1420);
  static const Color cardBg = Color(0xFF141B2D);
  static const Color inputFill = Color(0xFF0E1420);

  static const Color border = Color(0x1AFFFFFF);
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryLight = Color(0xFF93C5FD);
  static const Color secondary = Color(0xFF6366F1);
  static const Color emergencyRed = Color(0xFFEF4444);
  static const Color emergencyRedSoft = Color(0x1AEF4444);
  static const Color emergencyRedBorder = Color(0x40EF4444);
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenSoft = Color(0x1F10B981);
  static const Color warningAmber = Color(0xFFF59E0B);

  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF7C8DB0);
  static const Color textDisabled = Color(0xFF4A5568);
  static const Color blueSoft = Color(0x1A3B82F6);
}

class AppText {
  static const TextStyle heading1 = TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
  static const TextStyle heading2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const TextStyle heading3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const TextStyle body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const TextStyle caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted);
  static const TextStyle mono = TextStyle(fontSize: 13, fontFamily: 'monospace', color: AppColors.textPrimary);
  static const TextStyle label = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8);
}

InputDecoration lumoInputDecoration({String? hint, Widget? prefix, Widget? suffix, String? label}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textDisabled),
    labelText: label,
    labelStyle: AppText.caption,
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.inputFill,
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.emergencyRed)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.emergencyRed, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.emergencyRed,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        iconTheme: IconThemeData(color: AppColors.textMuted),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border, width: 1)),
      ),
    );
  }
}
