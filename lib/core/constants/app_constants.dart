class AppConstants {
  // App Info
  static const String appName = 'Lanka Offers';
  static const String appVersion = '1.0.0';

  // API — Android emulator uses 10.0.2.2 to reach the host; everything else
  // uses localhost. The ApiOffersDataSource switches automatically via Platform.
  // If running on a physical device, set this to the host machine's LAN IP.
  static const String apiPortHint = '3001';

  // Default Location (Colombo)
  static const double defaultLatitude = 6.9271;
  static const double defaultLongitude = 79.8612;
  static const String defaultCity = 'Colombo';
  static const String defaultDistrict = 'Colombo';

  // Search
  static const int maxRecentSearches = 10;
  static const int minSearchLength = 2;

  // Pagination
  static const int itemsPerPage = 20;

  // Cache
  static const Duration cacheExpiry = Duration(hours: 24);

  // Distance
  static const double defaultRadiusKm = 10.0;
  static const double maxRadiusKm = 50.0;
}
