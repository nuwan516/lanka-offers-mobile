import 'base_offer.dart';
import 'deal.dart';

class Promotion extends BaseOffer {
  @override
  final String providerName;
  final String promotionType; // 'flash_sale', 'limited_time', 'seasonal'
  final String urgencyLevel; // 'urgent', 'high', 'normal'
  final Deal deal;
  final String? stockStatus; // 'limited', 'available', 'sold_out'
  final int? unitsAvailable;
  final int? unitsSold;
  final int? flashDurationHours;
  final bool countdownEnabled;

  const Promotion({
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
    required this.providerName,
    required this.promotionType,
    required this.urgencyLevel,
    required this.deal,
    this.stockStatus,
    this.unitsAvailable,
    this.unitsSold,
    this.flashDurationHours,
    required this.countdownEnabled,
  });

  String getDisplayValue() {
    if (deal.type == 'discount') {
      return '${deal.value}% OFF';
    } else {
      return deal.description;
    }
  }

  @override
  List<Object?> get props => [
    ...super.props,
    providerName,
    promotionType,
    urgencyLevel,
    deal,
    stockStatus,
    unitsAvailable,
    unitsSold,
    flashDurationHours,
    countdownEnabled,
  ];
}
