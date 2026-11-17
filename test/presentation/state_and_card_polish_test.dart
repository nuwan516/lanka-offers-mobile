import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/core/di/injection.dart';
import 'package:lanka_offers/presentation/common/widgets/offer_card.dart';
import 'package:lanka_offers/presentation/common/widgets/offer_image.dart';
import 'package:lanka_offers/presentation/common/widgets/state_views.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
  });

  testWidgets(
    'a card without a photo does not show a broken-image placeholder',
    (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        localized(
        OfferCard(
          offer: testOffer(
            title: 'Tea Tang – 30% Off – Credit',
            discountRaw: '30',
          ),
        ),
      ),
      );
    await tester.pump();
    await tester.pump();

    expect(find.byType(OfferImage), findsNothing);
      expect(find.byIcon(Icons.image_not_supported_outlined), findsNothing);
      expect(find.text('30% off'), findsOneWidget);

      final save = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.favorite_border_rounded),
      );
      expect(save.constraints?.minWidth, greaterThanOrEqualTo(48));
      expect(save.constraints?.minHeight, greaterThanOrEqualTo(48));
    },
  );

  testWidgets('failed and empty states keep their actions and wording', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      localized(
        Column(
          children: [
            const Expanded(child: LoadFailedView()),
            Expanded(child: EmptyOffersView(onClear: () => retried = true)),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('load offers'), findsOneWidget);
    expect(find.text('No offers found'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);

    await tester.pumpWidget(
      localized(LoadFailedView(onRetry: () => retried = true)),
    );
    await tester.pump();
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });
}
