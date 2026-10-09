import 'package:flutter/material.dart';

class AppColors {
  // Temu-Inspired High-Energy Deal Palette (Red & Yellow)
  static const Color primary = Color(0xFFE51D1D); // Vibrant Deal Red
  static const Color primaryVariant = Color(0xFFB81010); // Deep Crimson Red
  static const Color primaryLight = Color(0xFFFF4848); // Cherry Red
  static const Color primarySoft = Color(0xFFFFF0F0); // Very soft red tint

  static const Color secondary = Color(0xFFFFC700); // Electric Deal Gold / Yellow
  static const Color secondaryVariant = Color(0xFFFF9E00); // Deep Amber Gold
  static const Color secondaryLight = Color(0xFFFFE600); // High-Vis Yellow
  static const Color secondarySoft = Color(0xFFFFF9E5); // Very soft yellow tint

  static const Color flashYellow = Color(0xFFFFD600); // Flash Sale Yellow
  static const Color hotRed = Color(0xFFFF2A2A); // Hot Badge Red

  static const Color accent = Color(0xFFFFB800); // Warm Gold Accent
  static const Color accentLight = Color(0xFFFFE066);

  // Neutrals (Light)
  static const Color background = Color(0xFFF6F7F9); // Crisp Light Grey
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F6);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFF3F4F6);

  // Neutrals (Dark)
  static const Color darkBackground = Color(0xFF111215);
  static const Color darkSurface = Color(0xFF1A1B20);
  static const Color darkSurfaceVariant = Color(0xFF262830);
  static const Color darkBorder = Color(0xFF2C2E38);

  // Text (Light)
  static const Color textPrimary = Color(0xFF18191D); // Deep Charcoal
  static const Color textSecondary = Color(0xFF6B7280); // Neutral Grey
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF18191D);

  // Text (Dark)
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextTertiary = Color(0xFF6B7280);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Urgency Indicators
  static const Color urgentRed = Color(0xFFDC2626);
  static const Color urgentOrange = Color(0xFFEA580C);
  static const Color urgentYellow = Color(0xFFF59E0B);

  // Offer Type Colors
  static const Color bankOfferColor = Color(0xFFE51D1D); // Primary Red
  static const Color shopOfferColor = Color(0xFFFF9E00); // Amber
  static const Color promotionColor = Color(0xFFE11D48); // Rose
  static const Color eventColor = Color(0xFF0D9488); // Teal

  // Temu-Inspired Vibrant Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE51D1D), Color(0xFFB81010)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroRedGradient = LinearGradient(
    colors: [Color(0xFFE51D1D), Color(0xFFFF3838), Color(0xFFD41111)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient yellowFlashGradient = LinearGradient(
    colors: [Color(0xFFFFD600), Color(0xFFFFB300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redYellowBadgeGradient = LinearGradient(
    colors: [Color(0xFFE51D1D), Color(0xFFFF7043)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [secondary, Color(0xFFFF9E00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> redGlowShadow = [
    BoxShadow(
      color: const Color(0xFFE51D1D).withValues(alpha: 0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> yellowGlowShadow = [
    BoxShadow(
      color: const Color(0xFFFFC700).withValues(alpha: 0.35),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}

