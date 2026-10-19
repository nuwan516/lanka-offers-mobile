import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/core/semantics/offer_semantics.dart';
import 'package:lanka_offers/domain/entities/location.dart';

import '../support/fakes.dart';

Location _loc(String address, {String name = ''}) => Location(
  name: name,
  address: address,
  district: '',
  city: '',
  latitude: 6.9270786,
  longitude: 79.861243,
);

void main() {
  group('area-level versus confirmed branch locations', () {
    test('a bare city, as the geocoder returns for "Colombo", is area-level', () {
      // Real API data: address "Colombo, Sri Lanka", status resolved, confidence 0.9.
      expect(OfferSemantics.isAreaLevel(_loc('Colombo, Sri Lanka')), isTrue);
      expect(OfferSemantics.isAreaLevel(_loc('Colombo')), isTrue);
      expect(OfferSemantics.isAreaLevel(_loc('Nuwara Eliya, Sri Lanka')), isTrue);
    });

    test('a location with no address at all is not treated as a branch', () {
      expect(OfferSemantics.isAreaLevel(_loc('')), isTrue);
    });

    test('street addresses and numbered places are confirmed branches', () {
      expect(OfferSemantics.isAreaLevel(_loc('5 Dalada Veediya, Kandy')), isFalse);
      expect(OfferSemantics.isAreaLevel(_loc('Colombo 07')), isFalse);
      expect(
        OfferSemantics.isAreaLevel(_loc('Port City Colombo, Marine Drive, Colombo')),
        isFalse,
      );
      expect(
        OfferSemantics.isAreaLevel(_loc('Alexandra Place, Colombo 7, Sri Lanka')),
        isFalse,
      );
    });

    test('an offer is pinnable only with at least one confirmed branch', () {
      final areaOnly = testOffer(locations: [_loc('Colombo, Sri Lanka')]);
      final branch = testOffer();
      final mixed = testOffer(
        locations: [_loc('Colombo, Sri Lanka'), _loc('5 Dalada Veediya, Kandy')],
      );

      expect(OfferSemantics.hasConfirmedBranch(areaOnly), isFalse);
      expect(OfferSemantics.canShowOnMap(areaOnly), isFalse);
      expect(OfferSemantics.canShowOnMap(branch), isTrue);
      expect(OfferSemantics.confirmedBranches(mixed), hasLength(1));
    });

    test('online and island-wide offers are never pinnable, whatever locations they carry', () {
      expect(
        OfferSemantics.canShowOnMap(testOffer(scope: 'ONLINE')),
        isFalse,
      );
      expect(
        OfferSemantics.canShowOnMap(testOffer(scope: 'NATIONWIDE')),
        isFalse,
      );
    });
  });
}
