import '../../core/enums/offer_type.dart';
import '../entities/bank_summary.dart';

abstract class OfferRepository {
  Future<List<dynamic>> getAllOffers();
  Future<List<dynamic>> getOffersByBank(String bankCode);

  /// All offers matching the server-side filters. [locationScope] is an API
  /// scope such as `ONLINE` or `NATIONWIDE`.
  Future<List<dynamic>> queryOffers({
    String? bank,
    String? category,
    String? locationScope,
  });
  Future<List<BankSummary>> getBanks();
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
