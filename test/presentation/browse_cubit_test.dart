import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/presentation/screens/explore/cubit/browse_cubit.dart';

import '../support/fakes.dart';

void main() {
  final soon = DateTime.now().add(const Duration(days: 3));
  final later = DateTime.now().add(const Duration(days: 90));

  late FakeOfferRepository repo;
  late BrowseCubit cubit;

  setUp(() {
    repo = FakeOfferRepository(
      offers: [
        testOffer(
          id: 'h1',
          bankCode: 'hnb',
          category: 'Dining',
          discountRaw: 20,
          validUntil: later,
        ),
        testOffer(
          id: 'h2',
          bankCode: 'hnb',
          category: 'Hotel',
          discountRaw: 50,
          validUntil: soon,
        ),
        testOffer(
          id: 'b1',
          bankCode: 'boc',
          category: 'Dining',
          discountRaw: 35,
          validUntil: later,
        ),
        testOffer(
          id: 'old',
          bankCode: 'hnb',
          category: 'Dining',
          discountRaw: 90,
          validUntil: DateTime.now().subtract(const Duration(days: 3)),
        ),
        testOffer(
          id: 'online1',
          bankCode: 'hnb',
          scope: 'ONLINE',
          locations: const [],
          category: 'Shopping',
        ),
      ],
    );
    cubit = BrowseCubit(repo);
  });

  tearDown(() => cubit.close());

  group('bank and scope filtering', () {
    test(
      'a bank filter is sent to the API and only that bank is shown',
      () async {
        await cubit.load(const BrowseFilters(bankCode: 'boc'));

        expect(repo.queries.single.bank, 'boc');
        expect(cubit.state.status, BrowseStatus.loaded);
        expect(cubit.state.offers.map((o) => o.uniqueId), ['b1']);
      },
    );

    test('scope filters use the API location scope', () async {
      await cubit.load(const BrowseFilters(scope: 'ONLINE'));

      expect(repo.queries.single.scope, 'ONLINE');
      expect(cubit.state.offers.map((o) => o.uniqueId), ['online1']);
    });

    test('expired offers never appear', () async {
      await cubit.load(const BrowseFilters());

      expect(cubit.state.offers.map((o) => o.uniqueId), isNot(contains('old')));
      expect(cubit.state.offers.length, 4);
    });
  });

  group('category and sort are applied to the full result', () {
    test(
      'categories come from the whole set, and the literal "All" is hidden',
      () async {
        repo.offers = [...repo.offers, testOffer(id: 'x', category: 'All')];
        await cubit.load(const BrowseFilters());

        expect(cubit.state.categories, ['Dining', 'Hotel', 'Shopping']);
      },
    );

    test(
      'choosing a category does not reload and does not shrink the category list',
      () async {
        await cubit.load(const BrowseFilters());
        cubit.refine(category: 'Hotel');

        expect(repo.queries, hasLength(1));
        expect(cubit.state.offers.map((o) => o.uniqueId), ['h2']);
        expect(cubit.state.categories, ['Dining', 'Hotel', 'Shopping']);

        cubit.refine(clearCategory: true);
        expect(cubit.state.offers.length, 4);
      },
    );

    test(
      'highest-discount sort orders by percentage, offers without one last',
      () async {
        await cubit.load(const BrowseFilters());
        cubit.refine(sort: BrowseSort.discount);

        final ids = cubit.state.offers.map((o) => o.uniqueId).toList();
        expect(ids.take(3), ['h2', 'b1', 'h1']);
      },
    );

    test('ending-soon sort puts the nearest expiry first', () async {
      await cubit.load(const BrowseFilters());
      cubit.refine(sort: BrowseSort.endingSoon);

      expect(cubit.state.offers.first.uniqueId, 'h2');
    });
  });

  group('loading, failure and ordering of requests', () {
    test(
      'a failed request leaves a failed state, and retrying recovers',
      () async {
        repo.failure = Exception('offline');
        await cubit.load(const BrowseFilters());
        expect(cubit.state.status, BrowseStatus.failed);

        repo.failure = null;
        await cubit.load(const BrowseFilters());
        expect(cubit.state.status, BrowseStatus.loaded);
      },
    );

    test('a slower, older response cannot overwrite a newer one', () async {
      final slow = Completer<List<dynamic>>();
      repo.gate = slow;
      final first = cubit.load(const BrowseFilters(bankCode: 'hnb'));

      repo.gate = null;
      await cubit.load(const BrowseFilters(bankCode: 'boc'));
      expect(cubit.state.offers.map((o) => o.uniqueId), ['b1']);

      slow.complete([testOffer(id: 'stale', bankCode: 'hnb')]);
      await first;

      expect(cubit.state.filters.bankCode, 'boc');
      expect(cubit.state.offers.map((o) => o.uniqueId), ['b1']);
    });
  });
}
