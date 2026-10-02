import '../repositories/offer_repository.dart';

class GetNearbyOffers {
  final OfferRepository repository;

  GetNearbyOffers(this.repository);

  Future<List<dynamic>> call({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    return await repository.getNearbyOffers(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }
}
