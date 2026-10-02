import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/core/di/injection.dart';
import 'package:lanka_offers/core/localization/app_localizations.dart';
import 'package:lanka_offers/core/services/language_service.dart';
import 'package:lanka_offers/domain/entities/user_preferences.dart';
import 'package:lanka_offers/domain/repositories/user_repository.dart';
import 'package:lanka_offers/presentation/screens/main_navigation/main_navigation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
  });

  testWidgets('Phase 1 navigation has exactly four bank-offer destinations', (
    tester,
  ) async {
    await tester.pumpWidget(_localized(const MainNavigationScreen()));
    await tester.pump();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    final navigation = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navigation.items, hasLength(4));
    expect(navigation.items.map((item) => item.label), [
      'Home',
      'Explore',
      'Saved',
      'Settings',
    ]);
    expect(find.text('Events'), findsNothing);
    expect(find.text('Profile'), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Settings'));
    await tester.pump();
  });

  test('bank and card preferences use structured JSON persistence', () async {
    final repository = getIt<UserRepository>();
    final preferences = UserPreferences(
      selectedBanks: const ['HNB'],
      cardTypes: const ['Credit card'],
      cardNetworks: const ['Visa'],
      preferredCategories: const ['Dining'],
      preferredDistricts: const ['Colombo'],
      preferredRadiusKm: 10,
      savedCards: const [],
      notificationsEnabled: false,
    );

    await repository.savePreferences(preferences);
    final restored = await repository.getPreferences();

    expect(restored.selectedBanks, ['HNB']);
    expect(restored.cardTypes, ['Credit card']);
    expect(restored.cardNetworks, ['Visa']);
    final raw = getIt<SharedPreferences>().getString('preferences');
    expect(raw, contains('"selectedBanks"'));
    expect(raw, isNot(contains('Instance of')));
  });
}

Widget _localized(Widget child) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: LanguageService.supportedLocales,
  home: child,
);
