import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

/// Clean, branded bank badge widget matching Lanka Offers design system.
/// Displays bank initials in a colored container alongside the bank name.
class BankBadge extends StatelessWidget {
  final String bankName;
  final bool compact;
  final VoidCallback? onTap;

  const BankBadge({
    super.key,
    required this.bankName,
    this.compact = false,
    this.onTap,
  });

  static Color bankBrandColor(String bank) {
    final b = bank.toLowerCase();
    if (b.contains('sampath')) return const Color(0xFFE65100); // Orange
    if (b.contains('hnb') || b.contains('hatton')) return const Color(0xFF0D47A1); // Deep Blue
    if (b.contains('commercial') || b.contains('combank')) return const Color(0xFF01579B); // Blue
    if (b.contains('boc') || b.contains('ceylon')) return const Color(0xFFB78103); // Gold
    if (b.contains('seylan')) return const Color(0xFFC62828); // Crimson Red
    if (b.contains('people')) return const Color(0xFF4A148C); // Maroon/Purple
    if (b.contains('dfcc')) return const Color(0xFFB71C1C); // Red
    if (b.contains('ndb')) return const Color(0xFF004D40); // Dark Teal
    if (b.contains('nsb')) return const Color(0xFF0277BD); // Light Navy
    if (b.contains('hsbc')) return const Color(0xFFD50000); // Red
    if (b.contains('standard') || b.contains('scb')) return const Color(0xFF0091EA); // Cyan Blue
    if (b.contains('amex') || b.contains('american')) return const Color(0xFF1A237E); // Indigo
    return const Color(0xFF455A64); // Slate fallback
  }

  static String bankInitials(String bank) {
    final clean = bank.trim();
    if (clean.isEmpty) return 'BK';
    final words = clean.split(RegExp(r'\s+'));
    if (words.length == 1) {
      return clean.length >= 3 ? clean.substring(0, 3).toUpperCase() : clean.toUpperCase();
    }
    return words.take(3).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor = bankBrandColor(bankName);
    final initials = bankInitials(bankName);

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: isDark ? brandColor.withValues(alpha: 0.18) : brandColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? brandColor.withValues(alpha: 0.35) : brandColor.withValues(alpha: 0.22),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: brandColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              bankName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionMedium.copyWith(
                color: isDark ? Colors.white.withValues(alpha: 0.9) : brandColor,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: badge,
      );
    }
    return badge;
  }
}
