import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/core/di/injection.dart';
import 'package:lanka_offers/domain/entities/bank_summary.dart';
import 'package:lanka_offers/domain/repositories/offer_repository.dart';
import 'package:lanka_offers/presentation/common/widgets/skeletons.dart';
import 'package:lanka_offers/presentation/routes/tab_navigation.dart';
import 'package:lanka_offers/presentation/screens/explore/explore_screen.dart';
import 'package:lanka_offers/presentation/screens/home/home_screen.dart';
import 'package:lanka_offers/presentation/screens/main_navigation/main_navigation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

void main() {
  late FakeOfferRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TabNavigation.exploreRequest.value = null;
    await getIt.reset();
    await configureDependencies();
    repo = FakeOfferRepository(
      offers: [
        testOffer(
          id: 'h1',
          bankCode: 'hnb',
          merchant: 'Pizza Hut',
          discountRaw: 20,
        ),
        testOffer(
          id: 'b1',
          bankCode: 'boc',
          merchant: 'Keells',
          discountRaw: 35,
          title: 'Keells – Up to 35% off – Credit',
        ),
      ],
      banks: const [
        BankSummary(
          code: 'hnb',
          name: 'Hatton National Bank',
          activeOfferCount: 1,
        ),
        BankSummary(code: 'boc', name: 'Bank of Ceylon', activeOfferCount: 1),
        BankSummary(code: 'sampath', name: 'Sampath Bank', activeOfferCount: 0),
      ],
    );
    getIt.unregister<OfferRepository>();
    getIt.registerLazySingleton<OfferRepository>(() => repo);
  });

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(localized(const MainNavigationScreen()));
    // Not pumpAndSettle: the skeleton shimmer animates until data arrives.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('Home states', () {
    testWidgets('shows a skeleton while loading', (tester) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(localized(const MainNavigationScreen()));
      await tester.pump();

      expect(find.byType(SkeletonFeed), findsOneWidget);
    });

    testWidgets(
      'loaded: banks with live counts, and an honest zero-offer bank',
      (tester) async {
        await pumpShell(tester);

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.widgetWithText(BankTile, 'Hatton National Bank'), findsOneWidget);
        expect(find.widgetWithText(BankTile, 'Sampath Bank'), findsOneWidget);
        expect(find.text('No active offers yet'), findsWidgets);
        // The other seven banks have no reported count, so no count is invented.
        expect(find.text('0 active offers'), findsNothing);
      },
    );

    testWidgets('highest discounts lists offers with accurate wording', (
      tester,
    ) async {
      await pumpShell(tester);
      await tester.scrollUntilVisible(
        find.text('Up to 35% off'),
        400,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Up to 35% off'), findsOneWidget);
    });

    testWidgets(
      'an API failure shows an error with retry, and retry recovers',
      (tester) async {
        repo.failure = Exception('offline');
        await pumpShell(tester);

        expect(find.text('Couldn’t load offers'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        repo.failure = null;
        await tester.tap(find.text('Retry'));
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.text('Couldn’t load offers'), findsNothing);
        expect(find.widgetWithText(BankTile, 'Hatton National Bank'), findsOneWidget);
      },
    );

    testWidgets('no live offers shows the empty state, not blank sections', (
      tester,
    ) async {
      repo.offers = [];
      await pumpShell(tester);

      expect(find.text('No offers found'), findsOneWidget);
      expect(find.text('Highest discounts'), findsNothing);
    });
  });

  group('Home to Explore', () {
    testWidgets('tapping a bank opens Explore filtered to that bank', (
      tester,
    ) async {
      await pumpShell(tester);

      await tester.tap(find.widgetWithText(BankTile, 'Bank of Ceylon'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(repo.queries.last.bank, 'boc');
      // The active filter is visible and removable.
      expect(find.widgetWithText(InputChip, 'Bank of Ceylon'), findsOneWidget);
      expect(find.text('1 offers'), findsOneWidget);
    });

    testWidgets('a bank with no active offers is not tappable', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.widgetWithText(BankTile, 'Sampath Bank'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(ExploreScreen), findsNothing);
    });

    testWidgets('the nearby shortcut opens the Nearby section', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('Nearby Offers'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Use my location'), findsOneWidget);
      expect(find.text('Kandy'), findsOneWidget);
      expect(repo.nearbyCalls, isNotEmpty);
    });

    testWidgets('removing the bank chip reloads all offers', (tester) async {
      await pumpShell(tester);
      await tester.tap(find.widgetWithText(BankTile, 'Bank of Ceylon'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.tap(find.byTooltip('Delete'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(repo.queries.last.bank, isNull);
      expect(find.text('2 offers'), findsOneWidget);
    });
  });

  group('Explore sections', () {
    testWidgets(
      'Banks lists all ten supported banks and never hides a zero-offer bank',
      (tester) async {
        await pumpShell(tester);
        await tester.tap(find.text('Explore'));
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.tap(find.text('Banks'));
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        for (final name in [
          'Hatton National Bank',
          'Bank of Ceylon',
          "People's Bank",
          'National Savings Bank',
          'Sampath Bank',
          'Seylan Bank',
          'NDB Bank',
          'DFCC Bank',
          'Pan Asia Bank',
          'Commercial Bank',
        ]) {
          await tester.scrollUntilVisible(
            find.text(name),
            200,
            scrollable: find.byType(Scrollable).last,
          );
          expect(find.text(name), findsOneWidget, reason: name);
        }
      },
    );
  });
}
