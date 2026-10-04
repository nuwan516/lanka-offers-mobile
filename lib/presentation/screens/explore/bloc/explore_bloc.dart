import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../domain/usecases/get_all_offers.dart';
import '../../../../domain/usecases/filter_offers.dart' as usecases;
import '../../../../data/datasources/remote/api_offers_datasource.dart';
import 'explore_event.dart';
import 'explore_state.dart';
import '../../../../domain/entities/bank_offer.dart';

import '../../../../core/di/injection.dart';
import '../../../../domain/repositories/user_repository.dart';
import '../../../../domain/services/card_matching_service.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  final GetAllOffers getAllOffers;
  final usecases.FilterOffers filterOffers;
  final ApiOffersDataSource _apiDataSource;

  ExploreBloc({required this.getAllOffers, required this.filterOffers})
    : _apiDataSource = ApiOffersDataSource(),
      super(ExploreInitial()) {
    on<LoadExploreOffers>(_onLoadExploreOffers);
    on<RefreshExploreOffers>(_onRefreshExploreOffers);
    on<FilterOffers>(_onFilterOffers);
    on<SortOffers>(_onSortOffers);
    on<ToggleMapView>(_onToggleMapView);
    on<ToggleNearby>(_onToggleNearby);
  }

  Future<void> _onLoadExploreOffers(
    LoadExploreOffers event,
    Emitter<ExploreState> emit,
  ) async {
    emit(ExploreLoading());

    try {
      List<BankOffer> offers;

      if (event.nearbyOnly && event.userLatitude != null && event.userLongitude != null) {
        try {
          offers = await _apiDataSource.fetchNearbyOffers(
            lat: event.userLatitude!,
            lng: event.userLongitude!,
            radius: 25.0,
            bank: event.bank != null && event.bank!.isNotEmpty ? _bankApiKey(event.bank!) : null,
            category: event.category,
          );
        } catch (_) {
          offers = await _apiDataSource.fetchOffers(
            bank: event.bank != null && event.bank!.isNotEmpty ? _bankApiKey(event.bank!) : null,
            category: event.category,
          );
        }
      } else if (event.bank != null && event.bank!.isNotEmpty) {
        offers = await _apiDataSource.fetchOffers(
          bank: _bankApiKey(event.bank!),
          category: event.category,
        );
      } else if (event.category != null && event.category!.isNotEmpty) {
        offers = await _apiDataSource.fetchOffers(
          category: event.category,
        );
      } else {
        offers = (await getAllOffers()).whereType<BankOffer>().toList();
      }

      if (event.district != null && event.district!.isNotEmpty) {
        offers = offers.where((o) {
          return o.locations.any(
            (loc) => loc.district.toLowerCase() == event.district!.toLowerCase(),
          );
        }).toList();
      }

      if (event.matchMyCards) {
        final prefs = await getIt<UserRepository>().getPreferences();
        final userCards = CardMatchingService.cardsFromPreferences(prefs);
        if (userCards.isNotEmpty) {
          offers = offers.where((o) {
            final res = CardMatchingService.matchUserCards(o, userCards);
            return !res.isMismatch;
          }).toList();
        }
      }

      if (event.nearbyOnly && event.userLatitude != null && event.userLongitude != null) {
        final uLat = event.userLatitude!;
        final uLng = event.userLongitude!;
        // Sort by distance (either from backend-api distanceKm or local calculation)
        offers.sort((a, b) {
          final distA = a.distanceKm ?? _minDistanceKm(a, uLat, uLng);
          final distB = b.distanceKm ?? _minDistanceKm(b, uLat, uLng);
          return distA.compareTo(distB);
        });
      } else {
        offers = _sortOffers(offers, 'popularity');
      }

      emit(
        ExploreLoaded(
          offers: offers,
          selectedType: event.filterType,
          selectedCategory: event.category,
          selectedDistrict: event.district,
          selectedBank: event.bank,
          matchMyCards: event.matchMyCards,
          nearbyOnly: event.nearbyOnly,
          userLatitude: event.userLatitude,
          userLongitude: event.userLongitude,
          isMapView: event.isMapView ?? (state is ExploreLoaded ? (state as ExploreLoaded).isMapView : false),
        ),
      );
    } catch (e) {
      emit(ExploreError(message: 'offers_load_failed'));
    }
  }

  double _minDistanceKm(BankOffer offer, double uLat, double uLng) {
    double min = double.infinity;
    for (final loc in offer.locations) {
      if (loc.latitude == 0 && loc.longitude == 0) continue;
      final d = Geolocator.distanceBetween(uLat, uLng, loc.latitude, loc.longitude) / 1000;
      if (d < min) min = d;
    }
    return min;
  }

  void _onToggleMapView(ToggleMapView event, Emitter<ExploreState> emit) {
    if (state is ExploreLoaded) {
      final s = state as ExploreLoaded;
      emit(s.copyWith(isMapView: !s.isMapView));
    }
  }

  void _onToggleNearby(ToggleNearby event, Emitter<ExploreState> emit) {
    if (state is ExploreLoaded) {
      final s = state as ExploreLoaded;
      add(
        LoadExploreOffers(
          filterType: s.selectedType,
          category: s.selectedCategory,
          district: s.selectedDistrict,
          bank: s.selectedBank,
          matchMyCards: s.matchMyCards,
          nearbyOnly: event.nearbyOnly,
          userLatitude: event.userLatitude,
          userLongitude: event.userLongitude,
          isMapView: s.isMapView,
        ),
      );
    }
  }

  Future<void> _onRefreshExploreOffers(
    RefreshExploreOffers event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is ExploreLoaded) {
      final currentState = state as ExploreLoaded;
      add(
        LoadExploreOffers(
          filterType: currentState.selectedType,
          category: currentState.selectedCategory,
          district: currentState.selectedDistrict,
          bank: currentState.selectedBank,
          matchMyCards: currentState.matchMyCards,
          nearbyOnly: currentState.nearbyOnly,
          userLatitude: currentState.userLatitude,
          userLongitude: currentState.userLongitude,
          isMapView: currentState.isMapView,
        ),
      );
    } else {
      add(LoadExploreOffers());
    }
  }

  Future<void> _onFilterOffers(
    FilterOffers event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is ExploreLoaded) {
      final currentState = state as ExploreLoaded;
      add(
        LoadExploreOffers(
          filterType: event.type ?? currentState.selectedType,
          category: event.category ?? currentState.selectedCategory,
          district: event.district ?? currentState.selectedDistrict,
          bank: event.bank ?? currentState.selectedBank,
          matchMyCards: event.matchMyCards ?? currentState.matchMyCards,
          nearbyOnly: event.nearbyOnly ?? currentState.nearbyOnly,
          userLatitude: event.userLatitude ?? currentState.userLatitude,
          userLongitude: event.userLongitude ?? currentState.userLongitude,
          isMapView: currentState.isMapView,
        ),
      );
    }
  }

  Future<void> _onSortOffers(
    SortOffers event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is ExploreLoaded) {
      final currentState = state as ExploreLoaded;
      final sortedOffers = _sortOffers(currentState.offers, event.sortBy);
      emit(currentState.copyWith(offers: sortedOffers, sortBy: event.sortBy));
    }
  }

  List<BankOffer> _sortOffers(List<BankOffer> offers, String sortBy) {
    final sorted = List<BankOffer>.from(offers);
    switch (sortBy) {
      case 'popularity':
        sorted.sort((a, b) {
          final scoreA = a.metrics?.popularityScore ?? 0;
          final scoreB = b.metrics?.popularityScore ?? 0;
          return scoreB.compareTo(scoreA);
        });
      case 'date':
        sorted.sort((a, b) {
          return b.validity.validUntil.compareTo(a.validity.validUntil);
        });
      case 'distance':
        // Sort by distance only when real location is available — skipped here.
        break;
    }
    return sorted;
  }

  /// Convert the display bank label back to the API key the backend expects.
  /// The API accepts the raw short code (e.g. 'hnb', 'combank').
  String _bankApiKey(String displayLabel) {
    return switch (displayLabel.toLowerCase()) {
      'hnb' => 'hnb',
      'bank of ceylon' => 'boc',
      'commercial bank' => 'combank',
      'dfcc bank' => 'dfcc',
      'ndb bank' => 'ndb',
      'nsb' => 'nsb',
      'pan asia bank' => 'pabc',
      "people's bank" => 'peoples',
      'sampath bank' => 'sampath',
      'seylan bank' => 'seylan',
      _ => displayLabel.toLowerCase(),
    };
  }
}
