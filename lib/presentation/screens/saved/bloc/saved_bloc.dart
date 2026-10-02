import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/user_repository.dart';
import '../../../../domain/repositories/offer_repository.dart';
import '../../../../core/enums/offer_type.dart';
import 'saved_event.dart';
import 'saved_state.dart';
import '../../../../domain/entities/bank_offer.dart';

class SavedBloc extends Bloc<SavedEvent, SavedState> {
  final UserRepository userRepository;
  final OfferRepository offerRepository;

  SavedBloc({required this.userRepository, required this.offerRepository})
    : super(SavedInitial()) {
    on<LoadSavedOffers>(_onLoadSavedOffers);
    on<RefreshSavedOffers>(_onRefreshSavedOffers);
    on<UnsaveOffer>(_onUnsaveOffer);
    on<FilterByType>(_onFilterByType);
  }

  Future<void> _onLoadSavedOffers(
    LoadSavedOffers event,
    Emitter<SavedState> emit,
  ) async {
    emit(SavedLoading());

    try {
      final savedIds = await userRepository.getSavedOffers();
      final allOffers = await offerRepository.getAllOffers();

      final savedOffers =
          allOffers
              .whereType<BankOffer>()
              .where((offer) => savedIds.contains(offer.uniqueId))
              .toList();
      final resolvedIds = savedOffers.map((offer) => offer.uniqueId).toSet();
      for (final orphanedId in savedIds.where(
        (id) => !resolvedIds.contains(id),
      )) {
        await userRepository.unsaveOffer(orphanedId);
      }

      emit(SavedLoaded(offers: savedOffers));
    } catch (e) {
      emit(SavedError(message: 'saved_load_failed'));
    }
  }

  Future<void> _onRefreshSavedOffers(
    RefreshSavedOffers event,
    Emitter<SavedState> emit,
  ) async {
    add(LoadSavedOffers());
  }

  Future<void> _onUnsaveOffer(
    UnsaveOffer event,
    Emitter<SavedState> emit,
  ) async {
    try {
      await userRepository.unsaveOffer(event.offerId);

      if (state is SavedLoaded) {
        final currentState = state as SavedLoaded;
        final updatedOffers =
            currentState.offers
                .where((o) => o.uniqueId != event.offerId)
                .toList();
        emit(currentState.copyWith(offers: updatedOffers));
      }
    } catch (e) {
      emit(SavedError(message: 'saved_update_failed'));
    }
  }

  Future<void> _onFilterByType(
    FilterByType event,
    Emitter<SavedState> emit,
  ) async {
    if (state is SavedLoaded) {
      final currentState = state as SavedLoaded;

      if (event.type == null) {
        add(LoadSavedOffers());
        return;
      }

      emit(currentState.copyWith(selectedType: OfferType.bankOffer));
    }
  }
}
