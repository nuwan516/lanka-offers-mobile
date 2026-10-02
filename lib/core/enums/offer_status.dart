enum OfferStatus { active, expired, upcoming, cancelled }

extension OfferStatusExtension on OfferStatus {
  String get displayName {
    switch (this) {
      case OfferStatus.active:
        return 'Active';
      case OfferStatus.expired:
        return 'Expired';
      case OfferStatus.upcoming:
        return 'Upcoming';
      case OfferStatus.cancelled:
        return 'Cancelled';
    }
  }
}
