import '../entities/user_preferences.dart';

abstract class UserRepository {
  Future<void> saveOffer(String offerId);
  Future<void> unsaveOffer(String offerId);
  Future<List<String>> getSavedOffers();
  Future<bool> isOfferSaved(String offerId);
  Future<void> savePreferences(UserPreferences preferences);
  Future<UserPreferences> getPreferences();
  Future<void> addRecentSearch(String query);
  Future<List<String>> getRecentSearches();
  Future<void> addRecentlyViewed(String offerId);
  Future<List<String>> getRecentlyViewed();
}
