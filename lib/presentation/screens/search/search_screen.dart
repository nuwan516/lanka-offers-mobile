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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              onChanged: (value) => bloc.add(SearchQueryChanged(value)),
              // Submitting searches immediately, skipping the debounce.
              onSubmitted: (value) => bloc.add(PerformSearch(value)),
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
                return ListView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.results.length,
                  itemBuilder:
                      (_, index) => OfferCard(
                        offer: state.results[index],
                        contextOffers: state.results,
                        initialIndex: index,
                      ),
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
