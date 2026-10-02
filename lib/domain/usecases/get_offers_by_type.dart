import '../repositories/offer_repository.dart';
import '../../core/enums/offer_type.dart';

class GetOffersByType {
  final OfferRepository repository;

  GetOffersByType(this.repository);

  Future<List<dynamic>> call(OfferType type) async {
    return await repository.getOffersByType(type);
  }
}
