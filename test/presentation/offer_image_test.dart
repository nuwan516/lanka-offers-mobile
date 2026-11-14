import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/presentation/common/widgets/offer_image.dart';

Widget subject(String? url) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 320,
      child: OfferImage(imageUrl: url, semanticLabel: 'HNB promotion image'),
    ),
  ),
);

void main() {
  testWidgets(
    'reserves a stable 16:9 frame and shows a neutral missing-image placeholder',
    (tester) async {
      await tester.pumpWidget(subject(null));
      expect(find.byKey(const ValueKey('offer_image_frame')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('offer_image_placeholder')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    },
  );

  testWidgets(
    'uses cached network loading and configures bounded loading and error states',
    (tester) async {
      await tester.pumpWidget(subject('https://invalid.test/image.png'));
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      final cached = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      final context = tester.element(find.byType(CachedNetworkImage));
      expect(
        cached.placeholder!(context, cached.imageUrl).key,
        const ValueKey('offer_image_loading'),
      );
      expect(
        cached.errorWidget!(context, cached.imageUrl, Exception('failed')).key,
        const ValueKey('offer_image_placeholder'),
      );
    },
  );
}
