import 'package:equatable/equatable.dart';
import '../../../../core/enums/offer_type.dart';
import '../../../../domain/entities/bank_offer.dart';

abstract class ExploreState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ExploreInitial extends ExploreState {}

class ExploreLoading extends ExploreState {}

class ExploreLoaded extends ExploreState {
  final List<BankOffer> offers;
  final OfferType? selectedType;
  final String? selectedCategory;
  final String? selectedDistrict;
  final String? selectedBank;
  final bool matchMyCards;
  final bool nearbyOnly;
  final double? userLatitude;
  final double? userLongitude;
  final bool isMapView;
  final String sortBy;

  ExploreLoaded({
    required this.offers,
    this.selectedType,
    this.selectedCategory,
    this.selectedDistrict,
    this.selectedBank,
    this.matchMyCards = false,
    this.nearbyOnly = false,
    this.userLatitude,
    this.userLongitude,
    this.isMapView = false,
    this.sortBy = 'popularity',
  });

  ExploreLoaded copyWith({
    List<BankOffer>? offers,
    OfferType? selectedType,
    String? selectedCategory,
    String? selectedDistrict,
    String? selectedBank,
    bool? matchMyCards,
    bool? nearbyOnly,
    double? userLatitude,
    double? userLongitude,
    bool? isMapView,
    String? sortBy,
  }) {
    return ExploreLoaded(
      offers: offers ?? this.offers,
      selectedType: selectedType ?? this.selectedType,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      selectedBank: selectedBank ?? this.selectedBank,
      matchMyCards: matchMyCards ?? this.matchMyCards,
      nearbyOnly: nearbyOnly ?? this.nearbyOnly,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      isMapView: isMapView ?? this.isMapView,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [
    offers,
    selectedType,
    selectedCategory,
    selectedDistrict,
    selectedBank,
    matchMyCards,
    nearbyOnly,
    userLatitude,
    userLongitude,
    isMapView,
    sortBy,
  ];
}

class ExploreError extends ExploreState {
  final String message;
  ExploreError({required this.message});
  @override
  List<Object?> get props => [message];
}
