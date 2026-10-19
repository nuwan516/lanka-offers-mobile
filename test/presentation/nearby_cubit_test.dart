import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lanka_offers/domain/usecases/get_nearby_offers.dart';
import 'package:lanka_offers/presentation/screens/explore/cubit/nearby_cubit.dart';

import '../support/fakes.dart';

void main() {
  late FakeOfferRepository repo;

  NearbyCubit build(FakeLocationService location) => NearbyCubit(
    getNearbyOffers: GetNearbyOffers(repo),
    locationService: location,
  );

  setUp(() {
    repo = FakeOfferRepository(
      nearby: [
        testOffer(id: 'far', distanceKm: 4.2),
        testOffer(id: 'near', distanceKm: 0.4),
        testOffer(id: 'unknown'),
      ],
    );
  });

  group('device location', () {
    test(
      'granted permission loads offers around the device position',
      () async {
        final location = FakeLocationService(
          position: testPosition(7.29, 80.63),
        );
        final cubit = build(location);

        await cubit.useDeviceLocation();

        expect(cubit.state.status, NearbyStatus.loaded);
        expect(cubit.state.place.isDevice, isTrue);
        expect(repo.nearbyCalls.single.lat, 7.29);
        expect(repo.nearbyCalls.single.radius, 10);
        // Nearest first; offers without a distance last.
        expect(cubit.state.offers.map((o) => o.uniqueId), [
          'near',
          'far',
          'unknown',
        ]);
        await cubit.close();
      },
    );

    test(
      'denial is reported, nothing is fetched, and the current city is kept',
      () async {
        final location = FakeLocationService(
          permission: LocationPermission.denied,
          afterRequest: LocationPermission.denied,
        );
        final cubit = build(location);

        await cubit.useDeviceLocation();

        expect(location.requests, 1);
        expect(location.positionReads, 0);
        expect(cubit.state.issue, LocationIssue.denied);
        expect(cubit.state.status, NearbyStatus.idle);
        expect(cubit.state.place.name, 'Colombo');
        expect(repo.nearbyCalls, isEmpty);
        await cubit.close();
      },
    );

    test(
      'permanent denial is distinguished so settings can be offered',
      () async {
        final cubit = build(
          FakeLocationService(permission: LocationPermission.deniedForever),
        );

        await cubit.useDeviceLocation();

        expect(cubit.state.issue, LocationIssue.deniedForever);
        expect(repo.nearbyCalls, isEmpty);
        await cubit.close();
      },
    );

    test(
      'switched-off location services are reported without prompting',
      () async {
        final location = FakeLocationService(servicesEnabled: false);
        final cubit = build(location);

        await cubit.useDeviceLocation();

        expect(cubit.state.issue, LocationIssue.servicesOff);
        expect(location.requests, 0);
        await cubit.close();
      },
    );

    test('a granted prompt answer proceeds to load', () async {
      final location = FakeLocationService(
        permission: LocationPermission.denied,
        afterRequest: LocationPermission.whileInUse,
        position: testPosition(6.93, 79.86),
      );
      final cubit = build(location);

      await cubit.useDeviceLocation();

      expect(cubit.state.status, NearbyStatus.loaded);
      expect(cubit.state.issue, LocationIssue.none);
      await cubit.close();
    });

    test('no position fix is reported as unavailable', () async {
      final cubit = build(FakeLocationService(position: null));

      await cubit.useDeviceLocation();

      expect(cubit.state.issue, LocationIssue.unavailable);
      await cubit.close();
    });
  });

  group('manual fallback', () {
    test('a preset city works after a denial and clears the notice', () async {
      final cubit = build(
        FakeLocationService(
          permission: LocationPermission.denied,
          afterRequest: LocationPermission.denied,
        ),
      );
      await cubit.useDeviceLocation();
      expect(cubit.state.issue, LocationIssue.denied);

      await cubit.selectCity(presetCities.firstWhere((c) => c.name == 'Kandy'));

      expect(cubit.state.issue, LocationIssue.none);
      expect(cubit.state.place.name, 'Kandy');
      expect(repo.nearbyCalls.single.lat, closeTo(7.2906, 0.0001));
      await cubit.close();
    });

    test('changing the radius reloads around the same place', () async {
      final cubit = build(FakeLocationService());
      await cubit.selectCity(presetCities.first);
      await cubit.setRadius(25);

      expect(repo.nearbyCalls.map((c) => c.radius), [10, 25]);
      expect(cubit.state.radiusKm, 25);
      await cubit.close();
    });

    test(
      'an API failure becomes a failed state that refresh can recover',
      () async {
        repo.failure = Exception('offline');
        final cubit = build(FakeLocationService());

        await cubit.selectCity(presetCities.first);
        expect(cubit.state.status, NearbyStatus.failed);

        repo.failure = null;
        await cubit.refresh();
        expect(cubit.state.status, NearbyStatus.loaded);
        await cubit.close();
      },
    );
  });
}
