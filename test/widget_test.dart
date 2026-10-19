import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/core/di/injection.dart';
import 'package:lanka_offers/core/localization/app_localizations.dart';
import 'package:lanka_offers/core/services/language_service.dart';
import 'package:lanka_offers/domain/entities/user_preferences.dart';
import 'package:lanka_offers/domain/repositories/user_repository.dart';
import 'package:lanka_offers/presentation/screens/home/home_screen.dart';
import 'package:lanka_offers/presentation/screens/profile/profile_screen.dart';
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

    // Verify exactly four navigation destination labels are rendered
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify unwanted or legacy destinations are absent
    expect(find.text('Events'), findsNothing);
    expect(find.text('Profile'), findsNothing);

    // Initial destination is HomeScreen
    expect(find.byType(HomeScreen), findsOneWidget);

    // Switch to Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pump();

    // Verify active screen switched to ProfileScreen
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
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
