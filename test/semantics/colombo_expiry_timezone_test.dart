import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/core/semantics/offer_semantics.dart';
import 'package:lanka_offers/domain/entities/validity_period.dart';

void main() {
  group('Sri Lankan Asia/Colombo Offer Expiry & Timezone Resilience', () {
    // An offer valid until October 31, 2026
    final offerOct31 = ValidityPeriod(
      validFrom: DateTime.utc(2026, 10, 1),
      validUntil: DateTime.utc(2026, 10, 31),
    );

    test('valid throughout the last day in Sri Lanka (Colombo morning and evening)', () {
      // 2026-10-31 at 08:00 Colombo time (02:30 UTC)
      final colomboMorning = DateTime.utc(2026, 10, 31, 2, 30);
      expect(OfferSemantics.isExpired(offerOct31, now: colomboMorning), isFalse);
      expect(OfferSemantics.daysLeft(offerOct31, now: colomboMorning), 0);

      // 2026-10-31 at 23:55 Colombo time (18:25 UTC) - minutes before midnight in Sri Lanka
      final colomboLateNight = DateTime.utc(2026, 10, 31, 18, 25);
      expect(OfferSemantics.isExpired(offerOct31, now: colomboLateNight), isFalse);
      expect(OfferSemantics.daysLeft(offerOct31, now: colomboLateNight), 0);
    });

    test('expires exactly as midnight passes in Sri Lanka (18:30:00 UTC)', () {
      // Exactly 00:00:01 on Nov 1 in Colombo (18:30:01 UTC on Oct 31)
      final pastMidnightColombo = DateTime.utc(2026, 10, 31, 18, 30, 1);
      expect(OfferSemantics.isExpired(offerOct31, now: pastMidnightColombo), isTrue);
      expect(OfferSemantics.daysLeft(offerOct31, now: pastMidnightColombo), isNull);
    });

    test('device in US Eastern (UTC-4) sees correct Sri Lanka calendar expiry', () {
      // In US Eastern on Oct 31 at 12:00 EDT (16:00 UTC = 21:30 Colombo time on Oct 31)
      // The offer is still valid because in Sri Lanka it is still October 31!
      final usEasternDaytime = DateTime.utc(2026, 10, 31, 16, 0);
      expect(OfferSemantics.isExpired(offerOct31, now: usEasternDaytime), isFalse);
      expect(OfferSemantics.daysLeft(offerOct31, now: usEasternDaytime), 0);

      // In US Eastern on Oct 31 at 15:00 EDT (19:00 UTC = 00:30 on Nov 1 in Colombo)
      // Even though it is still afternoon of Oct 31 in New York, the offer has EXPIRED in Sri Lanka!
      final usEasternAfternoonColomboNov1 = DateTime.utc(2026, 10, 31, 19, 0);
      expect(OfferSemantics.isExpired(offerOct31, now: usEasternAfternoonColomboNov1), isTrue);
    });

    test('device in UTC sees correct Sri Lanka calendar expiry', () {
      // In London/UTC at 17:00 UTC on Oct 31 (22:30 Colombo time on Oct 31)
      final utcEvening = DateTime.utc(2026, 10, 31, 17, 0);
      expect(OfferSemantics.isExpired(offerOct31, now: utcEvening), isFalse);

      // In London/UTC at 19:00 UTC on Oct 31 (00:30 Colombo time on Nov 1)
      final utcLate = DateTime.utc(2026, 10, 31, 19, 0);
      expect(OfferSemantics.isExpired(offerOct31, now: utcLate), isTrue);
    });

    test('year and month boundaries transition accurately without leap/boundary drift', () {
      // New Year Eve offer
      final offerNewYear = ValidityPeriod(
        validFrom: DateTime.utc(2026, 12, 1),
        validUntil: DateTime.utc(2026, 12, 31),
      );

      // 2026-12-31 at 23:00 Colombo time (17:30 UTC)
      final nyeNight = DateTime.utc(2026, 12, 31, 17, 30);
      expect(OfferSemantics.isExpired(offerNewYear, now: nyeNight), isFalse);
      expect(OfferSemantics.daysLeft(offerNewYear, now: nyeNight), 0);

      // 2027-01-01 at 00:05 Colombo time (18:35 UTC on Dec 31)
      final newYearMorning = DateTime.utc(2026, 12, 31, 18, 35);
      expect(OfferSemantics.isExpired(offerNewYear, now: newYearMorning), isTrue);
    });

    test('evergreen offer with noExpirySentinel never expires', () {
      final evergreen = ValidityPeriod(
        validFrom: ValidityPeriod.unknownStartSentinel,
        validUntil: ValidityPeriod.noExpirySentinel,
      );
      expect(OfferSemantics.isExpired(evergreen), isFalse);
      expect(OfferSemantics.daysLeft(evergreen), isNull);
      expect(OfferSemantics.isEndingSoon(evergreen), isFalse);
    });
  });
}
