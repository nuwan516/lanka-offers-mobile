import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lanka_offers/core/semantics/offer_semantics.dart';
import 'package:lanka_offers/data/datasources/remote/api_offers_datasource.dart';

Map<String, dynamic> _item({
  String id = 'a1',
  String uniqueId = 'peoples_uh-wheel',
  String bank = 'peoples',
  String title = 'U & H Wheel Service – Up to 50% off – Credit',
  Object? discount = '50',
  String? validTo = '2026-12-31T00:00:00.000Z',
  String scope = 'EXPLICIT_BRANCH',
}) => {
  'id': id,
  'unique_id': uniqueId,
  'bank': bank,
  'source_url': 'https://example-bank.lk/offers/uh',
  'title': title,
  'category': 'Autocare',
  'card_type': 'Credit',
  'merchant_name': 'U&H Wheel Service',
  'merchant_location': 'Colombo',
  'canonical_merchant': null,
  'location_scope': scope,
  'discount_percentage': discount,
  'valid_from': '2026-01-01T00:00:00.000Z',
  'valid_to': validTo,
  'card_eligibility': {
    'cardTypes': ['Credit Card'],
    'networks': ['Visa'],
    'includedCards': [],
    'excludedCards': [],
    'restrictions': [],
  },
  'geo_locations': [
    {'name': 'Narahenpita', 'city': 'Colombo', 'lat': 6.89, 'lng': 79.88},
    {'name': 'No coordinates', 'city': 'Kandy'},
  ],
  'db_status': 'PUBLISHED',
};

http.Client _client(Map<String, Object> Function(Uri uri) handler) =>
    MockClient((req) async {
      final result = handler(req.url);
      final status = result['status'] as int? ?? 200;
      return http.Response(
        jsonEncode(result['body']),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

void main() {
  final ds = ApiOffersDataSource();

  group('list response parsing', () {
    test(
      'maps bank code, canonical name, source link and card eligibility',
      () async {
        final offers = await http.runWithClient(
          () => ds.fetchOffers(),
          () => _client(
            (_) => {
              'body': {
                'items': [_item()],
                'total': 1,
              },
            },
          ),
        );

        final o = offers.single;
        expect(o.bankCode, 'peoples');
        expect(o.bankName, "People's Bank");
        expect(o.sourceUrl, 'https://example-bank.lk/offers/uh');
        expect(o.cardEligibility!.cardTypes, ['Credit Card']);
        expect(o.cardEligibility!.networks, ['Visa']);
      },
    );

    test(
      'keeps only locations that have coordinates (no invented pins)',
      () async {
        final offers = await http.runWithClient(
          () => ds.fetchOffers(),
          () => _client(
            (_) => {
              'body': {
                'items': [_item()],
                'total': 1,
              },
            },
          ),
        );

        expect(offers.single.locations, hasLength(1));
        expect(offers.single.locations.single.latitude, 6.89);
      },
    );

    test(
      '"Up to" in the title qualifies the discount; plain titles do not',
      () async {
        final offers = await http.runWithClient(
          () => ds.fetchOffers(),
          () => _client(
            (_) => {
              'body': {
                'items': [
                  _item(),
                  _item(
                    id: 'a2',
                    title: 'Tea Tang – 30% Off – Credit',
                    discount: '30',
                  ),
                ],
                'total': 2,
              },
            },
          ),
        );

        expect(offers[0].discount!.isUpTo, isTrue);
        expect(offers[0].discount!.description, 'Up to 50% off');
        expect(offers[1].discount!.isUpTo, isFalse);
        expect(offers[1].discount!.description, '30% off');
      },
    );

    test(
      'numeric and string discounts parse alike; null stays absent',
      () async {
        final offers = await http.runWithClient(
          () => ds.fetchOffers(),
          () => _client(
            (_) => {
              'body': {
                'items': [
                  _item(id: 'n1', discount: 25, title: 'X – 25% Off'),
                  _item(id: 'n2', discount: null, title: 'VISA Offers'),
                ],
                'total': 2,
              },
            },
          ),
        );

        expect(OfferSemantics.percentLabel(offers[0].discount), '25%');
        expect(offers[1].discount, isNull);
      },
    );

    test(
      'a missing end date is the no-expiry sentinel, not a made-up date',
      () async {
        final offers = await http.runWithClient(
          () => ds.fetchOffers(),
          () => _client(
            (_) => {
              'body': {
                'items': [_item(validTo: null)],
                'total': 1,
              },
            },
          ),
        );

        expect(offers.single.validity.hasNoConfiguredExpiry, isTrue);
      },
    );

    test('an HTTP error surfaces as an exception, not an empty list', () async {
      expect(
        http.runWithClient(
          () => ds.fetchOffers(),
          () => _client(
            (_) => {
              'status': 503,
              'body': {'error': 'down'},
            },
          ),
        ),
        throwsException,
      );
    });
  });

  group('paging', () {
    test(
      'fetchAllOffers keeps requesting pages until the reported total',
      () async {
        final offsets = <String?>[];
        final offers = await http.runWithClient(
          () => ds.fetchAllOffers(bank: 'peoples'),
          () => _client((uri) {
            offsets.add(uri.queryParameters['offset']);
            expect(uri.queryParameters['bank'], 'peoples');
            expect(uri.queryParameters['limit'], '500');
            final i = int.parse(uri.queryParameters['offset']!);
            return {
              'body': {
                'items': [_item(id: 'p$i', uniqueId: 'u$i')],
                'total': 3,
              },
            };
          }),
        );

        expect(offsets, ['0', '1', '2']);
        expect(offers.map((o) => o.uniqueId), ['u0', 'u1', 'u2']);
      },
    );

    test('an empty page ends paging even if the total is larger', () async {
      var calls = 0;
      final offers = await http.runWithClient(
        () => ds.fetchAllOffers(),
        () => _client((_) {
          calls++;
          return {
            'body': {'items': [], 'total': 99},
          };
        }),
      );

      expect(offers, isEmpty);
      expect(calls, 1);
    });
  });

  group('banks directory', () {
    test('reports counts, and distinguishes zero from unreported', () async {
      final banks = await http.runWithClient(
        () => ds.fetchBanks(),
        () => _client(
          (_) => {
            'body': [
              {
                'code': 'hnb',
                'name': 'Hatton National Bank',
                'activeOfferCount': 448,
                'cardTypesSupported': ['credit', 'debit'],
              },
              {
                'code': 'sampath',
                'name': 'Sampath Bank',
                'activeOfferCount': 0,
              },
              {'code': 'seylan', 'name': 'Seylan Bank'},
            ],
          },
        ),
      );

      expect(banks.map((b) => b.activeOfferCount), [448, 0, null]);
      expect(banks.first.cardTypesSupported, ['credit', 'debit']);
    });
  });

  group('detail response', () {
    test(
      'reads the bank\'s general terms and transaction range verbatim',
      () async {
        final detail =
            _item()
              ..['raw_offer'] = {
                'offer': {
                  'generalTerms': [
                    'Minimum bill value of Rs.25,000/-',
                    'Booking required',
                  ],
                  'restrictions': ['Minimum spend or pax required'],
                  'bookingRequired': true,
                },
                'transactionRange': {
                  'min': 25000,
                  'max': null,
                  'currency': 'LKR',
                },
              };

        final offer = await http.runWithClient(
          () => ds.fetchOfferById('a1'),
          () => _client((_) => {'body': detail}),
        );

        expect(offer!.generalTerms, [
          'Minimum bill value of Rs.25,000/-',
          'Booking required',
        ]);
        expect(offer.minTransaction, 25000);
        expect(offer.maxTransaction, isNull);
      },
    );

    test('404 is "not found" (null), other errors throw', () async {
      final missing = await http.runWithClient(
        () => ds.fetchOfferById('nope'),
        () => _client((_) => {'status': 404, 'body': {}}),
      );
      expect(missing, isNull);

      expect(
        http.runWithClient(
          () => ds.fetchOfferById('x'),
          () => _client((_) => {'status': 500, 'body': {}}),
        ),
        throwsException,
      );
    });
  });
}
