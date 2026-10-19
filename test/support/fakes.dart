import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lanka_offers/core/enums/offer_type.dart';
import 'package:lanka_offers/core/localization/app_localizations.dart';
import 'package:lanka_offers/core/semantics/offer_semantics.dart';
import 'package:lanka_offers/core/services/language_service.dart';
import 'package:lanka_offers/core/services/location_service.dart';
import 'package:lanka_offers/domain/entities/bank_offer.dart';
import 'package:lanka_offers/domain/entities/bank_summary.dart';
import 'package:lanka_offers/domain/entities/card_eligibility.dart';
import 'package:lanka_offers/domain/entities/location.dart';
import 'package:lanka_offers/domain/entities/quality_score.dart';
import 'package:lanka_offers/domain/entities/validity_period.dart';
import 'package:lanka_offers/domain/repositories/offer_repository.dart';

/// A published offer for tests. Dates default to a year ahead in Sri Lanka
/// time so nothing here expires while the suite runs.
BankOffer testOffer({
  String id = 'o1',
  String merchant = 'Pizza Hut',
  String title = 'Pizza Hut – 20% Off – Credit',
  String bankCode = 'hnb',
  String category = 'Dining',
  dynamic discountRaw = 20,
  String? discountEvidence,
  DateTime? validUntil,
  bool noExpiry = false,
  String? scope = 'EXPLICIT_BRANCH',
  List<Location>? locations,
  CardEligibility? eligibility,
  List<String> generalTerms = const [],
  String? sourceUrl,
  double? distanceKm,
  double? minTransaction,
  double? maxTransaction,
  List<String> applicableCards = const ['Credit Card'],
}) {
  final until = validUntil ?? DateTime.now().add(const Duration(days: 365));
  return BankOffer(
    uniqueId: id,
    title: title,
    description: title,
    merchantName: merchant,
    bankName: bankCode,
    bankCode: bankCode,
    category: category,
    subcategories: const [],
    images: const [],
    quality: QualityScore(confidenceScore: 0.9, grade: 'A'),
    discount: OfferSemantics.parseDiscount(
      discountRaw,
      evidence: discountEvidence ?? title,
    ),
    validity:
        noExpiry
            ? ValidityPeriod(
              validFrom: ValidityPeriod.unknownStartSentinel,
              validUntil: ValidityPeriod.noExpirySentinel,
            )
            : ValidityPeriod(
              validFrom: DateTime(2026, 1, 1),
              validUntil: until,
            ),
    locations:
        locations ??
        [
          Location(
            name: 'Kandy City Centre',
            address: '5 Dalada Veediya, Kandy',
            district: 'Kandy',
            city: 'Kandy',
            latitude: 7.2906,
            longitude: 80.6337,
          ),
        ],
    locationScope: scope,
    applicableCards: applicableCards,
    cardEligibility: eligibility,
    generalTerms: generalTerms,
    sourceUrl: sourceUrl,
    distanceKm: distanceKm,
    minTransaction: minTransaction,
    maxTransaction: maxTransaction,
  );
}

/// In-memory [OfferRepository] that records what it was asked for.
class FakeOfferRepository implements OfferRepository {
  FakeOfferRepository({
    this.offers = const [],
    this.banks = const [],
    this.nearby = const [],
  });

  List<BankOffer> offers;
  List<BankSummary> banks;
  List<BankOffer> nearby;

  Object? failure;
  Completer<List<dynamic>>? gate;
  final List<({String? bank, String? category, String? scope})> queries = [];
  final List<({double lat, double lng, double radius})> nearbyCalls = [];
  final List<String> searches = [];

  @override
  Future<List<dynamic>> queryOffers({
    String? bank,
    String? category,
    String? locationScope,
  }) async {
    queries.add((bank: bank, category: category, scope: locationScope));
    if (failure != null) throw failure!;
    if (gate != null) return gate!.future;
    return offers
        .where((o) => bank == null || o.bankCode == bank)
        .where((o) => locationScope == null || o.locationScope == locationScope)
        .toList();
  }

  @override
  Future<List<dynamic>> getAllOffers() async {
    if (failure != null) throw failure!;
    return offers;
  }

  @override
  Future<List<dynamic>> getOffersByBank(String bankCode) async =>
      offers.where((o) => o.bankCode == bankCode).toList();

  @override
  Future<List<BankSummary>> getBanks() async {
    if (failure != null) throw failure!;
    return banks;
  }

  @override
  Future<List<dynamic>> getNearbyOffers({
    required double latitude,
    required double longitude,
    required double radius,
  }) async {
    nearbyCalls.add((lat: latitude, lng: longitude, radius: radius));
    if (failure != null) throw failure!;
    return nearby;
  }

  @override
  Future<List<dynamic>> searchOffers(String query) async {
    searches.add(query);
    if (failure != null) throw failure!;
    if (gate != null) return gate!.future;
    return offers
        .where((o) => o.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<dynamic>> getOffersByType(OfferType type) async => offers;

  @override
  Future<List<dynamic>> filterOffers({
    OfferType? type,
    String? category,
    String? district,
    double? maxDistance,
    double? latitude,
    double? longitude,
  }) async => offers;

  @override
  Future<dynamic> getOfferById(String id) async {
    for (final o in offers) {
      if (o.uniqueId == id) return o;
    }
    return null;
  }

  @override
  Future<List<dynamic>> getSimilarOffers(
    String offerId,
    OfferType type,
  ) async => const [];
}

/// A [LocationService] whose answers are scripted.
class FakeLocationService extends LocationService {
  FakeLocationService({
    this.servicesEnabled = true,
    this.permission = LocationPermission.whileInUse,
    this.afterRequest,
    this.position,
  });

  bool servicesEnabled;
  LocationPermission permission;

  /// What the permission becomes after the user answers the prompt.
  LocationPermission? afterRequest;
  Position? position;
  int requests = 0;
  int positionReads = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => servicesEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    permission = afterRequest ?? permission;
    return permission;
  }

  @override
  Future<Position?> getCurrentPosition() async {
    positionReads++;
    return position;
  }

  @override
  Future<bool> openAppSettings() async => true;
}

Position testPosition(double lat, double lng) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime(2026, 1, 1),
  accuracy: 10,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

/// A localized app shell for widget tests. [width] and [textScale] let tests
/// check small phones and large accessibility text.
Widget localized(
  Widget child, {
  Locale locale = const Locale('en'),
  double textScale = 1.0,
  double? width,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: LanguageService.supportedLocales,
  builder:
      (context, home) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          size: width == null ? null : Size(width, 900),
        ),
        child: home!,
      ),
  home: Scaffold(body: child),
);
