import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/core/di/injection.dart';
import 'package:lanka_offers/domain/entities/location.dart';
import 'package:lanka_offers/presentation/common/widgets/offer_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
  });

  Future<void> pumpCard(
    WidgetTester tester,
    OfferCard card, {
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localized(
        SingleChildScrollView(child: card),
        locale: locale,
        textScale: textScale,
      ),
    );
    await tester.pump();
  }

  group('discount wording', () {
    testWidgets('a plain discount is "N% off", never "up to"', (tester) async {
      await pumpCard(
        tester,
        OfferCard(
          offer: testOffer(
            title: 'Tea Tang – 30% Off – Credit',
            discountRaw: '30',
          ),
        ),
      );

      expect(find.text('30% off'), findsOneWidget);
      expect(find.textContaining('Up to'), findsNothing);
    });

    testWidgets('"up to" appears only when the bank\'s wording says so', (
      tester,
    ) async {
      await pumpCard(
        tester,
        OfferCard(
          offer: testOffer(
            title: 'Oak Ray – Up to 35% off – Credit',
            discountRaw: '35',
          ),
        ),
      );

      expect(find.text('Up to 35% off'), findsOneWidget);
    });

    testWidgets('an unrelated "up to" does not qualify the discount', (
      tester,
    ) async {
      await pumpCard(
        tester,
        OfferCard(
          offer: testOffer(
            title: 'Up to 12 months 0% installments at Foo',
            discountRaw: '20',
          ),
        ),
      );

      expect(find.text('20% off'), findsOneWidget);
      expect(find.text('Up to 20% off'), findsNothing);
    });

    testWidgets('an offer with no stated discount shows no invented benefit', (
      tester,
    ) async {
      await pumpCard(
        tester,
        OfferCard(offer: testOffer(title: 'VISA Offers', discountRaw: null)),
      );

      expect(find.textContaining('% off'), findsNothing);
      expect(find.textContaining('Up to'), findsNothing);
    });

    testWidgets('Sinhala and Tamil use their own grammar for the qualifier', (
      tester,
    ) async {
      final offer = testOffer(
        title: 'Oak Ray – Up to 35% off – Credit',
        discountRaw: '35',
      );

      await pumpCard(
        tester,
        OfferCard(offer: offer),
        locale: const Locale('si'),
      );
      expect(find.text('උපරිම 35% වට්ටමක්'), findsOneWidget);

      await pumpCard(
        tester,
        OfferCard(offer: offer),
        locale: const Locale('ta'),
      );
      expect(find.text('35% வரை தள்ளுபடி'), findsOneWidget);
    });
  });

  group('validity', () {
    testWidgets('an expired offer is labelled and dimmed, not hidden', (
      tester,
    ) async {
      await pumpCard(
        tester,
        OfferCard(
          offer: testOffer(
            validUntil: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ),
      );

      expect(find.text('Expired'), findsOneWidget);
    });

    testWidgets('offers without an end date say so instead of showing a date', (
      tester,
    ) async {
      await pumpCard(tester, OfferCard(offer: testOffer(noExpiry: true)));

      expect(find.text('No end date stated'), findsOneWidget);
      expect(find.textContaining('2099'), findsNothing);
    });

    testWidgets('a far-off end date is shown as a date, not a countdown', (
      tester,
    ) async {
      await pumpCard(
        tester,
        OfferCard(
          offer: testOffer(
            validUntil: DateTime.now().add(const Duration(days: 200)),
          ),
        ),
      );

      expect(find.textContaining('Valid until'), findsOneWidget);
      expect(find.textContaining('days left'), findsNothing);
    });

    testWidgets('the last week shows a countdown', (tester) async {
      await pumpCard(
        tester,
        OfferCard(
          offer: testOffer(
            validUntil: DateTime.now().add(const Duration(days: 3)),
          ),
        ),
      );

      expect(find.textContaining('days left'), findsOneWidget);
    });
  });

  group('bank and location identification', () {
    testWidgets('shows the canonical bank name, not the raw code', (
      tester,
    ) async {
      await pumpCard(tester, OfferCard(offer: testOffer(bankCode: 'hnb')));

      expect(find.text('Hatton National Bank'), findsOneWidget);
      expect(find.text('HNB'), findsOneWidget); // monogram only, no logo asset
    });

    testWidgets('online and island-wide offers are named as such', (
      tester,
    ) async {
      await pumpCard(
        tester,
        OfferCard(offer: testOffer(scope: 'ONLINE', locations: const [])),
      );
      expect(find.text('Online'), findsOneWidget);

      await pumpCard(
        tester,
        OfferCard(offer: testOffer(scope: 'NATIONWIDE', locations: const [])),
      );
      expect(find.text('Island-wide'), findsOneWidget);
    });

    testWidgets(
      'a confirmed branch shows its city; unresolved shows no location',
      (tester) async {
        await pumpCard(tester, OfferCard(offer: testOffer()));
        expect(find.text('Kandy'), findsOneWidget);

        await pumpCard(
          tester,
          OfferCard(offer: testOffer(scope: 'UNRESOLVED', locations: const [])),
        );
        expect(find.byIcon(Icons.place_outlined), findsNothing);
      },
    );

    testWidgets(
      'multiple confirmed branches are summarised, not silently dropped',
      (tester) async {
        // Real branches have street addresses; an address-less location would
        // (correctly) be treated as area-level.
        Location loc(String city) => Location(
          name: city,
          address: '12 Main Street, $city',
          district: city,
          city: city,
          latitude: 7,
          longitude: 80,
        );
        await pumpCard(
          tester,
          OfferCard(
            offer: testOffer(
              scope: 'MULTIPLE_BRANCHES',
              locations: [loc('Kandy'), loc('Galle'), loc('Colombo')],
            ),
          ),
        );

        expect(find.text('Kandy +2'), findsOneWidget);
      },
    );

    testWidgets('nearby results show distance in metres under 1 km', (
      tester,
    ) async {
      await pumpCard(tester, OfferCard(offer: testOffer(distanceKm: 0.4)));
      expect(find.text('400 m'), findsOneWidget);

      await pumpCard(tester, OfferCard(offer: testOffer(distanceKm: 4.26)));
      expect(find.text('4.3 km'), findsOneWidget);
    });
  });

  group('layout under localization, long text and large type', () {
    const longTitle =
        'Lunch and Dinner at the Dining Room restaurant (At Cinnamon Lakeside Colombo) – Up to 25% off on selected set menus and beverages – Credit';
    final long = testOffer(
      merchant: 'The Dining Room at Cinnamon Lakeside Colombo International',
      title: longTitle,
      discountRaw: '25',
    );

    for (final locale in ['en', 'si', 'ta']) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets('320px wide, $locale, text ×$scale: no overflow', (
          tester,
        ) async {
          await pumpCard(
            tester,
            OfferCard(offer: long),
            locale: Locale(locale),
            textScale: scale,
            width: 320,
          );

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
