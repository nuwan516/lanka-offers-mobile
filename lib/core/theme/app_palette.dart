import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic colours that follow the active brightness.
///
/// Widgets read these instead of branching on light and dark at every call
/// site, so spacing, type and colour stay on the same tokens.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.card,
    required this.border,
    required this.muted,
    required this.faint,
    required this.benefitBg,
    required this.benefitFg,
    required this.positive,
    required this.negative,
    required this.warning,
    required this.shadow,
    required this.heroStart,
    required this.heroEnd,
  });

  final Color card;
  final Color border;
  final Color muted;
  final Color faint;
  final Color benefitBg;
  final Color benefitFg;
  final Color positive;
  final Color negative;
  final Color warning;
  final Color shadow;
  final Color heroStart;
  final Color heroEnd;

  static const light = AppPalette(
    card: AppColors.lSurface,
    border: AppColors.lBorder,
    muted: AppColors.lTextSecondary,
    faint: AppColors.lTextTertiary,
    benefitBg: AppColors.brandTealSoft,
    benefitFg: AppColors.brandTeal,
    positive: AppColors.positive,
    negative: AppColors.negative,
    warning: AppColors.warning,
    shadow: Color(0x140F1C1A),
    heroStart: AppColors.brandTeal,
    heroEnd: AppColors.brandTealDark,
  );

  static const dark = AppPalette(
    card: AppColors.dSurface,
    border: AppColors.dBorder,
    muted: AppColors.dTextSecondary,
    faint: AppColors.dTextTertiary,
    benefitBg: Color(0x332A8A85),
    benefitFg: Color(0xFFB7E6E2),
    positive: Color(0xFF7DCEA0),
    negative: Color(0xFFF0A0A0),
    warning: Color(0xFFF5C27A),
    shadow: Color(0x66000000),
    heroStart: Color(0xFF146E69),
    heroEnd: Color(0xFF0A3E3C),
  );

  @override
  AppPalette copyWith({
    Color? card,
    Color? border,
    Color? muted,
    Color? faint,
    Color? benefitBg,
    Color? benefitFg,
    Color? positive,
    Color? negative,
    Color? warning,
    Color? shadow,
    Color? heroStart,
    Color? heroEnd,
  }) => AppPalette(
    card: card ?? this.card,
    border: border ?? this.border,
    muted: muted ?? this.muted,
    faint: faint ?? this.faint,
    benefitBg: benefitBg ?? this.benefitBg,
    benefitFg: benefitFg ?? this.benefitFg,
    positive: positive ?? this.positive,
    negative: negative ?? this.negative,
    warning: warning ?? this.warning,
    shadow: shadow ?? this.shadow,
    heroStart: heroStart ?? this.heroStart,
    heroEnd: heroEnd ?? this.heroEnd,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      benefitBg: Color.lerp(benefitBg, other.benefitBg, t)!,
      benefitFg: Color.lerp(benefitFg, other.benefitFg, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
