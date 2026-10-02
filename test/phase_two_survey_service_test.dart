import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/core/services/phase_two_survey_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('survey becomes eligible after three distinct open days', () async {
    SharedPreferences.setMockInitialValues({});
    final service = PhaseTwoSurveyService(
      await SharedPreferences.getInstance(),
    );
    await service.recordAppOpen(DateTime(2026, 7, 1));
    await service.recordAppOpen(DateTime(2026, 7, 2));
    await service.recordAppOpen(DateTime(2026, 7, 3));
    expect(await service.isEligible(savedCount: 0), isTrue);
  });

  test('survey opt-out persists and prevents future eligibility', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = PhaseTwoSurveyService(preferences);
    await service.dismiss(optOut: true);
    expect(service.state.optedOut, isTrue);
    expect(await service.isEligible(savedCount: 10), isFalse);
  });
}
