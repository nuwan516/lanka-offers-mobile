import 'dart:math' as math;
import '../../domain/repositories/offer_repository.dart';
import '../../domain/entities/bank_offer.dart';
import '../../core/enums/offer_type.dart';
import '../datasources/remote/api_offers_datasource.dart';

class OfferRepositoryImpl implements OfferRepository {
  final ApiOffersDataSource _api;

  OfferRepositoryImpl() : _api = ApiOffersDataSource();

  @override
  Future<List<dynamic>> getAllOffers() => _api.fetchOffers();

  @override
  Future<List<dynamic>> getOffersByType(OfferType type) {
    // Only bank offers exist in the API; other types return empty.
    if (type == OfferType.bankOffer) return _api.fetchOffers();
    return Future.value([]);
  }

  @override
  Future<List<dynamic>> searchOffers(String query) =>
      _api.fetchOffers(search: query);

  @override
  Future<List<dynamic>> filterOffers({
    OfferType? type,
    String? category,
    String? district,
    double? maxDistance,
    double? latitude,
    double? longitude,
  }) async {
    // The API supports bank filter; distance/district filtering is done client-side.
    final offers = await _api.fetchOffers();

    var result = offers;

    if (type != null && type != OfferType.bankOffer) {
      return [];
    }

    if (category != null) {
      result = result
          .where((o) =>
              o.category.toLowerCase() == category.toLowerCase())
          .toList();
    }

    if (district != null && district.isNotEmpty) {
      result = result.where((o) {
        return o.locations.any(
          (loc) => loc.district.toLowerCase() == district.toLowerCase(),
        );
      }).toList();
    }

    if (maxDistance != null && latitude != null && longitude != null) {
      result = result.where((o) {
        final locs = o.locations;
        if (locs.isEmpty) return false;
        for (final loc in locs) {
          final dist = _distKm(latitude, longitude, loc.latitude, loc.longitude);
          if (dist <= maxDistance) return true;
        }
        return false;
      }).toList();
    }

    return result;
  }

  @override
  Future<List<dynamic>> getNearbyOffers({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    final offers = await _api.fetchOffers();
    return offers.where((o) {
      // Only offers with confirmed physical branch applicability can be nearby
      if (o.locationScope == 'ONLINE' ||
          o.locationScope == 'NATIONWIDE' ||
          o.locationScope == 'UNRESOLVED' ||
          o.locationScope == 'SELECTED_OUTLETS') {
        return false;
      }
      final locs = o.locations;
      if (locs.isEmpty) return false;
      return locs.any(
        (loc) => _distKm(latitude, longitude, loc.latitude, loc.longitude) <= radius,
      );
    }).toList();
  }

  @override
  Future<dynamic> getOfferById(String id) => _api.fetchOfferById(id);

  @override
  Future<List<dynamic>> getSimilarOffers(String offerId, OfferType type) async {
    final current = await getOfferById(offerId);
    if (current == null) return [];
    final all = await getAllOffers();
    return all
        .where((o) =>
            o.uniqueId != offerId &&
            o.category == (current as BankOffer).category)
        .take(5)
        .toList();
  }

  // Haversine distance in km
  double _distKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.pow(math.sin(dLon / 2), 2);
    return r * 2 * math.asin(math.sqrt(a.toDouble()));
  }
}
