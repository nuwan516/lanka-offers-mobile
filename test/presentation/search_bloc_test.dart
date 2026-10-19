import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/data/repositories/user_repository_impl.dart';
import 'package:lanka_offers/domain/usecases/search_offers.dart';
import 'package:lanka_offers/presentation/screens/search/bloc/search_bloc.dart';
import 'package:lanka_offers/presentation/screens/search/bloc/search_event.dart';
import 'package:lanka_offers/presentation/screens/search/bloc/search_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

void main() {
  late FakeOfferRepository repo;
  late SearchBloc bloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = FakeOfferRepository(
      offers: [
        testOffer(id: 'p', title: 'Pizza Hut – 20% Off – Credit'),
        testOffer(id: 'k', title: 'Keells – 10% Off – Credit'),
        testOffer(
          id: 'expired',
          title: 'Pizza Palace – 30% Off',
          validUntil: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    );
    bloc = SearchBloc(
      searchOffers: SearchOffers(repo),
      userRepository: UserRepositoryImpl(prefs),
    );
  });

  tearDown(() => bloc.close());

  Future<SearchState> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return bloc.state;
  }

  test(
    'typing is debounced into a single request for the final text',
    () async {
      bloc.add(SearchQueryChanged('p'));
      bloc.add(SearchQueryChanged('pi'));
      bloc.add(SearchQueryChanged('piz'));

      final state = await settle();

      expect(repo.searches, ['piz']);
      expect(state, isA<SearchResultsLoaded>());
    },
  );

  test('results hide expired offers', () async {
    bloc.add(PerformSearch('pizza'));
    final state = await settle() as SearchResultsLoaded;

    expect(state.results.map((o) => o.uniqueId), ['p']);
  });

  test('no match produces an empty result set, not an error', () async {
    bloc.add(PerformSearch('zzzz'));
    final state = await settle() as SearchResultsLoaded;

    expect(state.results, isEmpty);
    expect(state.query, 'zzzz');
  });

  test('clearing the field returns to the initial state', () async {
    bloc.add(PerformSearch('pizza'));
    await settle();
    bloc.add(ClearSearch());
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, isA<SearchInitial>());
  });

  test('a blank query never calls the API', () async {
    bloc.add(PerformSearch('   '));
    await settle();

    expect(repo.searches, isEmpty);
  });

  test('a failed search shows an error and the next search recovers', () async {
    repo.failure = Exception('offline');
    bloc.add(PerformSearch('pizza'));
    expect(await settle(), isA<SearchError>());

    repo.failure = null;
    bloc.add(PerformSearch('pizza'));
    expect(await settle(), isA<SearchResultsLoaded>());
  });

  test('a slow earlier search cannot replace the newer results', () async {
    final slow = Completer<List<dynamic>>();
    repo.gate = slow;
    bloc.add(PerformSearch('pizza'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    repo.gate = null;
    bloc.add(PerformSearch('keells'));
    final newer = await settle() as SearchResultsLoaded;
    expect(newer.query, 'keells');

    slow.complete([testOffer(id: 'stale', title: 'Stale pizza')]);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final state = bloc.state as SearchResultsLoaded;
    expect(state.query, 'keells');
    expect(state.results.map((o) => o.uniqueId), ['k']);
  });
}
