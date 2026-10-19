import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  /// Latin text uses Inter; these cover Sinhala and Tamil glyphs on each platform.
  static const List<String> fontFallback = [
    'Noto Sans Sinhala',
    'Noto Sans Tamil',
    'Iskoola Pota',
    'Nirmala UI',
    'Latha',
  ];

  // Display
  static TextStyle display1 = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle display2 = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.25,
  ).copyWith(fontFamilyFallback: fontFallback);

  // Headings
  static TextStyle h1 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle h2 = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle h3 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle h4 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  ).copyWith(fontFamilyFallback: fontFallback);

  // Body
  static TextStyle body1 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle body2 = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle body1Medium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle body2Medium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  ).copyWith(fontFamilyFallback: fontFallback);

  // Caption & Small
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle captionMedium = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    height: 1.6,
    letterSpacing: 0.5,
  ).copyWith(fontFamilyFallback: fontFallback);

  // Button
  static TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.25,
    letterSpacing: 0.2,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle buttonSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.25,
    letterSpacing: 0.2,
  ).copyWith(fontFamilyFallback: fontFallback);

  // Price/Discount
  static TextStyle price = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.2,
  ).copyWith(fontFamilyFallback: fontFallback);

  static TextStyle discount = GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    height: 1.2,
  ).copyWith(fontFamilyFallback: fontFallback);
}
