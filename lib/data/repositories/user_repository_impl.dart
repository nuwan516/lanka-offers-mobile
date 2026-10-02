import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/repositories/user_repository.dart';
import '../../domain/entities/user_preferences.dart';
import '../../core/constants/storage_keys.dart';

class UserRepositoryImpl implements UserRepository {
  final SharedPreferences _prefs;

  UserRepositoryImpl(this._prefs);

  @override
  Future<void> saveOffer(String offerId) async {
    final saved = await getSavedOffers();
    if (!saved.contains(offerId)) {
      saved.add(offerId);
      await _prefs.setStringList(StorageKeys.savedOffers, saved);
    }
  }

  @override
  Future<void> unsaveOffer(String offerId) async {
    final saved = await getSavedOffers();
    saved.remove(offerId);
    await _prefs.setStringList(StorageKeys.savedOffers, saved);
  }

  @override
  Future<List<String>> getSavedOffers() async {
    return _prefs.getStringList(StorageKeys.savedOffers) ?? <String>[];
  }

  @override
  Future<bool> isOfferSaved(String offerId) async {
    final saved = await getSavedOffers();
    return saved.contains(offerId);
  }

  @override
  Future<void> savePreferences(UserPreferences preferences) async {
    await _prefs.setString(
      StorageKeys.preferences,
      jsonEncode(preferences.toJson()),
    );
  }

  @override
  Future<UserPreferences> getPreferences() async {
    final stored = _prefs.getString(StorageKeys.preferences);
    if (stored != null) {
      try {
        return UserPreferences.fromJson(
          jsonDecode(stored) as Map<String, dynamic>,
        );
      } on FormatException {
        // Ignore legacy Dart toString() values and return safe defaults.
      }
    }
    return UserPreferences(
      preferredCategories: [],
      preferredDistricts: [],
      savedCards: [],
      notificationsEnabled: false,
    );
  }

  @override
  Future<void> addRecentSearch(String query) async {
    final recent = await getRecentSearches();
    recent.remove(query); // Remove if exists
    recent.insert(0, query); // Add to front
    if (recent.length > 10) {
      recent.removeLast(); // Keep only last 10
    }
    await _prefs.setStringList(StorageKeys.recentSearches, recent);
  }

  @override
  Future<List<String>> getRecentSearches() async {
    return _prefs.getStringList(StorageKeys.recentSearches) ?? <String>[];
  }

  @override
  Future<void> addRecentlyViewed(String offerId) async {
    final viewed = await getRecentlyViewed();
    viewed.remove(offerId);
    viewed.insert(0, offerId);
    if (viewed.length > 20) {
      viewed.removeLast();
    }
    await _prefs.setStringList(StorageKeys.recentlyViewed, viewed);
  }

  @override
  Future<List<String>> getRecentlyViewed() async {
    return _prefs.getStringList(StorageKeys.recentlyViewed) ?? <String>[];
  }
}
