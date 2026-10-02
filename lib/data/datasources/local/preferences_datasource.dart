import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';

class PreferencesDataSource {
  final SharedPreferences _prefs;

  PreferencesDataSource(this._prefs);

  Future<bool> isOnboardingCompleted() async {
    return _prefs.getBool(StorageKeys.onboardingCompleted) ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(StorageKeys.onboardingCompleted, completed);
  }

  Future<String?> getUserLocation() async {
    return _prefs.getString(StorageKeys.userLocation);
  }

  Future<void> setUserLocation(String location) async {
    await _prefs.setString(StorageKeys.userLocation, location);
  }
}
