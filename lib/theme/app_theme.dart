import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// CloudRead "Cinematic Crimson" palette — deep neutral black with a vivid
/// crimson accent and a coral support tone, inspired by premium streaming
/// platforms adapted to a digital library.
class AppColors {
  AppColors._();

  // Backgrounds (deep, neutral blacks for a cinematic feel).
  static const background = Color(0xFF0B0B0D);
  static const surface = Color(0xFF16151A);
  static const surfaceHigh = Color(0xFF201E26);
  static const surfaceHigher = Color(0xFF2B2833);

  // Accent (crimson) — the brand signature — with a coral support tone.
  static const accent = Color(0xFFFF3B5C);
  static const accentSoft = Color(0xFFFF8A5C);
  static const onAccent = Color(0xFFFFFFFF);

  // Text.
  static const textPrimary = Color(0xFFF5F3F4);
  static const textSecondary = Color(0xFFBDB8C0);
  static const textMuted = Color(0xFF837E8C);

  // Semantic.
  static const favorite = Color(0xFFFF3B5C);
  static const error = Color(0xFFFF6B6B);

  // Outlines.
  static const outline = Color(0xFF2E2B36);
  static const outlineSoft = Color(0xFF231F2A);

  /// Signature gradient for primary CTAs and accent highlights.
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentSoft],
  );

  /// Scrim used behind hero text and over cover backdrops.
  static const heroScrim = [
    Color(0x000B0B0D),
    Color(0x990B0B0D),
    Color(0xFF0B0B0D),
  ];

  /// Soft accent glow for hovered/active elements.
  static List<BoxShadow> accentGlow({double alpha = 0.35, double blur = 22}) => [
        BoxShadow(
          color: accent.withValues(alpha: alpha),
          blurRadius: blur,
          spreadRadius: 1,
        ),
      ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      primaryContainer: AppColors.surfaceHigher,
      onPrimaryContainer: AppColors.accentSoft,
      secondary: AppColors.accentSoft,
      onSecondary: AppColors.onAccent,
      secondaryContainer: AppColors.surfaceHigh,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary: AppColors.accentSoft,
      onTertiary: AppColors.onAccent,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerLowest: AppColors.background,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surfaceHigh,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHigher,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineSoft,
    );

    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);

    final bodyText = GoogleFonts.interTextTheme(base.textTheme);
    final displayText = GoogleFonts.playfairDisplayTextTheme(base.textTheme);

    final textTheme = bodyText.copyWith(
      displayLarge: displayText.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium: displayText.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall: displayText.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: displayText.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: displayText.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: displayText.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    ).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: textTheme,
      splashColor: AppColors.accent.withValues(alpha: 0.10),
      highlightColor: AppColors.accent.withValues(alpha: 0.05),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        scrolledUnderElevation: 0,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceHigh,
        side: const BorderSide(color: AppColors.outline),
        labelStyle: textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accent.withValues(alpha: 0.18),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.accent : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.accent : AppColors.textMuted,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.textPrimary),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.outline, thickness: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.accent),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigher,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
