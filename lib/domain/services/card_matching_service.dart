import '../entities/bank_offer.dart';
import '../entities/card_eligibility.dart';
import '../entities/user_card.dart';
import '../entities/user_preferences.dart';

enum CardMatchStatus {
  confirmedMatch,
  confirmedMismatch,
  unknown,
}

class CardMatchResult {
  final CardMatchStatus status;
  final UserCard? matchedCard;
  final String reason;

  const CardMatchResult({
    required this.status,
    this.matchedCard,
    required this.reason,
  });

  bool get isMatch => status == CardMatchStatus.confirmedMatch;
  bool get isMismatch => status == CardMatchStatus.confirmedMismatch;
  bool get isUnknown => status == CardMatchStatus.unknown;

  @override
  String toString() => 'CardMatchResult(status: $status, reason: $reason, card: ${matchedCard?.displayName})';
}

class CardMatchingService {
  /// Evaluates an offer against all cards belonging to a user.
  ///
  /// - Returns [CardMatchStatus.confirmedMatch] if AT LEAST ONE card confirmed-matches.
  /// - Returns [CardMatchStatus.confirmedMismatch] if ALL evaluated cards are confirmed mismatches.
  /// - Returns [CardMatchStatus.unknown] if no cards match and at least one evaluation is uncertain/unknown.
  static CardMatchResult matchUserCards(BankOffer offer, List<UserCard> cards) {
    if (cards.isEmpty) {
      return const CardMatchResult(
        status: CardMatchStatus.unknown,
        reason: 'No user cards specified for matching',
      );
    }

    final results = cards.map((c) => matchCard(offer, c)).toList();

    // 1. If any card matches -> Confirmed match
    final firstMatch = results.cast<CardMatchResult?>().firstWhere(
      (r) => r?.status == CardMatchStatus.confirmedMatch,
      orElse: () => null,
    );
    if (firstMatch != null) {
      return firstMatch;
    }

    // 2. If any card is unknown / partial -> Unknown (do not claim confirmed not eligible if user might qualify)
    final firstUnknown = results.cast<CardMatchResult?>().firstWhere(
      (r) => r?.status == CardMatchStatus.unknown,
      orElse: () => null,
    );
    if (firstUnknown != null) {
      return firstUnknown;
    }

    // 3. All cards are confirmed mismatches
    return CardMatchResult(
      status: CardMatchStatus.confirmedMismatch,
      reason: 'None of your saved cards match the offer requirements',
    );
  }

  /// Evaluates an offer against a single [UserCard].
  static CardMatchResult matchCard(BankOffer offer, UserCard card) {
    // ── 1. Bank check ────────────────────────────────────────────────────────
    if (!_banksMatch(offer.bankName, card.bank)) {
      return CardMatchResult(
        status: CardMatchStatus.confirmedMismatch,
        matchedCard: card,
        reason: 'Offer bank (${offer.bankName}) does not match card bank (${card.bank})',
      );
    }

    final elig = offer.cardEligibility ?? _fallbackEligibility(offer);

    // ── 2. Empty / Unspecified Offer Eligibility ─────────────────────────────
    if (elig.isEmpty && offer.applicableCards.isEmpty) {
      return CardMatchResult(
        status: CardMatchStatus.unknown,
        matchedCard: card,
        reason: 'Offer does not specify card requirements',
      );
    }

    // ── 3. Exclusions check ──────────────────────────────────────────────────
    if (elig.hasExclusions) {
      for (final excl in elig.excludedCards) {
        final normExcl = excl.toLowerCase();
        if (normExcl.contains('corporate') && card.isCorporate) {
          return CardMatchResult(
            status: CardMatchStatus.confirmedMismatch,
            matchedCard: card,
            reason: 'Corporate cards are explicitly excluded from this offer',
          );
        }
        if (normExcl.contains('business') && (card.isCorporate || card.tier?.toLowerCase() == 'business')) {
          return CardMatchResult(
            status: CardMatchStatus.confirmedMismatch,
            matchedCard: card,
            reason: 'Business cards are explicitly excluded from this offer',
          );
        }
        if (normExcl.contains('fuel') && card.tier?.toLowerCase() == 'fuel') {
          return CardMatchResult(
            status: CardMatchStatus.confirmedMismatch,
            matchedCard: card,
            reason: 'Fuel cards are explicitly excluded from this offer',
          );
        }
      }
    }

    // ── 4. Card Family check (Credit vs Debit) ───────────────────────────────
    final cardIsCredit = _isCredit(card.cardType);
    final cardIsDebit = _isDebit(card.cardType);

    if (elig.cardTypes.isNotEmpty) {
      final offerHasCredit = elig.cardTypes.any(_isCredit);
      final offerHasDebit = elig.cardTypes.any(_isDebit);

      if (offerHasCredit && !offerHasDebit && !cardIsCredit) {
        return CardMatchResult(
          status: CardMatchStatus.confirmedMismatch,
          matchedCard: card,
          reason: 'Offer is exclusive to Credit Cards',
        );
      }
      if (offerHasDebit && !offerHasCredit && !cardIsDebit) {
        return CardMatchResult(
          status: CardMatchStatus.confirmedMismatch,
          matchedCard: card,
          reason: 'Offer is exclusive to Debit Cards',
        );
      }
    } else if (offer.applicableCards.isNotEmpty) {
      final hasCredit = offer.applicableCards.any(_isCredit);
      final hasDebit = offer.applicableCards.any(_isDebit);
      if (hasCredit && !hasDebit && !cardIsCredit) {
        return CardMatchResult(
          status: CardMatchStatus.confirmedMismatch,
          matchedCard: card,
          reason: 'Offer is exclusive to Credit Cards',
        );
      }
      if (hasDebit && !hasCredit && !cardIsDebit) {
        return CardMatchResult(
          status: CardMatchStatus.confirmedMismatch,
          matchedCard: card,
          reason: 'Offer is exclusive to Debit Cards',
        );
      }
    }

    // ── 5. Specific Product / Tier Inclusions ────────────────────────────────
    if (elig.includedCards.isNotEmpty) {
      // The offer requires specific product tiers (e.g. Visa Signature, Visa Infinite)
      if (card.tier == null || card.tier!.isEmpty) {
        // User card does NOT specify a tier — preserve uncertainty!
        return CardMatchResult(
          status: CardMatchStatus.unknown,
          matchedCard: card,
          reason: 'Offer requires ${elig.includedCards.join(' or ')}; user card tier is unspecified',
        );
      }

      final tierMatches = elig.includedCards.any((inc) {
        final normInc = inc.toLowerCase();
        final normTier = card.tier!.toLowerCase();
        if (normInc.contains(normTier)) {
          // If network is also in the tier name, verify network
          if (normInc.contains('visa') && card.network != null && !card.network!.toLowerCase().contains('visa')) {
            return false;
          }
          if (normInc.contains('mastercard') && card.network != null && !card.network!.toLowerCase().contains('mastercard')) {
            return false;
          }
          return true;
        }
        return false;
      });

      if (!tierMatches) {
        return CardMatchResult(
          status: CardMatchStatus.confirmedMismatch,
          matchedCard: card,
          reason: 'Offer requires ${elig.includedCards.join(' or ')}, card tier is ${card.tier}',
        );
      }
    }

    // ── 6. Network check ─────────────────────────────────────────────────────
    if (elig.networks.isNotEmpty) {
      if (card.network == null || card.network!.isEmpty) {
        return CardMatchResult(
          status: CardMatchStatus.unknown,
          matchedCard: card,
          reason: 'Offer requires ${elig.networks.join(' or ')}; card network is unspecified',
        );
      }

      final networkMatches = elig.networks.any((net) =>
          net.toLowerCase() == card.network!.toLowerCase() ||
          card.network!.toLowerCase().contains(net.toLowerCase()));

      if (!networkMatches) {
        return CardMatchResult(
          status: CardMatchStatus.confirmedMismatch,
          matchedCard: card,
          reason: 'Offer requires ${elig.networks.join(' or ')}, card network is ${card.network}',
        );
      }
    }

    // ── 7. Confirmed Match ───────────────────────────────────────────────────
    final desc = [
      offer.bankName,
      if (card.network != null) card.network,
      if (card.tier != null) card.tier,
      card.cardType,
    ].whereType<String>().join(' ');

    return CardMatchResult(
      status: CardMatchStatus.confirmedMatch,
      matchedCard: card,
      reason: 'Matches your $desc',
    );
  }

  /// Synthesizes a list of [UserCard]s from the user's stored preferences.
  /// Handles both explicitly saved cards and legacy flat preference chips.
  static List<UserCard> cardsFromPreferences(UserPreferences prefs) {
    final cards = <UserCard>[];

    // 1. Explicitly saved cards
    if (prefs.savedCards.isNotEmpty) {
      for (final s in prefs.savedCards) {
        try {
          cards.add(UserCard.fromStorageString(s));
        } catch (_) {}
      }
    }

    // 2. Synthesize from selectedBanks + cardTypes + cardNetworks if savedCards is empty
    if (cards.isEmpty && prefs.selectedBanks.isNotEmpty) {
      final types = prefs.cardTypes.isNotEmpty
          ? prefs.cardTypes
          : ['Credit Card', 'Debit Card'];

      for (final bank in prefs.selectedBanks) {
        for (final type in types) {
          if (prefs.cardNetworks.isNotEmpty) {
            for (final net in prefs.cardNetworks) {
              cards.add(UserCard(bank: bank, cardType: type, network: net));
            }
          } else {
            cards.add(UserCard(bank: bank, cardType: type));
          }
        }
      }
    }

    return cards;
  }

  static bool _isCredit(String type) =>
      type.toLowerCase().contains('credit');

  static bool _isDebit(String type) =>
      type.toLowerCase().contains('debit');

  static bool _banksMatch(String a, String b) {
    final normA = _canonicalBank(a);
    final normB = _canonicalBank(b);
    return normA == normB;
  }

  static String _canonicalBank(String bank) {
    final l = bank.toLowerCase().trim();
    if (l == 'hnb' || l.contains('hatton')) return 'hnb';
    if (l == 'boc' || l.contains('ceylon')) return 'boc';
    if (l == 'nsb' || l.contains('savings')) return 'nsb';
    if (l == 'peoples' || l.contains("people's")) return 'peoples';
    if (l == 'combank' || l.contains('commercial')) return 'combank';
    if (l == 'sampath') return 'sampath';
    if (l == 'seylan') return 'seylan';
    if (l == 'dfcc') return 'dfcc';
    if (l == 'ndb') return 'ndb';
    if (l == 'pabc' || l.contains('pan asia')) return 'pabc';
    return l;
  }

  static CardEligibility _fallbackEligibility(BankOffer offer) {
    final types = <String>[];
    for (final c in offer.applicableCards) {
      if (_isCredit(c)) types.add('Credit Card');
      if (_isDebit(c)) types.add('Debit Card');
    }
    return CardEligibility(cardTypes: types.toSet().toList());
  }
}
