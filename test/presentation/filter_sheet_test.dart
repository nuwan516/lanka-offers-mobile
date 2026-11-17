import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/core/di/injection.dart';
import 'package:lanka_offers/domain/repositories/offer_repository.dart';
import 'package:lanka_offers/presentation/common/widgets/filter_sheet.dart';
import 'package:lanka_offers/presentation/screens/search/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('filter sheet applies and resets a single choice', (
    tester,
  ) async {
    Map<String, String?>? applied;
    await tester.pumpWidget(
      localized(
        Builder(
          builder:
              (context) => FilledButton(
                onPressed: () async {
                  applied = await FilterSheet.show(
                    context,
                    title: 'Filter',
                    groups: const [
                      FilterGroup(
                        id: 'bank',
                        title: 'Banks',
                        anyLabel: 'Any',
                        choices: [
                          FilterChoice(
                            value: 'hnb',
                            label: 'Hatton National Bank',
                          ),
                          FilterChoice(value: 'boc', label: 'Bank of Ceylon'),
                        ],
                      ),
                    ],
                  );
                },
                child: const Text('Open'),
              ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('filter_sheet')), findsOneWidget);
    expect(find.text('Hatton National Bank'), findsOneWidget);

    await tester.tap(find.text('Hatton National Bank'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter_reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hatton National Bank'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter_apply')));
    await tester.pumpAndSettle();

    expect(applied, {'bank': 'hnb'});
  });

  testWidgets('search results open the filter sheet and narrow the list', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
    final repo = FakeOfferRepository(
      offers: [
        testOffer(
          id: 'a',
          bankCode: 'hnb',
          merchant: 'Pizza Hut',
          title: 'Pizza Hut – 20% Off – Credit',
          category: 'Dining',
        ),
        testOffer(
          id: 'b',
          bankCode: 'boc',
          merchant: 'Keells',
          title: 'Keells Pizza – 10% Off – Credit',
          category: 'Groceries',
        ),
      ],
    );
    getIt.unregister<OfferRepository>();
    getIt.registerLazySingleton<OfferRepository>(() => repo);

    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(localized(const SearchScreen()));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'pizza');
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Pizza Hut'), findsOneWidget);
    expect(find.text('Keells'), findsOneWidget);

    await tester.tap(find.byKey(const Key('search_filter_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Hatton National Bank'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter_apply')));
    await tester.pumpAndSettle();

    expect(find.text('Pizza Hut'), findsOneWidget);
    expect(find.text('Keells'), findsNothing);
    expect(
      find.widgetWithText(InputChip, 'Hatton National Bank'),
      findsOneWidget,
    );
  });
}
