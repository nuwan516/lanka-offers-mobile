import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Sri Lankan flag inspired)
  static const Color primary = Color(0xFFE03C31); // Maroon red
  static const Color primaryVariant = Color(0xFFB8251A);
  static const Color primaryLight = Color(0xFFFF6F61);

  static const Color secondary = Color(0xFFFF9800); // Saffron orange
  static const Color secondaryVariant = Color(0xFFF57C00);
  static const Color secondaryLight = Color(0xFFFFB74D);

  static const Color accent = Color(0xFF00897B); // Teal green
  static const Color accentLight = Color(0xFF4DB6AC);

  // Neutrals (Light)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFEDF2F7);

  // Neutrals (Dark)
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B);    // Slate 800
  static const Color darkSurfaceVariant = Color(0xFF334155); // Slate 700
  static const Color darkBorder = Color(0xFF334155);

  // Text (Light)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Text (Dark)
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Urgency Indicators
  static const Color urgentRed = Color(0xFFDC2626);
  static const Color urgentOrange = Color(0xFFEA580C);
  static const Color urgentYellow = Color(0xFFFBBF24);

  // Offer Type Colors
  static const Color bankOfferColor = Color(0xFF6366F1); // Indigo
  static const Color shopOfferColor = Color(0xFFEC4899); // Pink
  static const Color promotionColor = Color(0xFF8B5CF6); // Purple
  static const Color eventColor = Color(0xFF14B8A6); // Teal

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [secondary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
