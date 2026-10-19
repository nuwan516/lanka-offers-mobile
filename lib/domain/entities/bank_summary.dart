import 'package:equatable/equatable.dart';

/// One entry of the public `GET /api/banks` directory.
///
/// [activeOfferCount] is null when the API did not report it, which is
/// different from 0 ("reported, and there are none").
class BankSummary extends Equatable {
  final String code;
  final String name;
  final int? activeOfferCount;
  final List<String> cardTypesSupported;

  const BankSummary({
    required this.code,
    required this.name,
    this.activeOfferCount,
    this.cardTypesSupported = const [],
  });

  @override
  List<Object?> get props => [code, name, activeOfferCount, cardTypesSupported];
}
