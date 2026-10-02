import 'base_offer.dart';
import 'discount.dart';
import 'restrictions.dart';
import '../../core/enums/shop_type.dart';

class ShopOffer extends BaseOffer {
  final String shopName;
  final ShopType shopType;
  final Discount discount;
  final String? promoCode;
  final double? minPurchaseAmount;
  final String? hoursOfOperation;
  final bool verified;
  final DateTime? verificationDate;
  final Restrictions? restrictions;

  ShopOffer({
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
    required this.shopName,
    required this.shopType,
    required this.discount,
    this.promoCode,
    this.minPurchaseAmount,
    this.hoursOfOperation,
    required this.verified,
    this.verificationDate,
    this.restrictions,
  });

  @override
  String get providerName => shopName;

  String getDisplayValue() {
    if (discount.type == 'percentage') {
      return '${discount.value}% OFF';
    } else if (discount.type == 'amount') {
      return 'Rs. ${discount.value} OFF';
    } else if (discount.type == 'bogo') {
      return discount.value.toString();
    } else {
      return discount.description;
    }
  }

  @override
  List<Object?> get props => [
    ...super.props,
    shopName,
    shopType,
    discount,
    promoCode,
    minPurchaseAmount,
    hoursOfOperation,
    verified,
    verificationDate,
    restrictions,
  ];
}
