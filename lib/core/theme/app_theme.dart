import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme => light();
  static ThemeData get darkTheme => dark();

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    bg: AppColors.dBackground,
    surface: AppColors.dSurface,
    surfaceHigh: AppColors.dSurfaceHigh,
    border: AppColors.dBorder,
    text: AppColors.dTextPrimary,
    textSecondary: AppColors.dTextSecondary,
  );

  static ThemeData light() => _build(
    brightness: Brightness.light,
    bg: AppColors.lBackground,
    surface: AppColors.lSurface,
    surfaceHigh: AppColors.lSurfaceHigh,
    border: AppColors.lBorder,
    text: AppColors.lTextPrimary,
    textSecondary: AppColors.lTextSecondary,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color surfaceHigh,
    required Color border,
    required Color text,
    required Color textSecondary,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: brightness == Brightness.dark ? AppColors.brandTealLight : AppColors.brandTeal,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      error: AppColors.negative,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: surfaceHigh,
      outline: border,
    );

    final base =
        brightness == Brightness.dark
            ? ThemeData.dark(useMaterial3: true)
            : ThemeData.light(useMaterial3: true);

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: text,
        fontFeatures: AppTextStyles.tabularFeatures,
      ).copyWith(fontFamilyFallback: AppTextStyles.fontFallback),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: text,
      ).copyWith(fontFamilyFallback: AppTextStyles.fontFallback),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: text,
      ).copyWith(fontFamilyFallback: AppTextStyles.fontFallback),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: text,
      ).copyWith(fontFamilyFallback: AppTextStyles.fontFallback),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: text,
      ).copyWith(fontFamilyFallback: AppTextStyles.fontFallback),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: text,
      ).copyWith(fontFamilyFallback: AppTextStyles.fontFallback),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        color: text,
      ).copyWith(fontFamilyFallback: AppTextStyles.fontFallback),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.5,
        color: textSecondary,
      ).copyWith(fontFamilyFallback: AppTextStyles.fontFallback),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 1.45,
        color: textSecondary,
      ).copyWith(fontFamilyFallback: AppTextStyles.fontFallback),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: text,
      ).copyWith(fontFamilyFallback: AppTextStyles.fontFallback),
      labelSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: textSecondary,
      ).copyWith(fontFamilyFallback: AppTextStyles.fontFallback),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          textStyle: textTheme.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: AppColors.negative),
        ),
        hintStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight:
                states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
            color:
                states.contains(WidgetState.selected)
                    ? AppColors.accent
                    : textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color:
                states.contains(WidgetState.selected)
                    ? AppColors.accent
                    : textSecondary,
            size: 24,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceHigh,
        selectedColor: AppColors.accent.withValues(alpha: 0.15),
        checkmarkColor: AppColors.accent,
        side: BorderSide(color: border, width: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceHigh,
        contentTextStyle: textTheme.bodyLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
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
}
