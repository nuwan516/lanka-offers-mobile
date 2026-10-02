import 'package:equatable/equatable.dart';
import '../../../../core/enums/offer_type.dart';

abstract class ExploreEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadExploreOffers extends ExploreEvent {
  final OfferType? filterType;
  final String? category;
  final String? district;
  final String? bank;
  final bool matchMyCards;
  final bool nearbyOnly;
  final double? userLatitude;
  final double? userLongitude;
  final bool? isMapView;

  LoadExploreOffers({
    this.filterType,
    this.category,
    this.district,
    this.bank,
    this.matchMyCards = false,
    this.nearbyOnly = false,
    this.userLatitude,
    this.userLongitude,
    this.isMapView,
  });

  @override
  List<Object?> get props => [
    filterType,
    category,
    district,
    bank,
    matchMyCards,
    nearbyOnly,
    userLatitude,
    userLongitude,
    isMapView,
  ];
}

class RefreshExploreOffers extends ExploreEvent {}

class FilterOffers extends ExploreEvent {
  final OfferType? type;
  final String? category;
  final String? district;
  final String? bank;
  final bool? matchMyCards;
  final bool? nearbyOnly;
  final double? userLatitude;
  final double? userLongitude;

  FilterOffers({
    this.type,
    this.category,
    this.district,
    this.bank,
    this.matchMyCards,
    this.nearbyOnly,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  List<Object?> get props => [
    type,
    category,
    district,
    bank,
    matchMyCards,
    nearbyOnly,
    userLatitude,
    userLongitude,
  ];
}

class ToggleMapView extends ExploreEvent {}

class ToggleNearby extends ExploreEvent {
  final bool nearbyOnly;
  final double? userLatitude;
  final double? userLongitude;

  ToggleNearby({
    required this.nearbyOnly,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  List<Object?> get props => [nearbyOnly, userLatitude, userLongitude];
}

class SortOffers extends ExploreEvent {
  final String sortBy; // 'popularity', 'date', 'distance'

  SortOffers(this.sortBy);

  @override
  List<Object?> get props => [sortBy];
}
