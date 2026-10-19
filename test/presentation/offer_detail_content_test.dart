import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/domain/entities/card_eligibility.dart';
import 'package:lanka_offers/presentation/screens/offer_detail/offer_detail_screen.dart';

import '../support/fakes.dart';

void main() {
  Future<void> pumpContent(
    WidgetTester tester,
    OfferDetailContent content, {
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      localized(content, locale: locale, textScale: textScale),
    );
    await tester.pump();
  }

  OfferDetailContent detail(offerArgs, {DateTime? now}) => OfferDetailContent(
    offer: offerArgs,
    isSaved: false,
    onToggleSaved: () {},
    now: now,
  );

  group('discount and caveats', () {
    testWidgets(
      'shows the discount with the bank\'s wording and the caveat note',
      (tester) async {
        await pumpContent(
          tester,
          detail(
            testOffer(
              title: 'Oak Ray – Up to 35% off – Credit',
              discountRaw: '35',
            ),
          ),
        );

        expect(find.text('Up to 35% off'), findsOneWidget);
        expect(
          find.textContaining(
            'Caps, minimum spend and eligible cards are in the terms',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('minimum spend, caps and transaction limits stay separate', () {
    testWidgets('structured transaction limits keep their exact names', (
      tester,
    ) async {
      await pumpContent(
        tester,
        detail(testOffer(minTransaction: 5000, maxTransaction: 50000)),
      );

      expect(find.text('Minimum transaction'), findsOneWidget);
      expect(find.text('LKR 5,000'), findsOneWidget);
      expect(find.text('Maximum transaction value'), findsOneWidget);
      expect(find.text('LKR 50,000'), findsOneWidget);
      // A transaction limit is never presented as a discount cap.
      expect(find.textContaining('Maximum discount'), findsNothing);
    });

    testWidgets('limits the source did not give are not shown', (tester) async {
      await pumpContent(tester, detail(testOffer()));

      expect(find.text('Minimum transaction'), findsNothing);
      expect(find.text('Maximum transaction value'), findsNothing);
    });

    testWidgets(
      'cap and minimum-bill statements are quoted verbatim from the terms',
      (tester) async {
        const terms = [
          'Minimum bill value of Rs.25,000/-',
          'Maximum discount Rs. 10,000 per transaction',
          'Prior reservation is mandatory',
        ];
        await pumpContent(tester, detail(testOffer(generalTerms: terms)));

        expect(find.text('Stated in the bank’s terms'), findsOneWidget);
        expect(
          find.text('“Minimum bill value of Rs.25,000/-”'),
          findsOneWidget,
        );
        expect(
          find.text('“Maximum discount Rs. 10,000 per transaction”'),
          findsOneWidget,
        );
        // Full terms are still listed unquoted.
        expect(find.text('Prior reservation is mandatory'), findsOneWidget);
      },
    );

    testWidgets('no cap statement in the terms means no cap is shown', (
      tester,
    ) async {
      await pumpContent(
        tester,
        detail(
          testOffer(generalTerms: const ['Prior reservation is mandatory']),
        ),
      );

      expect(find.text('Stated in the bank’s terms'), findsNothing);
    });
  });

  group('card eligibility', () {
    testWidgets('lists what the bank named', (tester) async {
      await pumpContent(
        tester,
        detail(
          testOffer(
            eligibility: const CardEligibility(
              cardTypes: ['Credit Card'],
              networks: ['Visa'],
              includedCards: ['Visa Signature'],
              excludedCards: ['Corporate Cards'],
            ),
          ),
        ),
      );

      expect(find.text('Visa Signature'), findsOneWidget);
      expect(find.text('Credit Card'), findsOneWidget);
      expect(find.text('Visa'), findsOneWidget);
      expect(find.text('✕ Corporate Cards'), findsOneWidget);
    });

    testWidgets('says so when the bank did not specify eligible cards', (
      tester,
    ) async {
      await pumpContent(
        tester,
        // No card data at all: not even a card-type token.
        detail(
          testOffer(
            eligibility: const CardEligibility(),
            applicableCards: const [],
          ),
        ),
      );

      expect(
        find.text('The bank did not specify which cards qualify.'),
        findsOneWidget,
      );
    });
  });

  group('validity states', () {
    testWidgets('an expired offer shows a clear notice', (tester) async {
      await pumpContent(
        tester,
        detail(
          testOffer(
            validUntil: DateTime.now().subtract(const Duration(days: 4)),
          ),
        ),
      );

      expect(find.text('Expired'), findsOneWidget);
      expect(
        find.text('This offer has expired and may no longer be honoured.'),
        findsOneWidget,
      );
    });

    testWidgets('valid through the whole last day (Sri Lanka time)', (
      tester,
    ) async {
      // valid_to is Oct 31; at 22:00 Sri Lanka time that evening it is still valid.
      final validUntil = DateTime.utc(2026, 10, 31);
      final eveningInColombo = DateTime.utc(
        2026,
        10,
        31,
        16,
        30,
      ); // 22:00 +05:30

      await pumpContent(
        tester,
        detail(testOffer(validUntil: validUntil), now: eveningInColombo),
      );

      expect(find.text('Last day today'), findsOneWidget);
      expect(find.text('Expired'), findsNothing);
    });

    testWidgets('the next morning in Sri Lanka it is expired', (tester) async {
      await pumpContent(
        tester,
        detail(
          testOffer(validUntil: DateTime.utc(2026, 10, 31)),
          now: DateTime.utc(2026, 10, 31, 19, 0), // 00:30 on Nov 1, +05:30
        ),
      );

      expect(find.text('Expired'), findsOneWidget);
    });
  });

  group('where it applies', () {
    testWidgets('online offers state that and show no map pin or directions', (
      tester,
    ) async {
      await pumpContent(
        tester,
        detail(testOffer(scope: 'ONLINE', locations: const [])),
      );

      expect(find.text('Available online'), findsOneWidget);
      expect(find.byIcon(Icons.directions_outlined), findsNothing);
    });

    testWidgets('island-wide offers do not claim every outlet takes part', (
      tester,
    ) async {
      await pumpContent(
        tester,
        detail(testOffer(scope: 'NATIONWIDE', locations: const [])),
      );

      expect(find.text('Available island-wide'), findsOneWidget);
      expect(find.textContaining('all '), findsNothing);
    });

    testWidgets('unresolved location is stated, not guessed', (tester) async {
      await pumpContent(
        tester,
        detail(testOffer(scope: 'UNRESOLVED', locations: const [])),
      );

      expect(find.text('Location not specified'), findsOneWidget);
    });

    testWidgets('a confirmed branch is listed with directions', (tester) async {
      await pumpContent(tester, detail(testOffer()));

      expect(find.text('Confirmed branch location'), findsOneWidget);
      expect(find.text('Kandy City Centre'), findsOneWidget);
      expect(find.byIcon(Icons.directions_outlined), findsOneWidget);
    });
  });

  group('source link', () {
    testWidgets('an https source gets a link to the original offer', (
      tester,
    ) async {
      await pumpContent(
        tester,
        detail(testOffer(sourceUrl: 'https://www.hnb.lk/offers/x')),
      );

      expect(find.text('View original bank offer'), findsOneWidget);
    });

    testWidgets('non-http(s) sources are ignored', (tester) async {
      await pumpContent(
        tester,
        detail(testOffer(sourceUrl: 'javascript:alert(1)')),
      );

      expect(find.text('View original bank offer'), findsNothing);
    });
  });

  group('localization and layout', () {
    for (final locale in ['en', 'si', 'ta']) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('320px, $locale, text ×$scale: no overflow', (
          tester,
        ) async {
          await pumpContent(
            tester,
            detail(
              testOffer(
                merchant:
                    'The Dining Room at Cinnamon Lakeside Colombo International',
                title:
                    'Lunch and Dinner at the Dining Room restaurant – Up to 25% off on selected set menus – Credit',
                discountRaw: '25',
                minTransaction: 5000,
                maxTransaction: 50000,
                generalTerms: const [
                  'Minimum bill value of Rs.25,000/-',
                  'Maximum discount Rs. 10,000 per transaction',
                  'Offer valid for dine-in only, subject to availability and prior reservation',
                ],
                sourceUrl: 'https://www.hnb.lk/offers/x',
                eligibility: const CardEligibility(
                  cardTypes: ['Credit Card'],
                  networks: ['Visa', 'Mastercard'],
                  includedCards: ['Visa Signature', 'World Mastercard'],
                ),
              ),
            ),
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
