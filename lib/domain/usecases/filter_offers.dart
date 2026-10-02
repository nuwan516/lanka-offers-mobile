import '../repositories/offer_repository.dart';
import '../../core/enums/offer_type.dart';

class FilterOffers {
  final OfferRepository repository;

  FilterOffers(this.repository);

  Future<List<dynamic>> call({
    OfferType? type,
    String? category,
    String? district,
    double? maxDistance,
    double? latitude,
    double? longitude,
  }) async {
    return await repository.filterOffers(
      type: type,
      category: category,
      district: district,
      maxDistance: maxDistance,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
