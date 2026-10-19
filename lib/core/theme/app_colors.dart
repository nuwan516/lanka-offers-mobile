import 'package:flutter/material.dart';

class AppColors {
  // Brand: deep teal, shared with the Lanka Offers web app.
  static const Color primary = Color(0xFF0F5F5C);
  static const Color primaryVariant = Color(0xFF0A4644);
  static const Color primaryLight = Color(0xFF2A8A85);
  static const Color primarySoft = Color(0xFFE6F2F1);

  // Secondary is a restrained amber reserved for time-sensitive cues.
  static const Color secondary = Color(0xFFB45309);
  static const Color secondaryVariant = Color(0xFF92400E);
  static const Color secondaryLight = Color(0xFFD97706);
  static const Color secondarySoft = Color(0xFFFEF3E2);

  static const Color flashYellow = secondaryLight;
  static const Color hotRed = Color(0xFFB3261E);

  static const Color accent = secondary;
  static const Color accentLight = secondaryLight;

  // Neutrals (Light): warm grey, white cards.
  static const Color background = Color(0xFFFAFAF7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F2EE);
  static const Color border = Color(0xFFE4E3DD);
  static const Color borderSubtle = Color(0xFFEEEDE8);

  // Neutrals (Dark)
  static const Color darkBackground = Color(0xFF101516);
  static const Color darkSurface = Color(0xFF171D1E);
  static const Color darkSurfaceVariant = Color(0xFF1F2728);
  static const Color darkBorder = Color(0xFF2A3335);

  // Text (Light). textSecondary meets 4.5:1 on background and surface.
  static const Color textPrimary = Color(0xFF1A2224);
  static const Color textSecondary = Color(0xFF4F5B5E);
  static const Color textTertiary = Color(0xFF7A8588);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // Text (Dark)
  static const Color darkTextPrimary = Color(0xFFF1F3F2);
  static const Color darkTextSecondary = Color(0xFFA9B4B6);
  static const Color darkTextTertiary = Color(0xFF7F8B8E);

  // Status colours (never the only signal: always paired with text or icon).
  static const Color success = Color(0xFF2F7D57);
  static const Color warning = Color(0xFFB45309);
  static const Color error = Color(0xFFB3261E);
  static const Color info = Color(0xFF2563EB);

  // Urgency
  static const Color urgentRed = Color(0xFFB3261E);
  static const Color urgentOrange = Color(0xFFB45309);
  static const Color urgentYellow = Color(0xFFB45309);

  // Offer type colours
  static const Color bankOfferColor = primary;
  static const Color shopOfferColor = secondary;
  static const Color promotionColor = Color(0xFF9F1239);
  static const Color eventColor = primaryLight;

  // Flat fills, kept as gradients only so existing call sites keep compiling.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primary],
  );
  static const LinearGradient heroRedGradient = primaryGradient;
  static const LinearGradient yellowFlashGradient = LinearGradient(
    colors: [secondarySoft, secondarySoft],
  );
  static const LinearGradient redYellowBadgeGradient = primaryGradient;
  static const LinearGradient accentGradient = LinearGradient(
    colors: [secondary, secondary],
  );

  // Elevation: hairline borders carry structure; shadows stay faint.
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> redGlowShadow = const [];
  static List<BoxShadow> yellowGlowShadow = const [];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];
}
