import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/enums/offer_type.dart';
import '../../../../domain/entities/bank_offer.dart';

abstract class HomeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<BankOffer> allOffers;
  final List<BankOffer> featuredOffers;
  final List<BankOffer> nearbyOffers;
  final List<Category> categories;
  final List<BankOffer> recentlyViewed;
  final OfferType selectedOfferType;

  HomeLoaded({
    required this.allOffers,
    required this.featuredOffers,
    required this.nearbyOffers,
    required this.categories,
    required this.recentlyViewed,
    required this.selectedOfferType,
  });

  HomeLoaded copyWith({
    List<BankOffer>? allOffers,
    List<BankOffer>? featuredOffers,
    List<BankOffer>? nearbyOffers,
    List<Category>? categories,
    List<BankOffer>? recentlyViewed,
    OfferType? selectedOfferType,
  }) {
    return HomeLoaded(
      allOffers: allOffers ?? this.allOffers,
      featuredOffers: featuredOffers ?? this.featuredOffers,
      nearbyOffers: nearbyOffers ?? this.nearbyOffers,
      categories: categories ?? this.categories,
      recentlyViewed: recentlyViewed ?? this.recentlyViewed,
      selectedOfferType: selectedOfferType ?? this.selectedOfferType,
    );
  }

  @override
  List<Object?> get props => [
    allOffers,
    featuredOffers,
    nearbyOffers,
    categories,
    recentlyViewed,
    selectedOfferType,
  ];
}

class HomeError extends HomeState {
  final String message;
  HomeError({required this.message});
  @override
  List<Object?> get props => [message];
}

class Category extends Equatable {
  final String name;
  final int count;
  final IconData icon;

  Category({required this.name, required this.count, required this.icon});

  @override
  List<Object?> get props => [name, count, icon];
}
