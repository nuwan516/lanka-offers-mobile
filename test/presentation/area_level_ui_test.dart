import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_offers/core/di/injection.dart';
import 'package:lanka_offers/domain/entities/location.dart';
import 'package:lanka_offers/domain/usecases/get_nearby_offers.dart';
import 'package:lanka_offers/presentation/common/widgets/offer_card.dart';
import 'package:lanka_offers/presentation/screens/explore/cubit/nearby_cubit.dart';
import 'package:lanka_offers/presentation/screens/offer_detail/offer_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

final Location _cityCentre = Location(
  name: 'Colombo, Sri Lanka',
  address: 'Colombo, Sri Lanka',
  district: '',
  city: '',
  latitude: 6.9270786,
  longitude: 79.861243,
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(localized(SingleChildScrollView(child: child)));
    await tester.pump();
  }

  group('a city-centre point is not presented as a branch', () {
    testWidgets('the card says "Area only" and shows no distance', (tester) async {
      await pump(
        tester,
        OfferCard(offer: testOffer(locations: [_cityCentre], distanceKm: 0)),
      );

      expect(find.text('Area only: Colombo'), findsOneWidget);
      expect(find.text('0 m'), findsNothing);
    });

    testWidgets('a confirmed branch still shows its distance', (tester) async {
      await pump(tester, OfferCard(offer: testOffer(distanceKm: 0.4)));

      expect(find.text('400 m'), findsOneWidget);
    });

    testWidgets('detail explains the limitation and shows no pin or directions', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        localized(
          OfferDetailContent(
            offer: testOffer(locations: [_cityCentre]),
            isSaved: false,
            onToggleSaved: () {},
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('The bank gave only an area, not a branch address, so no map pin is shown.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.directions_outlined), findsNothing);
      expect(find.text('Confirmed branch location'), findsNothing);
      expect(find.text('Location not specified'), findsOneWidget);
    });
  });

  group('nearby ordering', () {
    test('area-only offers come after every confirmed branch, even at distance 0', () async {
      final repo = FakeOfferRepository(
        nearby: [
          testOffer(id: 'area', locations: [_cityCentre], distanceKm: 0),
          testOffer(id: 'far', distanceKm: 6.0),
          testOffer(id: 'near', distanceKm: 0.7),
        ],
      );
      final cubit = NearbyCubit(
        getNearbyOffers: GetNearbyOffers(repo),
        locationService: FakeLocationService(),
      );

      await cubit.selectCity(presetCities.first);

      expect(cubit.state.offers.map((o) => o.uniqueId), ['near', 'far', 'area']);
      await cubit.close();
    });
  });
}
