import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/domain/entities/bank_offer.dart';
import 'package:lanka_offers/domain/entities/card_eligibility.dart';
import 'package:lanka_offers/domain/entities/quality_score.dart';
import 'package:lanka_offers/domain/entities/user_card.dart';
import 'package:lanka_offers/domain/entities/user_preferences.dart';
import 'package:lanka_offers/domain/entities/validity_period.dart';
import 'package:lanka_offers/domain/services/card_matching_service.dart';

BankOffer _mockOffer({
  required String id,
  required String bankName,
  List<String> applicableCards = const [],
  CardEligibility? cardEligibility,
}) {
  return BankOffer(
    uniqueId: id,
    title: 'Offer $id',
    description: 'Description for $id',
    category: 'Dining',
    subcategories: const [],
    locations: const [],
    validity: ValidityPeriod(
      validFrom: DateTime(2026, 1, 1),
      validUntil: DateTime(2026, 12, 31),
    ),
    images: const [],
    quality: QualityScore(confidenceScore: 0.8, grade: 'B'),
    bankName: bankName,
    merchantName: 'Merchant $id',
    applicableCards: applicableCards,
    cardEligibility: cardEligibility,
  );
}

void main() {
  group('CardEligibility Entity', () {
    test('parses complete structured JSON correctly', () {
      final json = {
        'cardTypes': ['Credit Card'],
        'networks': ['Visa'],
        'includedCards': ['Visa Signature', 'Visa Infinite'],
        'excludedCards': ['Corporate', 'Business', 'Fuel Cards'],
        'restrictions': ['Except: Corporate, Business and Fuel Cards'],
      };

      final elig = CardEligibility.fromJson(json);

      expect(elig.cardTypes, ['Credit Card']);
      expect(elig.networks, ['Visa']);
      expect(elig.includedCards, ['Visa Signature', 'Visa Infinite']);
      expect(elig.excludedCards, ['Corporate', 'Business', 'Fuel Cards']);
      expect(elig.restrictions, ['Except: Corporate, Business and Fuel Cards']);
      expect(elig.isCreditOnly, isTrue);
      expect(elig.isDebitOnly, isFalse);
      expect(elig.hasExclusions, isTrue);
      expect(elig.hasTierRequirements, isTrue);
      expect(elig.isEmpty, isFalse);
    });

    test('handles empty / null JSON with safe defaults', () {
      final eligNull = CardEligibility.fromJson(null);
      expect(eligNull.isEmpty, isTrue);
      expect(eligNull.cardTypes, isEmpty);
      expect(eligNull.networks, isEmpty);
      expect(eligNull.includedCards, isEmpty);
      expect(eligNull.excludedCards, isEmpty);

      final eligEmpty = CardEligibility.fromJson({});
      expect(eligEmpty.isEmpty, isTrue);
    });

    test('displaySummary formats human-friendly card requirements', () {
      const elig1 = CardEligibility(
        cardTypes: ['Credit Card'],
        networks: ['Visa'],
        excludedCards: ['Corporate'],
      );
      expect(elig1.displaySummary, 'Credit Card (Visa) [Excludes: Corporate]');

      const elig2 = CardEligibility(
        includedCards: ['Visa Signature', 'Visa Infinite'],
      );
      expect(elig2.displaySummary, 'Visa Signature / Visa Infinite');

      const elig3 = CardEligibility();
      expect(elig3.displaySummary, 'All Cards');
    });
  });

  group('UserCard Entity', () {
    test('displayName formats all dimensions cleanly', () {
      const card1 = UserCard(
        bank: 'HNB',
        cardType: 'Credit Card',
        network: 'Visa',
        tier: 'Signature',
      );
      expect(card1.displayName, 'HNB Visa Signature Credit Card');

      const card2 = UserCard(
        bank: 'BOC',
        cardType: 'Debit Card',
      );
      expect(card2.displayName, 'BOC Debit Card');

      const card3 = UserCard(
        bank: 'Commercial Bank',
        cardType: 'Credit Card',
        isCorporate: true,
      );
      expect(card3.displayName, 'Commercial Bank Corporate Credit Card');
    });

    test('toStorageString and fromStorageString roundtrip faithfully', () {
      const card = UserCard(
        bank: 'Hatton National Bank',
        cardType: 'Credit Card',
        network: 'Visa',
        tier: 'Signature',
        isCorporate: false,
      );

      final encoded = card.toStorageString();
      final decoded = UserCard.fromStorageString(encoded);

      expect(decoded.bank, card.bank);
      expect(decoded.cardType, card.cardType);
      expect(decoded.network, card.network);
      expect(decoded.tier, card.tier);
      expect(decoded.isCorporate, card.isCorporate);
    });
  });

  group('CardMatchingService — Test Matrix (Section 50 & 36)', () {
    test('Case 1: Offer: HNB Visa Signature, User: HNB Visa Signature -> MATCH', () {
      final offer = _mockOffer(
        id: 'hnb_sig',
        bankName: 'Hatton National Bank',
        cardEligibility: const CardEligibility(
          cardTypes: ['Credit Card'],
          networks: ['Visa'],
          includedCards: ['Visa Signature'],
        ),
      );

      const userCard = UserCard(
        bank: 'HNB',
        cardType: 'Credit Card',
        network: 'Visa',
        tier: 'Signature',
      );

      final result = CardMatchingService.matchCard(offer, userCard);
      expect(result.status, CardMatchStatus.confirmedMatch);
      expect(result.isMatch, isTrue);
    });

    test('Case 2: Offer: HNB Visa Signature, User: Commercial Bank Visa Signature -> NOT MATCH (wrong bank)', () {
      final offer = _mockOffer(
        id: 'hnb_sig',
        bankName: 'Hatton National Bank',
        cardEligibility: const CardEligibility(
          cardTypes: ['Credit Card'],
          networks: ['Visa'],
          includedCards: ['Visa Signature'],
        ),
      );

      const userCard = UserCard(
        bank: 'Commercial Bank',
        cardType: 'Credit Card',
        network: 'Visa',
        tier: 'Signature',
      );

      final result = CardMatchingService.matchCard(offer, userCard);
      expect(result.status, CardMatchStatus.confirmedMismatch);
      expect(result.isMismatch, isTrue);
      expect(result.reason, contains('does not match'));
    });

    test('Case 3: Offer: All HNB Credit Cards, User: HNB Mastercard Credit -> MATCH', () {
      final offer = _mockOffer(
        id: 'hnb_all_credit',
        bankName: 'Hatton National Bank',
        cardEligibility: const CardEligibility(
          cardTypes: ['Credit Card'],
          excludedCards: ['Corporate'],
        ),
      );

      const userCard = UserCard(
        bank: 'HNB',
        cardType: 'Credit Card',
        network: 'Mastercard',
      );

      final result = CardMatchingService.matchCard(offer, userCard);
      expect(result.status, CardMatchStatus.confirmedMatch);
      expect(result.isMatch, isTrue);
    });

    test('Case 4: Offer: HNB Credit except Corporate, User: HNB Corporate Credit -> NOT MATCH (excluded)', () {
      final offer = _mockOffer(
        id: 'hnb_excl',
        bankName: 'Hatton National Bank',
        cardEligibility: const CardEligibility(
          cardTypes: ['Credit Card'],
          excludedCards: ['Corporate', 'Business', 'Fuel Cards'],
        ),
      );

      const corporateCard = UserCard(
        bank: 'HNB',
        cardType: 'Credit Card',
        isCorporate: true,
      );

      final result = CardMatchingService.matchCard(offer, corporateCard);
      expect(result.status, CardMatchStatus.confirmedMismatch);
      expect(result.isMismatch, isTrue);
      expect(result.reason, contains('Corporate cards are explicitly excluded'));
    });

    test('Case 5: Offer: Selected Cards (no products listed), User: HNB Visa Credit -> UNKNOWN', () {
      final offer = _mockOffer(
        id: 'hnb_unknown',
        bankName: 'Hatton National Bank',
        cardEligibility: const CardEligibility(), // empty eligibility
      );

      const userCard = UserCard(
        bank: 'HNB',
        cardType: 'Credit Card',
        network: 'Visa',
      );

      final result = CardMatchingService.matchCard(offer, userCard);
      expect(result.status, CardMatchStatus.unknown);
      expect(result.isUnknown, isTrue);
      expect(result.reason, contains('does not specify card requirements'));
    });

    test('Case 6: Section 36: Offer requires Visa Signature, User has unspecified tier -> UNKNOWN (preserves uncertainty)', () {
      final offer = _mockOffer(
        id: 'hnb_sig_only',
        bankName: 'Hatton National Bank',
        cardEligibility: const CardEligibility(
          cardTypes: ['Credit Card'],
          networks: ['Visa'],
          includedCards: ['Visa Signature'],
        ),
      );

      // User card is Visa Credit, but tier is null/unspecified
      const userCard = UserCard(
        bank: 'HNB',
        cardType: 'Credit Card',
        network: 'Visa',
        tier: null,
      );

      final result = CardMatchingService.matchCard(offer, userCard);
      expect(result.status, CardMatchStatus.unknown);
      expect(result.isUnknown, isTrue);
      expect(result.reason, contains('user card tier is unspecified'));
    });

    test('Case 7: Offer requires Credit Card, User card is Debit Card -> NOT MATCH', () {
      final offer = _mockOffer(
        id: 'boc_credit',
        bankName: 'Bank of Ceylon',
        cardEligibility: const CardEligibility(
          cardTypes: ['Credit Card'],
        ),
      );

      const debitCard = UserCard(
        bank: 'BOC',
        cardType: 'Debit Card',
      );

      final result = CardMatchingService.matchCard(offer, debitCard);
      expect(result.status, CardMatchStatus.confirmedMismatch);
      expect(result.isMismatch, isTrue);
      expect(result.reason, contains('Credit Cards'));
    });

    test('Case 8: Offer requires Mastercard, User card is Visa -> NOT MATCH', () {
      final offer = _mockOffer(
        id: 'nsb_mc',
        bankName: 'National Savings Bank',
        cardEligibility: const CardEligibility(
          cardTypes: ['Debit Card'],
          networks: ['Mastercard'],
        ),
      );

      const visaCard = UserCard(
        bank: 'NSB',
        cardType: 'Debit Card',
        network: 'Visa',
      );

      final result = CardMatchingService.matchCard(offer, visaCard);
      expect(result.status, CardMatchStatus.confirmedMismatch);
      expect(result.isMismatch, isTrue);
      expect(result.reason, contains('Mastercard'));
    });

    test('Case 9: Multi-card evaluation: User has HNB Credit and BOC Debit. Offer is BOC Debit -> MATCH', () {
      final offer = _mockOffer(
        id: 'boc_debit',
        bankName: 'Bank of Ceylon',
        cardEligibility: const CardEligibility(
          cardTypes: ['Debit Card'],
        ),
      );

      final userCards = [
        const UserCard(bank: 'HNB', cardType: 'Credit Card'),
        const UserCard(bank: 'BOC', cardType: 'Debit Card'),
      ];

      final result = CardMatchingService.matchUserCards(offer, userCards);
      expect(result.status, CardMatchStatus.confirmedMatch);
      expect(result.isMatch, isTrue);
      expect(result.matchedCard?.bank, 'BOC');
    });

    test('Case 10: Multi-card evaluation: User has HNB Credit and BOC Debit. Offer is ComBank -> NOT MATCH', () {
      final offer = _mockOffer(
        id: 'cb_offer',
        bankName: 'Commercial Bank',
        cardEligibility: const CardEligibility(
          cardTypes: ['Credit Card'],
        ),
      );

      final userCards = [
        const UserCard(bank: 'HNB', cardType: 'Credit Card'),
        const UserCard(bank: 'BOC', cardType: 'Debit Card'),
      ];

      final result = CardMatchingService.matchUserCards(offer, userCards);
      expect(result.status, CardMatchStatus.confirmedMismatch);
      expect(result.isMismatch, isTrue);
    });
  });

  group('Preference Synthesis & Migration', () {
    test('synthesizes UserCards from flat preference chips', () {
      final prefs = UserPreferences(
        selectedBanks: ['Hatton National Bank'],
        cardTypes: ['Credit Card'],
        cardNetworks: ['Visa'],
        preferredCategories: [],
        preferredDistricts: [],
        savedCards: [],
        notificationsEnabled: false,
      );

      final cards = CardMatchingService.cardsFromPreferences(prefs);
      expect(cards, hasLength(1));
      expect(cards.first.bank, 'Hatton National Bank');
      expect(cards.first.cardType, 'Credit Card');
      expect(cards.first.network, 'Visa');
    });

    test('prioritizes explicit savedCards over flat chips when present', () {
      const explicitCard = UserCard(
        bank: 'HNB',
        cardType: 'Credit Card',
        network: 'Visa',
        tier: 'Signature',
      );

      final prefs = UserPreferences(
        selectedBanks: ['BOC'],
        cardTypes: ['Debit Card'],
        cardNetworks: ['Mastercard'],
        preferredCategories: [],
        preferredDistricts: [],
        savedCards: [explicitCard.toStorageString()],
        notificationsEnabled: false,
      );

      final cards = CardMatchingService.cardsFromPreferences(prefs);
      expect(cards, hasLength(1));
      expect(cards.first.tier, 'Signature');
      expect(cards.first.bank, 'HNB');
    });
  });
}
