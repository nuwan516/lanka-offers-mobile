import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/banks.dart';
import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../common/widgets/filter_sheet.dart';
import '../../common/widgets/offer_card.dart';
import '../../common/widgets/skeletons.dart';
import '../../common/widgets/state_views.dart';
import 'bloc/search_bloc.dart';
import 'bloc/search_event.dart';
import 'bloc/search_state.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String? _filterBank;
  String? _filterCategory;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _filterBank = null;
      _filterCategory = null;
    });
  }

  String _bankLabel(String code) => CanonicalBanks.nameFor(
    code,
    Localizations.localeOf(context).languageCode,
  );

  Future<void> _openFilters({
    required List<String> banks,
    required List<String> categories,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilterSheet.show(
      context,
      title: l10n.filter,
      groups: [
        if (banks.length > 1)
          FilterGroup(
            id: 'bank',
            title: l10n.text('sectionBanks'),
            anyLabel: l10n.text('filterAny'),
            selected: _filterBank,
            choices: [
              for (final bank in banks)
                FilterChoice(value: bank, label: _bankLabel(bank)),
            ],
          ),
        if (categories.length > 1)
          FilterGroup(
            id: 'category',
            title: l10n.text('sectionCategories'),
            anyLabel: l10n.text('filterAny'),
            selected: _filterCategory,
            choices: [
              for (final category in categories)
                FilterChoice(value: category, label: category),
            ],
          ),
      ],
    );
    if (result == null || !mounted) return;
    setState(() {
      _filterBank = result['bank'];
      _filterCategory = result['category'];
    });
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<SearchBloc>(),
    child: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final bloc = context.read<SearchBloc>();
        final palette = context.palette;
        return Scaffold(
          appBar: AppBar(
            title: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                _clearFilters();
                bloc.add(SearchQueryChanged(value));
              },
              onSubmitted: (value) {
                _clearFilters();
                bloc.add(PerformSearch(value));
              },
              decoration: InputDecoration(
                hintText: l10n.text('searchBankOffers'),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder:
                      (_, value, __) =>
                          value.text.isEmpty
                              ? const SizedBox.shrink()
                              : IconButton(
                                tooltip: l10n.text('searchClear'),
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  _clearFilters();
                                  bloc.add(ClearSearch());
                                },
                              ),
                ),
              ),
            ),
          ),
          body: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state is SearchLoading) return const SkeletonBody();
              if (state is SearchError) {
                return LoadFailedView(
                  onRetry:
                      _controller.text.trim().isEmpty
                          ? null
                          : () => bloc.add(PerformSearch(_controller.text)),
                );
              }
              if (state is SearchResultsLoaded) {
                if (state.results.isEmpty) {
                  return EmptyOffersView(
                    title: l10n.format('searchNoResultsFor', {
                      'query': state.query.trim(),
                    }),
                    hint: l10n.text('tryAnotherSearch'),
                  );
                }

                final banks =
                    state.results
                        .map((e) => e.bankCode ?? e.bankName)
                        .where((e) => e.isNotEmpty)
                        .toSet()
                        .toList()
                      ..sort();
                final categories =
                    state.results
                        .map((e) => e.category)
                        .where((e) => e.isNotEmpty && e.toLowerCase() != 'all')
                        .toSet()
                        .toList()
                      ..sort();

                final filtered =
                    state.results.where((o) {
                      final bankMatch =
                          _filterBank == null ||
                          (o.bankCode ?? o.bankName).toLowerCase() ==
                              _filterBank!.toLowerCase();
                      final catMatch =
                          _filterCategory == null ||
                          o.category == _filterCategory;
                      return bankMatch && catMatch;
                    }).toList();

                final hasActiveFilter =
                    _filterBank != null || _filterCategory != null;
                final canFilter = banks.length > 1 || categories.length > 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.format('offersCount', {
                                'count': filtered.length,
                              }),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: palette.muted),
                            ),
                          ),
                          if (canFilter)
                            TextButton.icon(
                              key: const Key('search_filter_button'),
                              onPressed:
                                  () => _openFilters(
                                    banks: banks,
                                    categories: categories,
                                  ),
                              icon: const Icon(Icons.tune_rounded, size: 18),
                              label: Text(l10n.filter),
                            ),
                        ],
                      ),
                    ),
                    if (hasActiveFilter)
                      SizedBox(
                        height: 52,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: ActionChip(
                                avatar: const Icon(Icons.clear, size: 16),
                                label: Text(l10n.text('clearFilters')),
                                onPressed: _clearFilters,
                              ),
                            ),
                            if (_filterBank != null)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 8,
                                ),
                                child: InputChip(
                                  label: Text(_bankLabel(_filterBank!)),
                                  onDeleted:
                                      () => setState(() => _filterBank = null),
                                ),
                              ),
                            if (_filterCategory != null)
                              InputChip(
                                label: Text(_filterCategory!),
                                onDeleted:
                                    () =>
                                        setState(() => _filterCategory = null),
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      child:
                          filtered.isEmpty
                              ? EmptyOffersView(
                                title: l10n.text('emptyOffersTitle'),
                                hint: l10n.text('emptyOffersHint'),
                                onClear: _clearFilters,
                              )
                              : RefreshIndicator(
                                onRefresh:
                                    () async => bloc.add(
                                      PerformSearch(_controller.text),
                                    ),
                                child: ListView.builder(
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    4,
                                    16,
                                    16,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder:
                                      (_, index) => OfferCard(
                                        offer: filtered[index],
                                        contextOffers: filtered,
                                        initialIndex: index,
                                      ),
                                ),
                              ),
                    ),
                  ],
                );
              }
              final initial = state is SearchInitial ? state : SearchInitial();
              if (initial.recentSearches.isEmpty) {
                return EmptyOffersView(
                  title: l10n.text('searchIdleTitle'),
                  hint: l10n.text('searchIdleHint'),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    l10n.recentSearches,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final query in initial.recentSearches)
                        ActionChip(
                          avatar: const Icon(Icons.history, size: 18),
                          label: Text(query),
                          onPressed: () {
                            _controller.text = query;
                            _controller.selection = TextSelection.collapsed(
                              offset: query.length,
                            );
                            bloc.add(PerformSearch(query));
                          },
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}
