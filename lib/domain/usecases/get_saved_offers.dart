import '../repositories/user_repository.dart';

class GetSavedOffers {
  final UserRepository repository;

  GetSavedOffers(this.repository);

  Future<List<String>> call() async {
    return await repository.getSavedOffers();
  }
}
