import '../repositories/user_repository.dart';

class SaveOffer {
  final UserRepository repository;

  SaveOffer(this.repository);

  Future<void> call(String offerId) async {
    return await repository.saveOffer(offerId);
  }
}
