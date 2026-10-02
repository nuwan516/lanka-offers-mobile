import 'package:equatable/equatable.dart';
import '../../../../core/enums/offer_type.dart';
import '../../../../domain/entities/bank_offer.dart';

abstract class SavedState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SavedInitial extends SavedState {}

class SavedLoading extends SavedState {}

class SavedLoaded extends SavedState {
  final List<BankOffer> offers;
  final OfferType? selectedType;

  SavedLoaded({required this.offers, this.selectedType});

  SavedLoaded copyWith({List<BankOffer>? offers, OfferType? selectedType}) {
    return SavedLoaded(
      offers: offers ?? this.offers,
      selectedType: selectedType ?? this.selectedType,
    );
  }

  @override
  List<Object?> get props => [offers, selectedType];
}

class SavedError extends SavedState {
  final String message;
  SavedError({required this.message});
  @override
  List<Object?> get props => [message];
}
