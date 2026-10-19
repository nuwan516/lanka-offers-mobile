import 'base_offer.dart';
import 'card_eligibility.dart';
import 'discount.dart';
import 'installment_plan.dart';
import 'restrictions.dart';

class BankOffer extends BaseOffer {
  final String bankName;
  final String? bankCode;
  final String? sourceUrl;
  final List<String> generalTerms;
  final String merchantName;
  final String? canonicalMerchant;
  final String? locationScope;
  final Discount? discount;
  final List<InstallmentPlan>? installmentPlans;
  final List<String> applicableCards;
  final CardEligibility? cardEligibility;
  final Restrictions? restrictions;
  final double? distanceKm;
  final String? merchantLocation;
  final String? terms;
  final double? minTransaction;
  final double? maxTransaction;

  const BankOffer({
    required super.uniqueId,
    required super.title,
    required super.description,
    required super.category,
    required super.subcategories,
    required super.locations,
    required super.validity,
    super.contact,
    required super.images,
    super.featuredImage,
    required super.quality,
    super.metrics,
    required this.bankName,
    this.bankCode,
    this.sourceUrl,
    this.generalTerms = const [],
    required this.merchantName,
    this.canonicalMerchant,
    this.locationScope,
    this.merchantLocation,
    this.terms,
    this.distanceKm,
    this.discount,
    this.installmentPlans,
    required this.applicableCards,
    this.cardEligibility,
    this.restrictions,
    this.minTransaction,
    this.maxTransaction,
  });

  @override
  String get providerName => bankName;

  String getDisplayValue() {
    if (discount != null) {
      if (discount!.type == 'percentage') {
        // Use description if the datasource already built it (e.g. "20% off").
        // Fall back to formatting the numeric value — use toStringAsFixed(0) so
        // whole numbers like 20.0 render as "20% OFF" not "20.0% OFF".
        if (discount!.description.isNotEmpty) {
          return discount!.description.toUpperCase();
        }
        final v = discount!.value;
        if (v is double) {
          final rounded =
              v == v.truncate() ? v.toInt().toString() : v.toStringAsFixed(1);
          return '$rounded% OFF';
        }
        return '${discount!.value}% OFF';
      } else if (discount!.type == 'amount') {
        final v = discount!.value;
        if (v is double) {
          final rounded =
              v == v.truncate() ? v.toInt().toString() : v.toStringAsFixed(2);
          return 'Rs. $rounded OFF';
        }
        return 'Rs. ${discount!.value} OFF';
      } else {
        // 'text' type: description is already the canonical wording
        // (e.g. "Up to 20%", "Buy 1 Get 1") — return verbatim.
        return discount!.description;
      }
    } else if (installmentPlans != null && installmentPlans!.isNotEmpty) {
      return installmentPlans!.first.description;
    }
    return 'Special Offer';
  }

  @override
  List<Object?> get props => [
    ...super.props,
    bankName,
    bankCode,
    sourceUrl,
    generalTerms,
    merchantName,
    canonicalMerchant,
    locationScope,
    merchantLocation,
    terms,
    distanceKm,
    discount,
    installmentPlans,
    applicableCards,
    cardEligibility,
    restrictions,
    minTransaction,
    maxTransaction,
  ];
}
