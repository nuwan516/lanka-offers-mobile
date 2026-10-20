import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/motion.dart';

class BalanceHeader extends StatefulWidget {
  const BalanceHeader({
    super.key,
    required this.count,
    required this.label,
    this.deltaText,
    this.isPositive = true,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(vertical: Gap.sm),
  });

  final int count;
  final String label;
  final String? deltaText;
  final bool isPositive;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  State<BalanceHeader> createState() => _BalanceHeaderState();
}

class _BalanceHeaderState extends State<BalanceHeader> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.isPositive ? AppColors.positive : AppColors.negative;

    return Container(
      padding: widget.padding,
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
              const Spacer(),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
          const SizedBox(height: 6),
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
                  fontFeatures: const [FontFeature.tabularFigures()],
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
                  Flexible(
                    child: Text(
                      widget.deltaText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
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
