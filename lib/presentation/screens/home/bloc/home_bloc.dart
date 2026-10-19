import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/usecases/get_all_offers.dart';
import '../../../../domain/entities/bank_summary.dart';
import '../../../../domain/usecases/get_banks.dart';
import '../../../../domain/usecases/get_nearby_offers.dart';
import '../../../../core/enums/offer_type.dart';
import 'home_event.dart';
import 'home_state.dart';
import '../../../../domain/entities/bank_offer.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetAllOffers getAllOffers;
  final GetNearbyOffers getNearbyOffers;
  final GetBanks getBanks;

  HomeBloc({
    required this.getAllOffers,
    required this.getNearbyOffers,
    required this.getBanks,
  }) : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<RefreshHomeData>(_onRefreshHomeData);
    on<ChangeOfferType>(_onChangeOfferType);
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());

    try {
      final allOffers = (await getAllOffers()).whereType<BankOffer>().toList();

      // The bank directory is a nicety: if it fails the offers still show.
      var banks = <BankSummary>[];
      try {
        banks = await getBanks();
      } catch (_) {}
      // Nearby results are only shown after real location is available.
      final nearby = <BankOffer>[];

      final featured =
          allOffers
              .where(
                (o) =>
                    o.quality.confidenceScore >= 0.85 &&
                    (o.metrics?.popularityScore ?? 0) >= 75,
              )
              .take(5)
              .toList();

      final categories = _extractCategories(allOffers);

      emit(
        HomeLoaded(
          allOffers: allOffers,
          featuredOffers: featured,
          nearbyOffers: nearby,
          categories: categories,
          recentlyViewed: const [],
          selectedOfferType: OfferType.bankOffer,
          banks: banks,
        ),
      );
    } catch (e) {
      emit(HomeError(message: 'offers_load_failed'));
    }
  }

  Future<void> _onRefreshHomeData(
    RefreshHomeData event,
    Emitter<HomeState> emit,
  ) async {
    add(LoadHomeData());
  }

  Future<void> _onChangeOfferType(
    ChangeOfferType event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(selectedOfferType: event.offerType));
    }
  }

  List<Category> _extractCategories(List<BankOffer> offers) {
    final categoryMap = <String, int>{};
    for (final offer in offers) {
      categoryMap[offer.category] = (categoryMap[offer.category] ?? 0) + 1;
    }

    return categoryMap.entries
        .map(
          (e) => Category(
            name: e.key,
            count: e.value,
            icon: _getCategoryIcon(e.key),
          ),
        )
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'dining':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'travel':
        return Icons.flight;
      case 'fashion':
        return Icons.checkroom;
      case 'electronics':
        return Icons.devices;
      case 'healthcare':
        return Icons.local_hospital;
      case 'wellness':
        return Icons.spa;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.category;
    }
  }
}
