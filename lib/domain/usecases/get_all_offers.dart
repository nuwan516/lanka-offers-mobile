import '../repositories/offer_repository.dart';

class GetAllOffers {
  final OfferRepository repository;

  GetAllOffers(this.repository);

  Future<List<dynamic>> call() async {
    return await repository.getAllOffers();
  }
}
