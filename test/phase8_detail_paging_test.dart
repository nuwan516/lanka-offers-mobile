import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/core/di/injection.dart';
import 'package:lanka_offers/core/localization/app_localizations.dart';
import 'package:lanka_offers/core/services/language_service.dart';
import 'package:lanka_offers/domain/entities/bank_offer.dart';
import 'package:lanka_offers/domain/entities/discount.dart';
import 'package:lanka_offers/domain/entities/location.dart';
import 'package:lanka_offers/domain/entities/validity_period.dart';
import 'package:lanka_offers/domain/entities/card_eligibility.dart';
import 'package:lanka_offers/domain/entities/quality_score.dart';
import 'package:lanka_offers/presentation/screens/offer_detail/offer_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

BankOffer _createTestOffer({
  required String id,
  required String title,
  required String merchantName,
  required String scope,
  List<Location>? locations,
}) {
  return BankOffer(
    uniqueId: id,
    title: title,
    description: 'Test description for $title',
    merchantName: merchantName,
    bankName: 'Hatton National Bank',
    category: 'Dining',
    subcategories: const [],
    images: const [],
    quality: QualityScore(confidenceScore: 0.9, grade: 'A'),
    discount: Discount(type: 'percentage', value: 20, description: '20% OFF'),
    validity: ValidityPeriod(
      validFrom: DateTime(2026, 10, 1),
      validUntil: DateTime(2026, 10, 31),
    ),
    locations: locations ?? [
      Location(
        name: 'Kandy City Centre Branch',
        address: '5 Sri Dalada Veediya, Kandy',
        latitude: 7.2906,
        longitude: 80.6337,
        district: 'Kandy',
        city: 'Kandy',
      ),
    ],
    locationScope: scope,
    applicableCards: const ['visa_signature', 'mastercard_world'],
    cardEligibility: const CardEligibility(
      cardTypes: ['Credit Card'],
      networks: ['Visa', 'Mastercard'],
      includedCards: ['Visa Signature', 'World Mastercard'],
    ),
    minTransaction: 5000,
    maxTransaction: 50000,
  );
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

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
  });

  group('Phase 8 — Offer Detail Horizontal Paging & Information Hierarchy', () {
    testWidgets('Renders offer details with full-screen PageView and position indicator', (tester) async {
      final offer1 = _createTestOffer(id: 'offer_1', title: 'Pizza Fest 20% Off', merchantName: 'Pizza Hut', scope: 'EXPLICIT_BRANCH');
      final offer2 = _createTestOffer(id: 'offer_2', title: 'Burger Weekend Deal', merchantName: 'Burger King', scope: 'MULTIPLE_BRANCHES');
      final offer3 = _createTestOffer(id: 'offer_3', title: 'Kottu Feast', merchantName: 'Pilawoos', scope: 'EXPLICIT_BRANCH');

      final contextOffers = [offer1, offer2, offer3];

      await tester.pumpWidget(
        _localized(
          OfferDetailScreen(
            offerId: 'offer_1',
            contextOffers: contextOffers,
            initialIndex: 0,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Offer 1 of 3 indicator
      expect(find.text('Offer 1 of 3'), findsOneWidget);
      expect(find.text('Pizza Hut'), findsOneWidget);
      expect(find.text('20% OFF'), findsOneWidget);
      expect(find.text('Pizza Fest 20% Off'), findsOneWidget);

      // Verify spend limits formatted with commas without any hardcoded text
      expect(find.text('LKR 5,000 – LKR 50,000'), findsOneWidget);

      // Verify confirmed branch is shown
      expect(find.text('Kandy City Centre Branch'), findsOneWidget);

      // Test horizontal swipe to next offer (Offer 2)
      final pageView = tester.widget<PageView>(find.byKey(const ValueKey('offer_detail_page_view')));
      pageView.controller!.jumpToPage(1);
      await tester.pumpAndSettle();

      expect(find.text('Offer 2 of 3'), findsOneWidget);
      expect(find.text('Burger King'), findsOneWidget);
      expect(find.text('Burger Weekend Deal'), findsOneWidget);

      // Test horizontal swipe to next offer (Offer 3)
      pageView.controller!.jumpToPage(2);
      await tester.pumpAndSettle();

      expect(find.text('Offer 3 of 3'), findsOneWidget);
      expect(find.text('Pilawoos'), findsOneWidget);

      // Test horizontal swipe backwards to Offer 2
      pageView.controller!.jumpToPage(1);
      await tester.pumpAndSettle();

      expect(find.text('Offer 2 of 3'), findsOneWidget);
      expect(find.text('Burger King'), findsOneWidget);
    });

    testWidgets('Truthful location scope presentation for ONLINE offer', (tester) async {
      final onlineOffer = _createTestOffer(id: 'online_1', title: 'Uber Eats 15% Off', merchantName: 'Uber Eats', scope: 'ONLINE', locations: []);

      await tester.pumpWidget(
        _localized(
          OfferDetailScreen(
            offerId: 'online_1',
            contextOffers: [onlineOffer],
            initialIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Online Promotion • Valid on website and mobile app'), findsOneWidget);
    });

    testWidgets('Truthful location scope presentation for NATIONWIDE offer', (tester) async {
      final nationwideOffer = _createTestOffer(id: 'nationwide_1', title: 'Keells Supermarket 20% Off', merchantName: 'Keells', scope: 'NATIONWIDE', locations: []);

      await tester.pumpWidget(
        _localized(
          OfferDetailScreen(
            offerId: 'nationwide_1',
            contextOffers: [nationwideOffer],
            initialIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Islandwide • Valid across all merchant outlets islandwide'), findsOneWidget);
    });
  });
}
