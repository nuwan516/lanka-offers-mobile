import '../../core/enums/offer_type.dart';

abstract class OfferRepository {
  Future<List<dynamic>> getAllOffers();
  Future<List<dynamic>> getOffersByType(OfferType type);
  Future<List<dynamic>> searchOffers(String query);
  Future<List<dynamic>> filterOffers({
    OfferType? type,
    String? category,
    String? district,
    double? maxDistance,
    double? latitude,
    double? longitude,
  });
  Future<List<dynamic>> getNearbyOffers({
    required double latitude,
    required double longitude,
    required double radius,
  });
  Future<dynamic> getOfferById(String id);
  Future<List<dynamic>> getSimilarOffers(String offerId, OfferType type);
}
