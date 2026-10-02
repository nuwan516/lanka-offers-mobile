import 'package:equatable/equatable.dart';
import '../../../../core/enums/offer_type.dart';

abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {}

class RefreshHomeData extends HomeEvent {}

class ChangeOfferType extends HomeEvent {
  final OfferType offerType;

  ChangeOfferType(this.offerType);

  @override
  List<Object?> get props => [offerType];
}
