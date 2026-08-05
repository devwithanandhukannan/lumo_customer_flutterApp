import 'dart:ui';
import 'package:flutter/material.dart';
import 'smooth_animations.dart';

class AppColors {
  // Premium Obsidian & Dark Glass Theme Foundation
  static const Color background = Color(0xFF0B0E17);
  static const Color surface = Color(0xFF131824);
  static const Color cardBg = Color(0xFF1A202C);
  static const Color inputFill = Color(0x14FFFFFF);

  static const Color border = Color(0x26FEF08A);
  static const Color glassBg = Color(0x1AFEF08A);
  static const Color glassBorder = Color(0x33EAB308);
  static const Color glassBorderBright = Color(0x66FEF08A);

  // Vibrant Gold-Yellow & Warm Accent Palette
  static const Color primary = Color(0xFFEAB308);        // Warm Sun Yellow / Gold
  static const Color primaryDark = Color(0xFFCA8A04);    // Deep Amber Gold
  static const Color primarySoft = Color(0x26EAB308);    // Soft Gold Glow
  static const Color primaryLight = Color(0xFFFEF08A);   // Cream Butter Yellow
  static const Color secondary = Color(0xFFF59E0B);      // Warm Amber Accent
  static const Color emergencyRed = Color(0xFFEF4444);
  static const Color emergencyRedSoft = Color(0x1AEF4444);
  static const Color emergencyRedBorder = Color(0x40EF4444);
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenSoft = Color(0x1F10B981);
  static const Color warningAmber = Color(0xFFF59E0B);

  // Text Colors tuned for Obsidian Aesthetics
  static const Color textPrimary = Color(0xFFFFFFFF);     // Pure White
  static const Color textSecondary = Color(0xFFF1F5F9);   // Off-White
  static const Color textMuted = Color(0xFF94A3B8);       // Slate Muted
  static const Color textDisabled = Color(0xFF475569);    // Dark Muted
  static const Color blueSoft = Color(0x26EAB308);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFEAB308), Color(0xFFCA8A04)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x24FEF08A), Color(0x0CFEF08A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppText {
  static const TextStyle heading1 = TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5);
  static const TextStyle heading2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3);
  static const TextStyle heading3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const TextStyle body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.4);
  static const TextStyle caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted, height: 1.3);
  static const TextStyle mono = TextStyle(fontSize: 13, fontFamily: 'monospace', color: AppColors.textPrimary);
  static const TextStyle label = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryLight, letterSpacing: 0.8);
  static const TextStyle buttonText = TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.8);
}

InputDecoration lumoInputDecoration({String? hint, Widget? prefix, Widget? suffix, String? label}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 14),
    labelText: label,
    labelStyle: AppText.caption,
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0x1AFFFFFF),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.glassBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.emergencyRed)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.emergencyRed, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  );
}

// ─── Glassmorphism GlassCard Widget ──────────────────────────────────────────
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blurRadius;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final List<Color>? gradientColors;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.blurRadius = 20,
    this.borderColor = AppColors.glassBorder,
    this.borderWidth = 1.0,
    this.borderRadius = 20,
    this.gradientColors,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors ?? [const Color(0x1CFEF08A), const Color(0x0AFEF08A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: child,
          ),
        ),
      ),
    );
    if (onTap != null) return AppBounceTap(onTap: onTap, child: content);
    return content;
  }
}

// ─── Glassmorphism Glass Chip ──────────────────────────────────────────
class AppGlassChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const AppGlassChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppBounceTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.textMuted),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gradient Button ──────────────────────────────────────────────────────────
class AppGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final List<Color> colors;
  final IconData? icon;

  const AppGradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.height = 54,
    this.colors = const [Color(0xFFEAB308), Color(0xFFCA8A04)],
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppBounceTap(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: isLoading ? [AppColors.surface, AppColors.surface] : colors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isLoading ? [] : [BoxShadow(color: colors.first.withAlpha(90), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Color(0xFF0F172A), strokeWidth: 2.5))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[Icon(icon, color: const Color(0xFF0F172A), size: 18), const SizedBox(width: 8)],
                    Text(label, style: AppText.buttonText),
                  ],
                ),
        ),
      ),
    );
  }
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
        onPrimary: Color(0xFF0F172A),
        onSurface: AppColors.textPrimary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: LumoPageTransitionsBuilder(),
          TargetPlatform.iOS: LumoPageTransitionsBuilder(),
          TargetPlatform.macOS: LumoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        iconTheme: IconThemeData(color: AppColors.primary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border, width: 1)),
      ),
    );
  }
}
