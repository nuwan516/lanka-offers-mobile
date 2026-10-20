import 'package:flutter/material.dart';

abstract final class AppColors {
  // Sri Lanka Bank Deals Brand Teal (Core Identity)
  static const Color brandTeal = Color(0xFF0F5F5C);
  static const Color brandTealLight = Color(0xFF2A8A85);
  static const Color brandTealSoft = Color(0xFFE6F2F1);
  static const Color brandTealDark = Color(0xFF0A4644);

  // Primary Action Accent (Restrained Deep Teal CTA)
  static const Color accent = brandTeal;
  static const Color accentPressed = brandTealDark;
  static const Color onAccent = Colors.white;

  // Dark theme neutrals (Calm dark mode)
  static const Color dBackground = Color(0xFF0C0C0F);
  static const Color dSurface = Color(0xFF16161B);
  static const Color dSurfaceHigh = Color(0xFF1F1F26);
  static const Color dBorder = Color(0xFF2B2B34);
  static const Color dTextPrimary = Color(0xFFEFF6F2);
  static const Color dTextSecondary = Color(0xFFAABAB1);
  static const Color dTextTertiary = Color(0xFF6F7C75);

  // Light theme neutrals (Warm-gray editorial)
  static const Color lBackground = Color(0xFFF7F6F4);
  static const Color lSurface = Color(0xFFFFFFFF);
  static const Color lSurfaceHigh = Color(0xFFF0EEEA);
  static const Color lBorder = Color(0xFFE4E1DB);
  static const Color lTextPrimary = Color(0xFF162521);
  static const Color lTextSecondary = Color(0xFF596963);
  static const Color lTextTertiary = Color(0xFF8C9893);

  // Semantic (Calm, source-truthful)
  static const Color positive = Color(0xFF1C7554);
  static const Color negative = Color(0xFFB93838);
  static const Color warning = Color(0xFF8A5D15);
  static const Color info = Color(0xFF2563EB);

  // Backward-compatible aliases for existing screens & tests
  static const Color primary = brandTeal;
  static const Color primaryVariant = brandTealDark;
  static const Color primaryLight = brandTealLight;
  static const Color primarySoft = brandTealSoft;

  static const Color secondary = Color(0xFFB45309);
  static const Color secondaryVariant = Color(0xFF92400E);
  static const Color secondaryLight = Color(0xFFFDE68A);
  static const Color secondarySoft = Color(0xFFFEF3C7);

  static const Color flashYellow = warning;
  static const Color hotRed = negative;
  static const Color accentLight = brandTealLight;

  static const Color background = lBackground;
  static const Color surface = lSurface;
  static const Color surfaceVariant = lSurfaceHigh;
  static const Color border = lBorder;
  static const Color borderSubtle = Color(0xFFEEEBE5);

  static const Color darkBackground = dBackground;
  static const Color darkSurface = dSurface;
  static const Color darkSurfaceVariant = dSurfaceHigh;
  static const Color darkBorder = dBorder;

  static const Color textPrimary = lTextPrimary;
  static const Color textSecondary = lTextSecondary;
  static const Color textTertiary = lTextTertiary;
  static const Color textOnPrimary = Colors.white;
  static const Color textOnSecondary = onAccent;

  static const Color darkTextPrimary = dTextPrimary;
  static const Color darkTextSecondary = dTextSecondary;
  static const Color darkTextTertiary = dTextTertiary;

  static const Color success = positive;
  static const Color error = negative;

  static const Color urgentRed = negative;
  static const Color urgentOrange = accent;
  static const Color urgentYellow = warning;

  static const Color bankOfferColor = brandTeal;
  static const Color shopOfferColor = accent;
  static const Color promotionColor = Color(0xFF9F1239);
  static const Color eventColor = brandTealLight;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [brandTeal, brandTeal],
  );
  static const LinearGradient heroRedGradient = primaryGradient;
  static const LinearGradient yellowFlashGradient = LinearGradient(
    colors: [secondarySoft, secondarySoft],
  );
  static const LinearGradient redYellowBadgeGradient = primaryGradient;
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentPressed],
  );

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> redGlowShadow = const [];
  static List<BoxShadow> yellowGlowShadow = const [];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
