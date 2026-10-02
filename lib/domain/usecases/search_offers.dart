import '../repositories/offer_repository.dart';

class SearchOffers {
  final OfferRepository repository;

  SearchOffers(this.repository);

  Future<List<dynamic>> call(String query) async {
    return await repository.searchOffers(query);
  }
}
