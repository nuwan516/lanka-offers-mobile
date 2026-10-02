import '../repositories/user_repository.dart';

class UnsaveOffer {
  final UserRepository repository;

  UnsaveOffer(this.repository);

  Future<void> call(String offerId) async {
    return await repository.unsaveOffer(offerId);
  }
}
