import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<SearchBloc>(),
    child: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final bloc = context.read<SearchBloc>();
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
              // Submitting searches immediately, skipping the debounce.
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
                        .where(
                          (e) => e.isNotEmpty && e.toLowerCase() != 'all',
                        )
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

                return Column(
                  children: [
                    if (banks.length > 1 || categories.length > 1)
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          children: [
                            if (hasActiveFilter)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 8,
                                ),
                                child: ActionChip(
                                  avatar: const Icon(Icons.clear, size: 14),
                                  label: Text(l10n.text('clearFilters')),
                                  onPressed: _clearFilters,
                                ),
                              ),
                            for (final b in banks)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 8,
                                ),
                                child: FilterChip(
                                  label: Text(
                                    b.toUpperCase(),
                                  ),
                                  selected: _filterBank == b,
                                  onSelected:
                                      (on) => setState(
                                        () => _filterBank = on ? b : null,
                                      ),
                                ),
                              ),
                            for (final c in categories)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 8,
                                ),
                                child: FilterChip(
                                  label: Text(c),
                                  selected: _filterCategory == c,
                                  onSelected:
                                      (on) => setState(
                                        () =>
                                            _filterCategory = on ? c : null,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Row(
                        children: [
                          Text(
                            l10n.format('offersCount', {
                              'count': filtered.length,
                            }),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child:
                          filtered.isEmpty
                              ? EmptyOffersView(
                                title: l10n.text('emptyOffersTitle'),
                                hint: l10n.text('clearFilters'),
                                onClear: _clearFilters,
                              )
                              : ListView.builder(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                  ],
                );
              }
              final initial = state is SearchInitial ? state : SearchInitial();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (initial.recentSearches.isNotEmpty) ...[
                    Text(
                      l10n.recentSearches,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final query in initial.recentSearches)
                          ActionChip(
                            avatar: const Icon(Icons.history, size: 16),
                            label: Text(query),
                            onPressed: () {
                              _controller.text = query;
                              bloc.add(PerformSearch(query));
                            },
                          ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    ),
  );
}
