enum ShopType {
  restaurant,
  retail,
  service,
  entertainment,
  healthcare,
  education,
}

extension ShopTypeExtension on ShopType {
  String get displayName {
    switch (this) {
      case ShopType.restaurant:
        return 'Restaurant';
      case ShopType.retail:
        return 'Retail';
      case ShopType.service:
        return 'Service';
      case ShopType.entertainment:
        return 'Entertainment';
      case ShopType.healthcare:
        return 'Healthcare';
      case ShopType.education:
        return 'Education';
    }
  }
}
