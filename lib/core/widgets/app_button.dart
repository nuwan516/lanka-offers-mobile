import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

enum AppButtonKind { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = AppButtonKind.primary,
    this.loading = false,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final bool loading;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null && !loading;

    final (bg, fg) = switch (kind) {
      AppButtonKind.primary => (AppColors.accent, AppColors.onAccent),
      AppButtonKind.secondary => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurface,
      ),
      AppButtonKind.ghost => (Colors.transparent, AppColors.accent),
    };

    return Pressable(
      onTap: enabled ? onPressed : null,
      child: Opacity(
        opacity: onPressed == null ? 0.45 : 1.0,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(Radii.md),
            border:
                kind == AppButtonKind.secondary
                    ? Border.all(color: theme.colorScheme.outline, width: 0.8)
                    : null,
          ),
          child:
              loading
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: fg,
                    ),
                  )
                  : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: fg, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
