import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/presentation/common/cubit/paginated_offers_cubit.dart';

import '../support/fakes.dart';

void main() {
  late FakeOfferRepository repo;
  late PaginatedOffersCubit cubit;

  setUp(() {
    repo = FakeOfferRepository(
      offers: [
        for (int i = 1; i <= 55; i++)
          testOffer(
            id: 'offer_$i',
            bankCode: i.isEven ? 'hnb' : 'boc',
            category: i % 3 == 0 ? 'Dining' : 'Shopping',
            validUntil: DateTime.now().add(const Duration(days: 30)),
          ),
      ],
    );
    cubit = PaginatedOffersCubit(repo, pageSize: 20);
  });

  tearDown(() => cubit.close());

  group('PaginatedOffersCubit — Scalable Pagination & State Transitions', () {
    test('1. initial page loading fetches the first page of offers', () async {
      await cubit.loadInitial();

      expect(cubit.state.status, PaginationStatus.loaded);
      expect(cubit.state.offers.length, 20);
      expect(cubit.state.total, 55);
      expect(cubit.state.offset, 20);
      expect(cubit.state.hasReachedMax, isFalse);
      expect(cubit.state.isFetchingMore, isFalse);
    });

    test('2. incremental page fetching fetches next batch and appends', () async {
      await cubit.loadInitial();
      expect(cubit.state.offers.length, 20);

      await cubit.loadNextPage();
      expect(cubit.state.offers.length, 40);
      expect(cubit.state.offset, 40);
      expect(cubit.state.hasReachedMax, isFalse);

      await cubit.loadNextPage();
      expect(cubit.state.offers.length, 55);
      expect(cubit.state.offset, 55);
      expect(cubit.state.hasReachedMax, isTrue);
    });

    test('3. duplicate-request prevention ignores concurrent loadNextPage calls', () async {
      final gate = Completer<List<dynamic>>();
      await cubit.loadInitial();
      expect(cubit.state.offers.length, 20);

      repo.gate = gate;
      // Trigger first fetchMore
      final firstFetch = cubit.loadNextPage();
      expect(cubit.state.isFetchingMore, isTrue);

      // Trigger second fetchMore concurrently while first is still loading
      await cubit.loadNextPage();

      // Complete the gate
      gate.complete(repo.offers.skip(20).take(20).toList());
      await firstFetch;

      // Only one batch was appended
      expect(cubit.state.offers.length, 40);
    });

    test('4. stable ID deduplication prevents duplicate items across pages', () async {
      // Intentionally insert duplicates in the repository stream
      repo.offers = [
        testOffer(id: 'o1', bankCode: 'hnb'),
        testOffer(id: 'o2', bankCode: 'hnb'),
        // Same ID appears again on next page
        testOffer(id: 'o1', bankCode: 'hnb'),
        testOffer(id: 'o3', bankCode: 'hnb'),
      ];
      final shortCubit = PaginatedOffersCubit(repo, pageSize: 2);

      await shortCubit.loadInitial();
      expect(shortCubit.state.offers.map((o) => o.uniqueId).toList(), ['o1', 'o2']);

      await shortCubit.loadNextPage();
      // 'o1' should be deduplicated, leaving only 'o3' appended
      expect(shortCubit.state.offers.map((o) => o.uniqueId).toList(), ['o1', 'o2', 'o3']);
      await shortCubit.close();
    });

    test('5. filter resets clear items and reset offset to 0', () async {
      await cubit.loadInitial(
        filters: const PaginatedFilters(bank: 'hnb', category: 'Dining'),
      );
      expect(cubit.state.filters.isFiltered, isTrue);

      await cubit.resetFilters();
      expect(cubit.state.filters.isFiltered, isFalse);
      expect(cubit.state.offset, 20);
      expect(cubit.state.offers.length, 20);
    });

    test('6. refresh behavior reloads the first page with active filters', () async {
      await cubit.loadInitial(filters: const PaginatedFilters(bank: 'boc'));
      await cubit.loadNextPage();
      expect(cubit.state.offset, greaterThan(20));

      await cubit.refresh();
      // Should reset back to the first page while preserving bank: boc
      expect(cubit.state.offset, 20);
      expect(cubit.state.filters.bank, 'boc');
    });

    test('7. end-of-results detection sets hasReachedMax when catalog is exhausted', () async {
      repo.offers = [
        testOffer(id: 'only_1', bankCode: 'hnb'),
        testOffer(id: 'only_2', bankCode: 'hnb'),
      ];
      final smallCubit = PaginatedOffersCubit(repo, pageSize: 10);
      await smallCubit.loadInitial();

      expect(smallCubit.state.offers.length, 2);
      expect(smallCubit.state.hasReachedMax, isTrue);
      await smallCubit.close();
    });

    test('8. race-condition protection drops stale responses from older requests', () async {
      final slow = Completer<List<dynamic>>();
      repo.gate = slow;
      final firstRequest = cubit.loadInitial(
        filters: const PaginatedFilters(bank: 'hnb'),
      );

      repo.gate = null;
      await cubit.loadInitial(filters: const PaginatedFilters(bank: 'boc'));
      expect(cubit.state.filters.bank, 'boc');

      // Complete the slower, older request
      slow.complete([testOffer(id: 'stale_hnb', bankCode: 'hnb')]);
      await firstRequest;

      // The state remains on the newer 'boc' filter
      expect(cubit.state.filters.bank, 'boc');
    });

    test('9. error during initial load emits failure state', () async {
      repo.failure = Exception('Network error');
      await cubit.loadInitial();

      expect(cubit.state.status, PaginationStatus.failure);
      expect(cubit.state.errorMessage, contains('Network error'));
    });

    test('10. error during loadNextPage preserves existing offers and clears isFetchingMore', () async {
      await cubit.loadInitial();
      expect(cubit.state.offers.length, 20);

      repo.failure = Exception('Next page failed');
      await cubit.loadNextPage();

      // State is still loaded, offers preserved, isFetchingMore reset to false
      expect(cubit.state.status, PaginationStatus.loaded);
      expect(cubit.state.offers.length, 20);
      expect(cubit.state.isFetchingMore, isFalse);
      expect(cubit.state.errorMessage, contains('Next page failed'));
    });
  });
}
