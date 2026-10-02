enum OfferType { bankOffer, shopOffer, promotion, event }

extension OfferTypeExtension on OfferType {
  String get displayName {
    switch (this) {
      case OfferType.bankOffer:
        return 'Bank Offers';
      case OfferType.shopOffer:
        return 'Shop Offers';
      case OfferType.promotion:
        return 'Promotions';
      case OfferType.event:
        return 'Events';
    }
  }
}
