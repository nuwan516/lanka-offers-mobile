import 'package:flutter/material.dart';

import '../../../core/constants/banks.dart';
import '../../../core/theme/app_colors.dart';

/// Bank identification: a neutral monogram plus the bank's name.
///
/// Banks are never given invented brand colours; one tonal chip keeps every
/// card visually consistent and no unlicensed logo is shown.
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

  /// Short monogram for [bank] (a code or a name).
  static String bankInitials(String bank) {
    final known = CanonicalBanks.lookup(bank);
    if (known != null) return known.short;
    final clean = bank.trim();
    if (clean.isEmpty) return 'BK';
    final words = clean.split(RegExp(r'\s+'));
    if (words.length == 1) {
      return clean.length >= 3
          ? clean.substring(0, 3).toUpperCase()
          : clean.toUpperCase();
    }
    return words.take(3).map((w) => w[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = Localizations.maybeLocaleOf(context)?.languageCode;
    final name = CanonicalBanks.nameFor(bankName, lang);
    final fg = isDark ? AppColors.primaryLight : AppColors.primary;
    final chip = Container(
      constraints: const BoxConstraints(minWidth: 32),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        bankInitials(bankName),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: fg,
        ),
      ),
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: chip),
        if (!compact) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color:
                    isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );

    return Semantics(
      label: name,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
