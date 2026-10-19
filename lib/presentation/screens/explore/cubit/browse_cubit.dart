import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/semantics/offer_semantics.dart';
import '../../../../domain/entities/bank_offer.dart';
import '../../../../domain/repositories/offer_repository.dart';

enum BrowseStatus { loading, loaded, failed }

enum BrowseSort { newest, discount, endingSoon }

/// [bankCode] and [scope] are filtered by the API; [category] and [sort] are
/// applied to that complete result, so category choices always come from the
/// whole set and ordering is never based on a partial page.
class BrowseFilters extends Equatable {
  final String? bankCode;
  final String? category;

  /// `ONLINE`, `NATIONWIDE`, or null for every offer.
  final String? scope;
  final BrowseSort sort;

  const BrowseFilters({
    this.bankCode,
    this.category,
    this.scope,
    this.sort = BrowseSort.newest,
  });

  bool get isFiltered => bankCode != null || category != null || scope != null;

  BrowseFilters copyWith({
    String? bankCode,
    String? category,
    String? scope,
    BrowseSort? sort,
    bool clearBank = false,
    bool clearCategory = false,
    bool clearScope = false,
  }) => BrowseFilters(
    bankCode: clearBank ? null : bankCode ?? this.bankCode,
    category: clearCategory ? null : category ?? this.category,
    scope: clearScope ? null : scope ?? this.scope,
    sort: sort ?? this.sort,
  );

  @override
  List<Object?> get props => [bankCode, category, scope, sort];
}

class BrowseState extends Equatable {
  final BrowseStatus status;
  final BrowseFilters filters;

  /// Live offers for the server-side filters, before category and sort.
  final List<BankOffer> base;

  /// [base] after category and sort: what the list shows.
  final List<BankOffer> offers;

  const BrowseState({
    this.status = BrowseStatus.loading,
    this.filters = const BrowseFilters(),
    this.base = const [],
    this.offers = const [],
  });

  List<String> get categories =>
      (base
          .map((o) => o.category)
          .where((c) => c.trim().isNotEmpty && c.toLowerCase() != 'all')
          .toSet()
          .toList()
        ..sort());

  @override
  List<Object?> get props => [status, filters, base, offers];
}

class BrowseCubit extends Cubit<BrowseState> {
  BrowseCubit(this._repository) : super(const BrowseState());

  final OfferRepository _repository;
  int _request = 0;

  /// Reloads from the API for [filters]. A slower, older request can never
  /// overwrite a newer one.
  Future<void> load(BrowseFilters filters) async {
    final id = ++_request;
    emit(BrowseState(status: BrowseStatus.loading, filters: filters));
    try {
      final all = await _repository.queryOffers(
        bank: filters.bankCode,
        locationScope: filters.scope,
      );
      if (id != _request || isClosed) return;
      final base =
          all
              .whereType<BankOffer>()
              .where((o) => !OfferSemantics.isExpired(o.validity))
              .toList();
      emit(
        BrowseState(
          status: BrowseStatus.loaded,
          filters: filters,
          base: base,
          offers: arrange(base, filters),
        ),
      );
    } catch (_) {
      if (id != _request || isClosed) return;
      emit(BrowseState(status: BrowseStatus.failed, filters: filters));
    }
  }

  /// Category and sort need no new request.
  void refine({
    String? category,
    bool clearCategory = false,
    BrowseSort? sort,
  }) {
    final filters = state.filters.copyWith(
      category: category,
      clearCategory: clearCategory,
      sort: sort,
    );
    emit(
      BrowseState(
        status: state.status,
        filters: filters,
        base: state.base,
        offers: arrange(state.base, filters),
      ),
    );
  }

  static num _percent(BankOffer o) =>
      o.discount?.type == 'percentage' ? (o.discount!.value as num? ?? 0) : 0;

  static List<BankOffer> arrange(List<BankOffer> base, BrowseFilters filters) {
    final list =
        filters.category == null
            ? [...base]
            : base.where((o) => o.category == filters.category).toList();
    switch (filters.sort) {
      case BrowseSort.discount:
        list.sort((a, b) => _percent(b).compareTo(_percent(a)));
      case BrowseSort.endingSoon:
        list.sort(
          (a, b) => (OfferSemantics.daysLeft(a.validity) ?? 1 << 30).compareTo(
            OfferSemantics.daysLeft(b.validity) ?? 1 << 30,
          ),
        );
      case BrowseSort.newest:
        break;
    }
    return list;
  }
}
