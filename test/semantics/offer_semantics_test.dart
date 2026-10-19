import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/core/semantics/offer_semantics.dart';
import 'package:lanka_offers/domain/entities/validity_period.dart';

ValidityPeriod _until(String iso) => ValidityPeriod(
  validFrom: DateTime.utc(2026, 1, 1),
  validUntil: DateTime.parse(iso),
);

void main() {
  group('discount wording', () {
    test('plain number without "up to" evidence is a fixed percentage', () {
      final d =
          OfferSemantics.parseDiscount(
            '30',
            evidence: 'Tea Tang – 30% Off – Credit',
          )!;
      expect(d.type, 'percentage');
      expect(d.isUpTo, isFalse);
      expect(d.description, '30% off');
      expect(OfferSemantics.percentLabel(d), '30%');
    });

    test('"Up to N%" in the title for the same figure is shown as up to', () {
      final d =
          OfferSemantics.parseDiscount(
            50,
            evidence: 'U & H Wheel Service – Up to 50% off – Credit',
          )!;
      expect(d.isUpTo, isTrue);
      expect(d.description, 'Up to 50% off');
    });

    test(
      '"up to" next to a different figure does not qualify the discount',
      () {
        expect(
          OfferSemantics.parseDiscount(
            '20',
            evidence: 'Up to 12 months 0% installments at Foo',
          )!.isUpTo,
          isFalse,
        );
        expect(
          OfferSemantics.parseDiscount(
            '30',
            evidence: 'Up to 50% off on dining, 30% off on drinks',
          )!.isUpTo,
          isFalse,
        );
        expect(
          OfferSemantics.parseDiscount(
            '30',
            evidence: 'Save up to Rs. 5,000, 30% off',
          )!.isUpTo,
          isFalse,
        );
      },
    );

    test('matching is case-insensitive and tolerates spacing', () {
      expect(
        OfferSemantics.isUpToPercent(35, 'OAK RAY – UP  TO 35% OFF'),
        isTrue,
      );
      expect(OfferSemantics.isUpToPercent(35, 'upto 35%'), isTrue);
    });

    test('missing, empty and non-positive discounts produce no label', () {
      expect(OfferSemantics.parseDiscount(null), isNull);
      expect(OfferSemantics.parseDiscount('  '), isNull);
      expect(OfferSemantics.parseDiscount('0'), isNull);
    });

    test('free-text discounts are kept verbatim, not reinterpreted', () {
      final d = OfferSemantics.parseDiscount('20% (min. spend Rs. 5,000)')!;
      expect(d.type, 'text');
      expect(d.description, '20% (min. spend Rs. 5,000)');
      expect(d.isUpTo, isFalse);
      expect(OfferSemantics.percentLabel(d), isNull);
    });
  });

  group('validity in Sri Lanka time', () {
    // 2026-10-31 in Sri Lanka runs 2026-10-30T18:30Z to 2026-10-31T18:30Z.
    final v = _until('2026-10-31T00:00:00Z');

    test('still valid at the end of the last day', () {
      expect(
        OfferSemantics.isExpired(v, now: DateTime.utc(2026, 10, 31, 18, 0)),
        isFalse,
      );
      expect(
        OfferSemantics.daysLeft(v, now: DateTime.utc(2026, 10, 31, 18, 0)),
        0,
      );
    });

    test('expires at Sri Lanka midnight, not UTC midnight', () {
      expect(
        OfferSemantics.isExpired(v, now: DateTime.utc(2026, 10, 31, 18, 31)),
        isTrue,
      );
      expect(
        OfferSemantics.daysLeft(v, now: DateTime.utc(2026, 10, 31, 18, 31)),
        isNull,
      );
    });

    test(
      'a UTC-midnight valid_to is not expired for the early-morning hours',
      () {
        // 2026-10-31T01:00Z is 06:30 on Oct 31 in Colombo.
        expect(
          OfferSemantics.isExpired(v, now: DateTime.utc(2026, 10, 31, 1)),
          isFalse,
        );
      },
    );

    test('counts whole calendar days and flags the last week', () {
      final now = DateTime.utc(2026, 10, 24, 6);
      expect(OfferSemantics.daysLeft(v, now: now), 7);
      expect(OfferSemantics.isEndingSoon(v, now: now), isTrue);
      expect(
        OfferSemantics.isEndingSoon(v, now: DateTime.utc(2026, 10, 20)),
        isFalse,
      );
    });

    test('offers without an end date never expire and never count down', () {
      final open = ValidityPeriod(
        validFrom: ValidityPeriod.unknownStartSentinel,
        validUntil: ValidityPeriod.noExpirySentinel,
      );
      expect(OfferSemantics.isExpired(open), isFalse);
      expect(OfferSemantics.daysLeft(open), isNull);
      expect(OfferSemantics.isEndingSoon(open), isFalse);
    });
  });

  group('terms statements stay verbatim', () {
    const terms = [
      'Minimum bill value of Rs.25,000/-',
      'Maximum discount Rs. 10,000 per transaction',
      'Prior reservation is mandatory',
    ];

    test('minimum spend lines are returned as written', () {
      expect(OfferSemantics.minSpendStatements(terms), [
        'Minimum bill value of Rs.25,000/-',
      ]);
    });

    test('cap lines are returned as written, none are invented', () {
      expect(OfferSemantics.capStatements(terms), [
        'Maximum discount Rs. 10,000 per transaction',
      ]);
      expect(OfferSemantics.capStatements(const ['Booking required']), isEmpty);
    });
  });
}
