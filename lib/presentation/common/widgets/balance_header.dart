import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/motion.dart';
import '../../../core/widgets/pressable.dart';

class BalanceHeader extends StatefulWidget {
  const BalanceHeader({
    super.key,
    required this.count,
    required this.label,
    this.deltaText,
    this.isPositive = true,
    this.trailing,
  });

  final int count;
  final String label;
  final String? deltaText;
  final bool isPositive;
  final Widget? trailing;

  @override
  State<BalanceHeader> createState() => _BalanceHeaderState();
}

class _BalanceHeaderState extends State<BalanceHeader> {
  bool _hidden = false;

  void _toggleHidden() {
    HapticFeedback.selectionClick();
    setState(() => _hidden = !_hidden);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.isPositive ? AppColors.positive : AppColors.negative;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.label,
                style: textTheme.bodyMedium?.copyWith(
                  color:
                      isDark
                          ? AppColors.dTextSecondary
                          : AppColors.lTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Pressable(
                onTap: _toggleHidden,
                child: Icon(
                  _hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                  color:
                      isDark
                          ? AppColors.dTextTertiary
                          : AppColors.lTextTertiary,
                ),
              ),
              const Spacer(),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
          const SizedBox(height: 6),
          if (_hidden)
            Text(
              '••••••',
              style: textTheme.displayLarge?.copyWith(
                letterSpacing: 4.0,
                color:
                    isDark ? AppColors.dTextPrimary : AppColors.lTextPrimary,
              ),
            )
          else
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: widget.count.toDouble()),
              duration: Motion.slow,
              curve: Motion.countUp,
              builder: (_, value, __) {
                return Text(
                  '${value.round()}',
                  style: textTheme.displayLarge?.copyWith(
                    color:
                        isDark ? AppColors.dTextPrimary : AppColors.lTextPrimary,
                  ),
                );
              },
            ),
          if (widget.deltaText != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isPositive
                        ? Icons.verified_rounded
                        : Icons.info_outline_rounded,
                    size: 13,
                    color: color,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.deltaText!,
                    style: textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
