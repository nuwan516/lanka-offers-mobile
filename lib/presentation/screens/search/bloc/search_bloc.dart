import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../domain/usecases/search_offers.dart';
import '../../../../domain/repositories/user_repository.dart';
import 'search_event.dart';
import 'search_state.dart';
import '../../../../domain/entities/bank_offer.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchOffers searchOffers;
  final UserRepository userRepository;
  Timer? _debounceTimer;

  SearchBloc({required this.searchOffers, required this.userRepository})
    : super(SearchInitial()) {
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<PerformSearch>(_onPerformSearch);
    on<ClearSearch>(_onClearSearch);
    on<LoadRecentSearches>(_onLoadRecentSearches);
    on<LoadPopularSearches>(_onLoadPopularSearches);

    add(LoadRecentSearches());
    add(LoadPopularSearches());
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    _debounceTimer?.cancel();

    if (event.query.isEmpty) {
      final current = state;
      emit(
        SearchInitial(
          recentSearches:
              current is SearchInitial ? current.recentSearches : const [],
          popularSearches:
              current is SearchInitial ? current.popularSearches : const [],
        ),
      );
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      add(PerformSearch(event.query));
    });
  }

  Future<void> _onPerformSearch(
    PerformSearch event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    try {
      await userRepository.addRecentSearch(event.query);
      final results =
          (await searchOffers(event.query)).whereType<BankOffer>().toList();

      emit(SearchResultsLoaded(results: results, query: event.query));
    } catch (e) {
      emit(SearchError(message: 'search_failed'));
    }
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<SearchState> emit,
  ) async {
    final current = state;
    emit(
      SearchInitial(
        recentSearches:
            current is SearchInitial ? current.recentSearches : const [],
        popularSearches:
            current is SearchInitial ? current.popularSearches : const [],
      ),
    );
  }

  Future<void> _onLoadRecentSearches(
    LoadRecentSearches event,
    Emitter<SearchState> emit,
  ) async {
    try {
      final List<String> recent = await userRepository.getRecentSearches();
      final List<String> popular;
      if (state is SearchInitial) {
        final SearchInitial initialState = state as SearchInitial;
        popular = List<String>.from(initialState.popularSearches);
      } else {
        popular = <String>[];
      }
      emit(SearchInitial(recentSearches: recent, popularSearches: popular));
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _onLoadPopularSearches(
    LoadPopularSearches event,
    Emitter<SearchState> emit,
  ) async {
    // Mock popular searches
    final List<String> popular = <String>[];
    final List<String> recent;
    if (state is SearchInitial) {
      final SearchInitial initialState = state as SearchInitial;
      recent = List<String>.from(initialState.recentSearches);
    } else {
      recent = <String>[];
    }
    emit(SearchInitial(recentSearches: recent, popularSearches: popular));
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
