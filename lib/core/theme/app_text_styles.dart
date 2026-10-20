import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  /// Latin text uses Inter; these cover Sinhala and Tamil glyphs on each platform.
  static const List<String> fontFallback = [
    'Noto Sans Sinhala',
    'Noto Sans Tamil',
    'Iskoola Pota',
    'Nirmala UI',
    'Latha',
  ];

  static const List<FontFeature> tabularFeatures = [
    FontFeature.tabularFigures(),
  ];

  // Ready-inspired Typography roles
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    color: AppColors.lTextPrimary,
    fontFeatures: tabularFeatures,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.lTextPrimary,
    letterSpacing: -0.5,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle titleLarge = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.lTextPrimary,
    letterSpacing: -0.3,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle titleMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.lTextPrimary,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.lTextPrimary,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.lTextSecondary,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.lTextPrimary,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.lTextSecondary,
  ).copyWith(fontFamilyFallback: fontFallback);

  // Backward-compatible aliases for existing screens
  static TextStyle display1 = displayLarge;
  static TextStyle display2 = headlineMedium;
  static TextStyle h1 = headlineMedium;
  static TextStyle h2 = titleLarge;
  static TextStyle h3 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.lTextPrimary,
    height: 1.35,
  ).copyWith(fontFamilyFallback: fontFallback);
  static TextStyle h4 = titleMedium;

  static TextStyle body1 = bodyLarge;
  static TextStyle body1Medium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.lTextPrimary,
    height: 1.4,
  ).copyWith(fontFamilyFallback: fontFallback);
  static TextStyle body1SemiBold = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.lTextPrimary,
    height: 1.4,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle body2 = bodyMedium;
  static TextStyle body2Medium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.lTextSecondary,
    height: 1.4,
  ).copyWith(fontFamilyFallback: fontFallback);
  static TextStyle body2SemiBold = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.lTextPrimary,
    height: 1.4,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle caption = labelSmall;
  static TextStyle captionMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.lTextSecondary,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle overline = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.lTextTertiary,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle buttonSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ).copyWith(fontFamilyFallback: fontFallback);
}
