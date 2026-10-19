import '../entities/bank_summary.dart';
import '../repositories/offer_repository.dart';

class GetBanks {
  final OfferRepository repository;

  GetBanks(this.repository);

  Future<List<BankSummary>> call() => repository.getBanks();
}
