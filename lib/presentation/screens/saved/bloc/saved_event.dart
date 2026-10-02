import 'package:equatable/equatable.dart';
import '../../../../core/enums/offer_type.dart';

abstract class SavedEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSavedOffers extends SavedEvent {}

class RefreshSavedOffers extends SavedEvent {}

class UnsaveOffer extends SavedEvent {
  final String offerId;

  UnsaveOffer(this.offerId);

  @override
  List<Object?> get props => [offerId];
}

class FilterByType extends SavedEvent {
  final OfferType? type;

  FilterByType(this.type);

  @override
  List<Object?> get props => [type];
}
