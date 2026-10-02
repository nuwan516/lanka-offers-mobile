import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';

class LanguageService {
  final SharedPreferences _prefs;

  LanguageService(this._prefs);

  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('si', ''), // Sinhala
    Locale('ta', ''), // Tamil
  ];

  Future<Locale> getSavedLocale() async {
    final languageCode = _prefs.getString(StorageKeys.selectedLanguage) ?? 'en';
    return Locale(languageCode, '');
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(StorageKeys.selectedLanguage, locale.languageCode);
  }

  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'si':
        return 'සිංහල'; // Sinhala
      case 'ta':
        return 'தமிழ்'; // Tamil
      default:
        return 'English';
    }
  }

  String getLanguageNativeName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'si':
        return 'සිංහල';
      case 'ta':
        return 'தமிழ்';
      default:
        return 'English';
    }
  }
}
