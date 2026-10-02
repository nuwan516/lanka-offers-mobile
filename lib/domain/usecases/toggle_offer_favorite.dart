import '../repositories/user_repository.dart';

class ToggleOfferFavorite {
  final UserRepository repository;

  ToggleOfferFavorite(this.repository);

  Future<bool> call(String offerId) async {
    final isSaved = await repository.isOfferSaved(offerId);
    if (isSaved) {
      await repository.unsaveOffer(offerId);
      return false;
    } else {
      await repository.saveOffer(offerId);
      return true;
    }
  }
}
