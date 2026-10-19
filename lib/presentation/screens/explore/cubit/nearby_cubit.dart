import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/semantics/offer_semantics.dart';
import '../../../../core/services/location_service.dart';
import '../../../../domain/entities/bank_offer.dart';
import '../../../../domain/usecases/get_nearby_offers.dart';

class NearbyPlace {
  const NearbyPlace.city(this.name, this.latitude, this.longitude)
    : isDevice = false;
  const NearbyPlace.device(this.latitude, this.longitude)
    : name = null,
      isDevice = true;

  /// Null for the device position (shown as "your location").
  final String? name;
  final double latitude;
  final double longitude;
  final bool isDevice;
}

/// Manual fallbacks when device location is off or denied.
const List<NearbyPlace> presetCities = [
  NearbyPlace.city('Colombo', 6.9271, 79.8612),
  NearbyPlace.city('Kandy', 7.2906, 80.6337),
  NearbyPlace.city('Galle', 6.0535, 80.2210),
  NearbyPlace.city('Negombo', 7.2008, 79.8737),
  NearbyPlace.city('Kurunegala', 7.4863, 80.3623),
];

enum NearbyStatus { idle, locating, loading, loaded, failed }

/// Why device location could not be used (the manual city list still works).
enum LocationIssue { none, servicesOff, denied, deniedForever, unavailable }

class NearbyState extends Equatable {
  final NearbyStatus status;
  final NearbyPlace place;
  final double radiusKm;
  final LocationIssue issue;
  final List<BankOffer> offers;

  const NearbyState({
    this.status = NearbyStatus.idle,
    this.place = const NearbyPlace.city('Colombo', 6.9271, 79.8612),
    this.radiusKm = 10,
    this.issue = LocationIssue.none,
    this.offers = const [],
  });

  NearbyState copyWith({
    NearbyStatus? status,
    NearbyPlace? place,
    double? radiusKm,
    LocationIssue? issue,
    List<BankOffer>? offers,
  }) => NearbyState(
    status: status ?? this.status,
    place: place ?? this.place,
    radiusKm: radiusKm ?? this.radiusKm,
    issue: issue ?? this.issue,
    offers: offers ?? this.offers,
  );

  @override
  List<Object?> get props => [
    status,
    place.name,
    place.latitude,
    place.longitude,
    place.isDevice,
    radiusKm,
    issue,
    offers,
  ];
}

class NearbyCubit extends Cubit<NearbyState> {
  NearbyCubit({required this.getNearbyOffers, required this.locationService})
    : super(const NearbyState());

  final GetNearbyOffers getNearbyOffers;
  final LocationService locationService;
  int _request = 0;

  /// Loads offers around the current place without asking for permission.
  Future<void> refresh() => _load(state.place, state.radiusKm);

  Future<void> selectCity(NearbyPlace city) =>
      _load(city, state.radiusKm, issue: LocationIssue.none);

  Future<void> setRadius(double km) => _load(state.place, km);

  /// Asks for permission when needed. On denial the cubit keeps the current
  /// city and reports why, so the UI can offer settings or the city list.
  Future<void> useDeviceLocation() async {
    emit(
      state.copyWith(status: NearbyStatus.locating, issue: LocationIssue.none),
    );
    final issue = await _checkPermission();
    if (issue != LocationIssue.none) {
      emit(state.copyWith(status: NearbyStatus.idle, issue: issue));
      return;
    }
    final position = await locationService.getCurrentPosition();
    if (position == null) {
      emit(
        state.copyWith(
          status: NearbyStatus.idle,
          issue: LocationIssue.unavailable,
        ),
      );
      return;
    }
    await _load(
      NearbyPlace.device(position.latitude, position.longitude),
      state.radiusKm,
      issue: LocationIssue.none,
    );
  }

  Future<LocationIssue> _checkPermission() async {
    if (!await locationService.isLocationServiceEnabled()) {
      return LocationIssue.servicesOff;
    }
    var permission = await locationService.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await locationService.requestPermission();
    }
    return switch (permission) {
      LocationPermission.denied => LocationIssue.denied,
      LocationPermission.deniedForever => LocationIssue.deniedForever,
      _ => LocationIssue.none,
    };
  }

  Future<void> _load(
    NearbyPlace place,
    double radiusKm, {
    LocationIssue? issue,
  }) async {
    final id = ++_request;
    emit(
      state.copyWith(
        status: NearbyStatus.loading,
        place: place,
        radiusKm: radiusKm,
        issue: issue,
      ),
    );
    try {
      final result = await getNearbyOffers(
        latitude: place.latitude,
        longitude: place.longitude,
        radius: radiusKm,
      );
      if (id != _request || isClosed) return;
      // Confirmed branches nearest-first; area-only offers after them, since
      // their "distance" is to a town centre.
      double rank(BankOffer o) =>
          OfferSemantics.hasConfirmedBranch(o)
              ? (o.distanceKm ?? double.maxFinite - 1)
              : double.maxFinite;
      final offers =
          result.whereType<BankOffer>().toList()
            ..sort((a, b) => rank(a).compareTo(rank(b)));
      emit(state.copyWith(status: NearbyStatus.loaded, offers: offers));
    } catch (_) {
      if (id != _request || isClosed) return;
      emit(state.copyWith(status: NearbyStatus.failed, offers: const []));
    }
  }
}
