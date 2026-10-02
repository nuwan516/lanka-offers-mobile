enum CoverageType { islandWide, district, city, specificLocation }

extension CoverageTypeExtension on CoverageType {
  String get displayName {
    switch (this) {
      case CoverageType.islandWide:
        return 'Island Wide';
      case CoverageType.district:
        return 'District';
      case CoverageType.city:
        return 'City';
      case CoverageType.specificLocation:
        return 'Specific Location';
    }
  }
}
