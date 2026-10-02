import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

class SurveyState {
  const SurveyState({
    this.shown = false,
    this.dismissed = false,
    this.optedOut = false,
    this.response,
    this.area,
    this.submittedAt,
    this.appVersion,
  });

  final bool shown;
  final bool dismissed;
  final bool optedOut;
  final String? response;
  final String? area;
  final DateTime? submittedAt;
  final String? appVersion;

  bool get submitted => response != null;

  Map<String, Object?> toJson() => {
    'shown': shown,
    'dismissed': dismissed,
    'optedOut': optedOut,
    'response': response,
    'area': area,
    'submittedAt': submittedAt?.toIso8601String(),
    'appVersion': appVersion,
  };

  factory SurveyState.fromJson(Map<String, dynamic> json) => SurveyState(
    shown: json['shown'] as bool? ?? false,
    dismissed: json['dismissed'] as bool? ?? false,
    optedOut: json['optedOut'] as bool? ?? false,
    response: json['response'] as String?,
    area: json['area'] as String?,
    submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? ''),
    appVersion: json['appVersion'] as String?,
  );
}

class PhaseTwoSurveyService {
  PhaseTwoSurveyService(this._preferences);

  final SharedPreferences _preferences;

  SurveyState get state {
    final value = _preferences.getString(StorageKeys.surveyState);
    if (value == null) return const SurveyState();
    try {
      return SurveyState.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } on FormatException {
      return const SurveyState();
    }
  }

  Future<void> recordAppOpen(DateTime now) async {
    final days = _preferences.getStringList(StorageKeys.appOpenDays) ?? [];
    final day = '${now.year}-${now.month}-${now.day}';
    if (!days.contains(day)) {
      days.add(day);
      await _preferences.setStringList(StorageKeys.appOpenDays, days);
    }
  }

  Future<void> recordOfferViewed() => _preferences.setInt(
    StorageKeys.viewedOfferCount,
    (_preferences.getInt(StorageKeys.viewedOfferCount) ?? 0) + 1,
  );

  Future<bool> isEligible({required int savedCount}) async {
    final current = state;
    if (current.optedOut || current.submitted || current.shown) return false;
    final openDays =
        _preferences.getStringList(StorageKeys.appOpenDays)?.length ?? 0;
    final views = _preferences.getInt(StorageKeys.viewedOfferCount) ?? 0;
    return openDays >= 3 || views >= 8 || savedCount >= 2;
  }

  Future<void> dismiss({required bool optOut}) =>
      _write(SurveyState(shown: true, dismissed: true, optedOut: optOut));

  Future<void> submit({required String response, String? area}) => _write(
    SurveyState(
      shown: true,
      response: response,
      area: area,
      submittedAt: DateTime.now(),
      appVersion: '1.0.0',
    ),
  );

  Future<void> _write(SurveyState value) => _preferences.setString(
    StorageKeys.surveyState,
    jsonEncode(value.toJson()),
  );
}
