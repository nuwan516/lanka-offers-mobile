import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/banks.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/skeletons.dart';
import '../../../common/widgets/offer_card.dart';
import '../../../common/widgets/state_views.dart';
import '../cubit/browse_cubit.dart';

const int _pageSize = 20;

class BrowseView extends StatefulWidget {
  const BrowseView({super.key});

  @override
  State<BrowseView> createState() => _BrowseViewState();
}

class _BrowseViewState extends State<BrowseView> {
  int _visible = _pageSize;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<BrowseCubit>();

    return BlocConsumer<BrowseCubit, BrowseState>(
      listenWhen: (a, b) => a.filters != b.filters,
      listener: (_, __) => setState(() => _visible = _pageSize),
      builder: (context, state) {
        final filters = state.filters;

        return Column(
          children: [
            _ScopeChips(
              selected: filters.scope,
              onSelected:
                  (scope) => cubit.load(
                    filters.copyWith(scope: scope, clearScope: scope == null),
                  ),
            ),
            if (state.status == BrowseStatus.loaded &&
                state.categories.isNotEmpty)
              _CategoryChips(
                categories: state.categories,
                selected: filters.category,
                onSelected:
                    (c) => cubit.refine(category: c, clearCategory: c == null),
              ),
            if (filters.bankCode != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: InputChip(
                    label: Text(CanonicalBanks.nameFor(filters.bankCode)),
                    onDeleted:
                        () => cubit.load(filters.copyWith(clearBank: true)),
                  ),
                ),
              ),
            if (state.status == BrowseStatus.loaded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.format('offersCount', {
                          'count': state.offers.length,
                        }),
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    PopupMenuButton<BrowseSort>(
                      tooltip: l10n.sort,
                      icon: const Icon(Icons.sort),
                      initialValue: filters.sort,
                      onSelected: (s) => cubit.refine(sort: s),
                      itemBuilder:
                          (_) => [
                            for (final s in BrowseSort.values)
                              PopupMenuItem(
                                value: s,
                                child: Text(_sortLabel(l10n, s)),
                              ),
                          ],
                    ),
                  ],
                ),
              ),
            Expanded(child: _body(context, state, l10n, cubit)),
          ],
        );
      },
    );
  }

  String _sortLabel(AppLocalizations l10n, BrowseSort s) => switch (s) {
    BrowseSort.newest => l10n.text('sectionNewest'),
    BrowseSort.discount => l10n.text('sectionHighestDiscounts'),
    BrowseSort.endingSoon => l10n.text('sectionEndingSoon'),
  };

  Widget _body(
    BuildContext context,
    BrowseState state,
    AppLocalizations l10n,
    BrowseCubit cubit,
  ) {
    switch (state.status) {
      case BrowseStatus.loading:
        return const SkeletonBody();
      case BrowseStatus.failed:
        return LoadFailedView(onRetry: () => cubit.load(state.filters));
      case BrowseStatus.loaded:
        if (state.offers.isEmpty) {
          return EmptyOffersView(
            onClear:
                state.filters.isFiltered
                    ? () => cubit.load(const BrowseFilters())
                    : null,
          );
        }
        final shown = state.offers.take(_visible).toList();
        return RefreshIndicator(
          onRefresh: () => cubit.load(state.filters),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount:
                shown.length + (shown.length < state.offers.length ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == shown.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: OutlinedButton(
                    onPressed: () => setState(() => _visible += _pageSize),
                    child: Text(l10n.text('showMore')),
                  ),
                );
              }
              return OfferCard(
                offer: shown[i],
                contextOffers: state.offers,
                initialIndex: i,
              );
            },
          ),
        );
    }
  }
}

class _ScopeChips extends StatelessWidget {
  const _ScopeChips({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = <(String?, String)>[
      (null, l10n.text('scopeAll')),
      ('ONLINE', l10n.text('scopeOnline')),
      ('NATIONWIDE', l10n.text('scopeNationwide')),
    ];
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          for (final (value, label) in options)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selected == value,
                onSelected: (_) => onSelected(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          for (final c in categories)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: FilterChip(
                label: Text(c),
                selected: selected == c,
                onSelected: (on) => onSelected(on ? c : null),
              ),
            ),
        ],
      ),
    );
  }
}
