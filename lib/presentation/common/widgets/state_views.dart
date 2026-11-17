import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_palette.dart';

/// Centred message for empty and failed states, with a 48dp action when set.
class StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.benefitBg,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Icon(icon, size: 32, color: palette.benefitFg),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: 8),
                Text(
                  hint!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.muted,
                    height: 1.4,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyOffersView extends StatelessWidget {
  final VoidCallback? onClear;
  final String? title;
  final String? hint;

  const EmptyOffersView({super.key, this.onClear, this.title, this.hint});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StateMessage(
      icon: Icons.search_off_rounded,
      title: title ?? l10n.text('emptyOffersTitle'),
      hint: hint ?? l10n.text('emptyOffersHint'),
      actionLabel: onClear == null ? null : l10n.text('clearFilters'),
      onAction: onClear,
    );
  }
}

class LoadFailedView extends StatelessWidget {
  final VoidCallback? onRetry;

  const LoadFailedView({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StateMessage(
      icon: Icons.cloud_off_rounded,
      title: l10n.text('errorLoadTitle'),
      hint: l10n.text('errorLoadHint'),
      actionLabel: onRetry == null ? null : l10n.retry,
      onAction: onRetry,
    );
  }
}
