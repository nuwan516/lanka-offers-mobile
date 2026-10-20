import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/semantics/offer_semantics.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../../domain/repositories/offer_repository.dart';

class PaginatedFilters extends Equatable {
  final String? bank;
  final String? category;
  final String? search;
  final String? locationScope;

  const PaginatedFilters({
    this.bank,
    this.category,
    this.search,
    this.locationScope,
  });

  bool get isFiltered =>
      bank != null ||
      category != null ||
      (search != null && search!.isNotEmpty) ||
      locationScope != null;

  PaginatedFilters copyWith({
    String? bank,
    String? category,
    String? search,
    String? locationScope,
    bool clearBank = false,
    bool clearCategory = false,
    bool clearSearch = false,
    bool clearScope = false,
  }) => PaginatedFilters(
    bank: clearBank ? null : bank ?? this.bank,
    category: clearCategory ? null : category ?? this.category,
    search: clearSearch ? null : search ?? this.search,
    locationScope: clearScope ? null : locationScope ?? this.locationScope,
  );

  @override
  List<Object?> get props => [bank, category, search, locationScope];
}

enum PaginationStatus { initial, loading, loaded, failure }

class PaginatedOffersState extends Equatable {
  final PaginationStatus status;
  final List<BankOffer> offers;
  final int total;
  final int offset;
  final int pageSize;
  final bool hasReachedMax;
  final bool isFetchingMore;
  final String? errorMessage;
  final PaginatedFilters filters;

  const PaginatedOffersState({
    this.status = PaginationStatus.initial,
    this.offers = const [],
    this.total = 0,
    this.offset = 0,
    this.pageSize = 20,
    this.hasReachedMax = false,
    this.isFetchingMore = false,
    this.errorMessage,
    this.filters = const PaginatedFilters(),
  });

  PaginatedOffersState copyWith({
    PaginationStatus? status,
    List<BankOffer>? offers,
    int? total,
    int? offset,
    int? pageSize,
    bool? hasReachedMax,
    bool? isFetchingMore,
    String? errorMessage,
    bool clearError = false,
    PaginatedFilters? filters,
  }) => PaginatedOffersState(
    status: status ?? this.status,
    offers: offers ?? this.offers,
    total: total ?? this.total,
    offset: offset ?? this.offset,
    pageSize: pageSize ?? this.pageSize,
    hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    filters: filters ?? this.filters,
  );

  @override
  List<Object?> get props => [
    status,
    offers,
    total,
    offset,
    pageSize,
    hasReachedMax,
    isFetchingMore,
    errorMessage,
    filters,
  ];
}

class PaginatedOffersCubit extends Cubit<PaginatedOffersState> {
  PaginatedOffersCubit(this._repository, {int pageSize = 20})
    : _pageSize = pageSize,
      super(PaginatedOffersState(pageSize: pageSize));

  final OfferRepository _repository;
  final int _pageSize;
  int _requestId = 0;

  /// Loads the first page with given [filters].
  Future<void> loadInitial({
    PaginatedFilters filters = const PaginatedFilters(),
  }) async {
    final currentReq = ++_requestId;
    emit(
      state.copyWith(
        status: PaginationStatus.loading,
        filters: filters,
        offers: const [],
        offset: 0,
        total: 0,
        hasReachedMax: false,
        isFetchingMore: false,
        clearError: true,
      ),
    );

    try {
      final result = await _repository.getOffersPage(
        bank: filters.bank,
        category: filters.category,
        search: filters.search,
        locationScope: filters.locationScope,
        limit: _pageSize,
        offset: 0,
      );

      if (currentReq != _requestId || isClosed) return;

      final items =
          result.items
              .whereType<BankOffer>()
              .where((o) => !OfferSemantics.isExpired(o.validity))
              .toList();

      // Deduplicate by uniqueId
      final seenIds = <String>{};
      final uniqueItems = <BankOffer>[];
      for (final item in items) {
        if (seenIds.add(item.uniqueId)) {
          uniqueItems.add(item);
        }
      }

      final reachedMax =
          result.items.isEmpty ||
          uniqueItems.isEmpty ||
          uniqueItems.length >= result.total ||
          result.items.length < _pageSize;

      emit(
        state.copyWith(
          status: PaginationStatus.loaded,
          offers: uniqueItems,
          total: result.total,
          offset: uniqueItems.length,
          hasReachedMax: reachedMax,
          isFetchingMore: false,
          clearError: true,
        ),
      );
    } catch (e) {
      if (currentReq != _requestId || isClosed) return;
      emit(
        state.copyWith(
          status: PaginationStatus.failure,
          errorMessage: e.toString(),
          isFetchingMore: false,
        ),
      );
    }
  }

  /// Incremental page fetching: `GET /api/offers?limit=...&offset=...`.
  /// Implements duplicate-request prevention and end-of-results detection.
  Future<void> loadNextPage() async {
    if (state.status != PaginationStatus.loaded ||
        state.isFetchingMore ||
        state.hasReachedMax) {
      return;
    }

    final currentReq = _requestId;
    emit(state.copyWith(isFetchingMore: true, clearError: true));

    try {
      final result = await _repository.getOffersPage(
        bank: state.filters.bank,
        category: state.filters.category,
        search: state.filters.search,
        locationScope: state.filters.locationScope,
        limit: _pageSize,
        offset: state.offers.length,
      );

      if (currentReq != _requestId || isClosed) return;

      final rawItems =
          result.items
              .whereType<BankOffer>()
              .where((o) => !OfferSemantics.isExpired(o.validity))
              .toList();

      // Stable offer ID deduplication against already loaded offers
      final existingIds = state.offers.map((o) => o.uniqueId).toSet();
      final newItems = <BankOffer>[];
      for (final item in rawItems) {
        if (!existingIds.contains(item.uniqueId)) {
          existingIds.add(item.uniqueId);
          newItems.add(item);
        }
      }

      final reachedMax =
          result.items.isEmpty ||
          newItems.isEmpty ||
          state.offers.length + newItems.length >= result.total ||
          result.items.length < _pageSize;

      emit(
        state.copyWith(
          offers: [...state.offers, ...newItems],
          offset: state.offers.length + newItems.length,
          total: result.total,
          hasReachedMax: reachedMax,
          isFetchingMore: false,
          clearError: true,
        ),
      );
    } catch (e) {
      if (currentReq != _requestId || isClosed) return;
      // Do not discard existing offers on incremental fetch failure
      emit(
        state.copyWith(
          isFetchingMore: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Refreshes the feed using current filters.
  Future<void> refresh() => loadInitial(filters: state.filters);

  /// Resets all filters back to default.
  Future<void> resetFilters() =>
      loadInitial(filters: const PaginatedFilters());
}
