import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';

/// One selectable value in a [FilterGroup].
class FilterChoice {
  const FilterChoice({required this.value, required this.label});

  final String value;
  final String label;
}

/// A single-select group. A null selection means "any".
class FilterGroup {
  const FilterGroup({
    required this.id,
    required this.title,
    required this.choices,
    this.selected,
    this.anyLabel,
  });

  final String id;
  final String title;
  final List<FilterChoice> choices;
  final String? selected;

  /// Label for the chip that clears the group. Hidden when null.
  final String? anyLabel;
}

/// Bottom sheet for narrowing a list without leaving the screen.
///
/// Pops a map of group id to the chosen value (`null` means any) when the
/// person applies. Dismissing the sheet pops null and changes nothing.
class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key, required this.title, required this.groups});

  final String title;
  final List<FilterGroup> groups;

  static Future<Map<String, String?>?> show(
    BuildContext context, {
    required String title,
    required List<FilterGroup> groups,
  }) {
    return showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterSheet(title: title, groups: groups),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late Map<String, String?> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {for (final group in widget.groups) group.id: group.selected};
  }

  void _choose(String id, String? value) {
    HapticFeedback.selectionClick();
    setState(() => _selected[id] = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 12 + bottom),
        child: Column(
          key: const Key('filter_sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l10n.text('filterSheetHint'),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in widget.groups) ...[
                      Semantics(
                        header: true,
                        child: Text(
                          group.title,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (group.anyLabel != null)
                            ChoiceChip(
                              label: Text(group.anyLabel!),
                              selected: _selected[group.id] == null,
                              onSelected: (_) => _choose(group.id, null),
                            ),
                          for (final choice in group.choices)
                            ChoiceChip(
                              label: Text(choice.label),
                              selected: _selected[group.id] == choice.value,
                              onSelected:
                                  (_) => _choose(
                                    group.id,
                                    _selected[group.id] == choice.value
                                        ? null
                                        : choice.value,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('filter_reset'),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        for (final id in _selected.keys) {
                          _selected[id] = null;
                        }
                      });
                    },
                    child: Text(l10n.reset),
                  ),
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: FilledButton(
                    key: const Key('filter_apply'),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(
                        context,
                        Map<String, String?>.from(_selected),
                      );
                    },
                    child: Text(l10n.apply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
