import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/banks.dart';
import '../../../core/semantics/offer_semantics.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../../domain/entities/bank_summary.dart';
import '../../../domain/entities/card_eligibility.dart';
import '../../../domain/entities/contact_info.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/entities/quality_score.dart';
import '../../../domain/entities/restrictions.dart';
import '../../../domain/entities/validity_period.dart';

/// Fetches real offer data from the Lanka Offers Express API.
/// Connects to backend-api (port 3001) in development or production.
class ApiOffersDataSource {
  ApiOffersDataSource();

  static const String _prodUrl = 'https://api.lanka-offers.me';

  String get _base {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return _prodUrl;
  }

  Future<List<BankOffer>> fetchOffers({
    String? bank,
    String? category,
    String? search,
    String? merchant,
    String? locationScope,
    int limit = 100,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (bank != null && bank.isNotEmpty) params['bank'] = bank.toLowerCase();
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (merchant != null && merchant.isNotEmpty) params['merchant'] = merchant;
    if (locationScope != null && locationScope.isNotEmpty) {
      params['locationScope'] = locationScope;
    }

    return (await _getOffersPage(params)).items;
  }

  Future<({List<BankOffer> items, int total})> fetchOffersPage({
    String? bank,
    String? category,
    String? search,
    String? merchant,
    String? locationScope,
    required int limit,
    required int offset,
  }) {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (bank != null && bank.isNotEmpty) params['bank'] = bank.toLowerCase();
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (merchant != null && merchant.isNotEmpty) params['merchant'] = merchant;
    if (locationScope != null && locationScope.isNotEmpty) {
      params['locationScope'] = locationScope;
    }
    return _getOffersPage(params);
  }

  Future<({List<BankOffer> items, int total})> _getOffersPage(
    Map<String, String> params,
  ) async {
    final uri = Uri.parse('$_base/api/offers').replace(queryParameters: params);
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = (body['items'] as List<dynamic>? ?? []);
    final items = raw.map((j) => _map(j as Map<String, dynamic>)).toList();
    final total = body['total'];
    return (items: items, total: total is num ? total.toInt() : items.length);
  }

  /// Largest page the public API serves (backend PAGINATION.MAX_LIMIT).
  static const int _maxPage = 500;

  /// Every offer matching the filters, fetched page by page. A single default
  /// page is only 100 of several hundred offers.
  Future<List<BankOffer>> fetchAllOffers({
    String? bank,
    String? category,
    String? search,
    String? merchant,
    String? locationScope,
  }) async {
    final all = <BankOffer>[];
    var offset = 0;
    for (;;) {
      final page = await fetchOffersPage(
        bank: bank,
        category: category,
        search: search,
        merchant: merchant,
        locationScope: locationScope,
        limit: _maxPage,
        offset: offset,
      );
      all.addAll(page.items);
      offset += page.items.length;
      if (page.items.isEmpty || offset >= page.total) break;
    }
    return all;
  }

  /// The ten supported banks with live active-offer counts.
  Future<List<BankSummary>> fetchBanks() async {
    final uri = Uri.parse('$_base/api/banks');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }
    final body = jsonDecode(response.body);
    final list =
        body is List ? body : (body['items'] ?? body['data'] ?? []) as List;
    return list
        .whereType<Map<String, dynamic>>()
        .map((b) {
          final count = b['activeOfferCount'];
          return BankSummary(
            code: (_str(b['code']) ?? '').toLowerCase(),
            name: _str(b['name']) ?? '',
            activeOfferCount:
                count is num ? count.toInt() : int.tryParse('$count'),
            cardTypesSupported: _strList(b['cardTypesSupported']),
          );
        })
        .where((b) => b.code.isNotEmpty)
        .toList();
  }

  Future<List<BankOffer>> fetchNearbyOffers({
    required double lat,
    required double lng,
    double radius = 25.0,
    String? bank,
    String? category,
    String? search,
    int limit = 100,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'lat': lat.toString(),
      'lng': lng.toString(),
      'radius': radius.toString(),
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (bank != null && bank.isNotEmpty) params['bank'] = bank.toLowerCase();
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse(
      '$_base/api/offers/nearby',
    ).replace(queryParameters: params);
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (body['items'] as List<dynamic>? ?? []);
    return items.map((j) => _map(j as Map<String, dynamic>)).toList();
  }

  Future<BankOffer?> fetchOfferById(String id) async {
    final uri = Uri.parse('$_base/api/offers/$id');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }
    return _map(jsonDecode(response.body) as Map<String, dynamic>);
  }

  BankOffer _map(Map<String, dynamic> j) {
    // raw_offer is only present on the detail endpoint
    final raw = j['raw_offer'] as Map<String, dynamic>?;
    final offerData = raw?['offer'] as Map<String, dynamic>?;
    final merchantData = raw?['merchant'] as Map<String, dynamic>?;

    final description =
        _str(j['description']) ??
        _str(offerData?['description'])?.trim() ??
        _str(j['title']) ??
        '';

    final discount = OfferSemantics.parseDiscount(
      j['discount_percentage'],
      evidence: '${j['title'] ?? ''} ${j['description'] ?? ''}',
    );

    CardEligibility? cardEligibility;
    final rawElig = j['card_eligibility'];
    if (rawElig != null) {
      if (rawElig is Map<String, dynamic>) {
        cardEligibility = CardEligibility.fromJson(rawElig);
      } else if (rawElig is String && rawElig.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(rawElig);
          if (decoded is Map<String, dynamic>) {
            cardEligibility = CardEligibility.fromJson(decoded);
          }
        } catch (_) {}
      }
    }

    final cards = <String>[];
    if (cardEligibility != null && cardEligibility.isNotEmpty) {
      if (cardEligibility.includedCards.isNotEmpty) {
        cards.addAll(cardEligibility.includedCards);
      }
      cards.addAll(cardEligibility.cardTypes);
      if (cardEligibility.networks.isNotEmpty) {
        cards.addAll(cardEligibility.networks);
      }
    }
    if (cards.isEmpty) {
      final rawTokens =
          _str(j['card_type'])
              ?.split(',')
              .map((c) => c.trim())
              .where((c) => c.isNotEmpty)
              .toList() ??
          [];
      for (final t in rawTokens) {
        final l = t.toLowerCase();
        if (l == 'credit') {
          cards.add('Credit Card');
        } else if (l == 'debit') {
          cards.add('Debit Card');
        } else if (l == 'credit/debit') {
          cards.add('Credit Card');
          cards.add('Debit Card');
        } else {
          cards.add(t);
        }
      }
    }

    // Missing validity must never be presented as a real scraped date — use
    // stable sentinels the UI recognizes, not values relative to "now"
    // (which previously made evergreen offers look like they were about to
    // expire in 30 days, and newly-changed offers look like they'd just
    // started yesterday).
    final validFrom =
        _parseDate(j['valid_from']) ?? ValidityPeriod.unknownStartSentinel;
    final validUntil =
        _parseDate(j['valid_to']) ?? ValidityPeriod.noExpirySentinel;

    final locations = _parseLocations(j['geo_locations'] as List<dynamic>?);

    final rulePassed = j['rule_passed'] as bool? ?? true;

    // Booking/restrictions from raw_offer
    Restrictions? restrictions;
    final bookingRequired = offerData?['bookingRequired'] as bool?;
    final offerRestrictions =
        (offerData?['restrictions'] as List<dynamic>?)
            ?.whereType<String>()
            .toList();
    if (bookingRequired != null || offerRestrictions?.isNotEmpty == true) {
      restrictions = Restrictions(
        keyRestrictions: offerRestrictions ?? [],
        bookingRequired: bookingRequired,
      );
    }

    // Contact
    ContactInfo? contact;
    if (merchantData != null) {
      final phones =
          (merchantData['phone'] as List<dynamic>?)
              ?.whereType<String>()
              .where((p) => p.isNotEmpty)
              .toList();
      final emails =
          (merchantData['email'] as List<dynamic>?)
              ?.whereType<String>()
              .where((e) => e.isNotEmpty)
              .toList();
      final website =
          _str(merchantData['website']) ??
          _str(raw?['sourceUrl']) ??
          _str(j['source_url']);
      if (phones?.isNotEmpty == true ||
          emails?.isNotEmpty == true ||
          website != null) {
        contact = ContactInfo(phone: phones, email: emails, website: website);
      }
    }

    return BankOffer(
      uniqueId: _str(j['unique_id']) ?? _str(j['id']) ?? '',
      title: _str(j['title']) ?? 'Untitled',
      description: description,
      category: _str(j['category']) ?? 'General',
      subcategories: const [],
      locations: locations,
      validity: ValidityPeriod(validFrom: validFrom, validUntil: validUntil),
      contact: contact,
      images: const [],
      featuredImage: null,
      quality: QualityScore(
        confidenceScore: rulePassed ? 0.75 : 0.45,
        grade: rulePassed ? 'B' : 'C',
      ),
      bankName: _bankLabel(_str(j['bank']) ?? ''),
      bankCode: _str(j['bank'])?.toLowerCase(),
      sourceUrl: _str(j['source_url']) ?? _str(raw?['sourceUrl']),
      generalTerms: _strList(offerData?['generalTerms']),
      merchantName:
          _str(j['merchant_name'])?.isNotEmpty == true
              ? j['merchant_name'] as String
              : _str(j['title']) ?? '',
      canonicalMerchant: _str(j['canonical_merchant']),
      locationScope: _str(j['location_scope']),
      merchantLocation: _str(j['merchant_location']),
      terms: _str(j['terms']),
      distanceKm: _dbl(j['distance_km']),
      discount: discount,
      applicableCards: cards.toSet().toList(),
      cardEligibility: cardEligibility,
      restrictions: restrictions,
      minTransaction: _parseMinTransaction(raw),
      maxTransaction: _parseMaxTransaction(raw),
    );
  }

  List<Location> _parseLocations(List<dynamic>? geoList) {
    if (geoList == null || geoList.isEmpty) return [];
    final result = <Location>[];
    for (final item in geoList) {
      if (item is! Map<String, dynamic>) continue;
      final lat = _dbl(item['lat'] ?? item['latitude']);
      final lng = _dbl(item['lng'] ?? item['lon'] ?? item['longitude']);
      if (lat == null || lng == null) continue;
      result.add(
        Location(
          name: _str(item['name'] ?? item['address']) ?? '',
          address: _str(item['address']) ?? '',
          district: _str(item['district']) ?? '',
          city: _str(item['city']) ?? '',
          latitude: lat,
          longitude: lng,
        ),
      );
    }
    return result;
  }

  double? _parseMinTransaction(Map<String, dynamic>? raw) {
    final tx = raw?['transactionRange'] as Map<String, dynamic>?;
    return _dbl(tx?['min']);
  }

  double? _parseMaxTransaction(Map<String, dynamic>? raw) {
    final tx = raw?['transactionRange'] as Map<String, dynamic>?;
    return _dbl(tx?['max']);
  }

  String _bankLabel(String bank) =>
      CanonicalBanks.lookup(bank)?.name ?? bank.toUpperCase();

  static final RegExp _dateOnlyRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    try {
      // Date-only (YYYY-MM-DD): represents a calendar day in Sri Lanka.
      // Parse as UTC date so no local device timezone shifts the calendar date.
      if (_dateOnlyRegex.hasMatch(s)) {
        final parts = s.split('-');
        return DateTime.utc(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }

      // Full timestamp: normalize to Asia/Colombo calendar day.
      final dt = DateTime.parse(s);
      final colombo = dt.toUtc().add(OfferSemantics.colomboOffset);
      return DateTime.utc(
        colombo.year,
        colombo.month,
        colombo.day,
        colombo.hour,
        colombo.minute,
        colombo.second,
      );
    } catch (_) {
      return null;
    }
  }

  List<String> _strList(dynamic v) =>
      v is List ? v.map((e) => _str(e)).whereType<String>().toList() : const [];

  String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
