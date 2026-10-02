import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../common/widgets/error_view.dart';
import '../../common/widgets/offer_card.dart';
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
        return Scaffold(
          appBar: AppBar(
            title: TextField(
              controller: _controller,
              autofocus: true,
              onChanged:
                  (value) =>
                      context.read<SearchBloc>().add(SearchQueryChanged(value)),
              decoration: InputDecoration(
                hintText: l10n.text('searchBankOffers'),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  tooltip: l10n.cancel,
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    context.read<SearchBloc>().add(ClearSearch());
                  },
                ),
              ),
            ),
          ),
          body: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state is SearchLoading)
                return const Center(child: CircularProgressIndicator());
              if (state is SearchError)
                return ErrorView(
                  message: l10n.text('connectionRetry'),
                  onRetry:
                      _controller.text.isEmpty
                          ? null
                          : () => context.read<SearchBloc>().add(
                            PerformSearch(_controller.text),
                          ),
                );
              if (state is SearchResultsLoaded) {
                if (state.results.isEmpty)
                  return _Empty(
                    title: l10n.text('noMatchingOffers'),
                    body: l10n.text('tryAnotherSearch'),
                  );
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.results.length,
                  itemBuilder: (_, index) => OfferCard(
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Wrap(
                      spacing: 8,
                      children:
                          initial.recentSearches
                              .map(
                                (query) => ActionChip(
                                  label: Text(query),
                                  onPressed: () {
                                    _controller.text = query;
                                    context.read<SearchBloc>().add(
                                      PerformSearch(query),
                                    );
                                  },
                                ),
                              )
                              .toList(),
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

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 56),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(body, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
