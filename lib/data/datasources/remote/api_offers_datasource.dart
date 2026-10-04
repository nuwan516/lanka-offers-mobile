import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../domain/entities/bank_offer.dart';
import '../../../domain/entities/card_eligibility.dart';
import '../../../domain/entities/contact_info.dart';
import '../../../domain/entities/discount.dart';
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
    if (kDebugMode) {
      if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3001';
      return 'http://localhost:3001';
    }
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

    final uri = Uri.parse('$_base/api/offers').replace(queryParameters: params);
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (body['items'] as List<dynamic>? ?? []);
    return items
        .map((j) => _map(j as Map<String, dynamic>))
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

    final uri =
        Uri.parse('$_base/api/offers/nearby').replace(queryParameters: params);
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (body['items'] as List<dynamic>? ?? []);
    return items
        .map((j) => _map(j as Map<String, dynamic>))
        .toList();
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

    final description = _str(j['description']) ??
        _str(offerData?['description'])?.trim() ??
        _str(j['title']) ??
        '';

    final discount = _parseDiscount(j['discount_percentage']);

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
      final rawTokens = _str(j['card_type'])
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
    final validFrom = _parseDate(j['valid_from']) ??
        ValidityPeriod.unknownStartSentinel;
    final validUntil = _parseDate(j['valid_to']) ??
        ValidityPeriod.noExpirySentinel;

    final locations =
        _parseLocations(j['geo_locations'] as List<dynamic>?);

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
      final phones = (merchantData['phone'] as List<dynamic>?)
          ?.whereType<String>()
          .where((p) => p.isNotEmpty)
          .toList();
      final emails = (merchantData['email'] as List<dynamic>?)
          ?.whereType<String>()
          .where((e) => e.isNotEmpty)
          .toList();
      final website = _str(merchantData['website']) ??
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
      merchantName: _str(j['merchant_name'])?.isNotEmpty == true
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

  Discount? _parseDiscount(dynamic raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;

    // A clean numeric value (e.g. "20") — the common case.
    final pct = double.tryParse(text);
    if (pct != null) {
      return Discount(
        type: 'percentage',
        value: pct,
        description: '${pct.toStringAsFixed(0)}% off',
      );
    }

    // Anything else (e.g. "Up to 20%", "20% (min. spend Rs. 5,000)") must
    // keep its original wording — forcing it through double.tryParse alone
    // would drop the whole discount silently. `type: 'text'` routes both
    // getDisplayValue() and the offer card's _benefit() to use
    // `description` verbatim instead of a synthesized "$value% off".
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(text);
    return Discount(
      type: 'text',
      value: match != null ? double.tryParse(match.group(1)!) : null,
      description: text,
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
      result.add(Location(
        name: _str(item['name'] ?? item['address']) ?? '',
        address: _str(item['address']) ?? '',
        district: _str(item['district']) ?? '',
        city: _str(item['city']) ?? '',
        latitude: lat,
        longitude: lng,
      ));
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

  String _bankLabel(String bank) => switch (bank.toLowerCase()) {
        'hnb' => 'HNB',
        'boc' => 'Bank of Ceylon',
        'combank' => 'Commercial Bank',
        'dfcc' => 'DFCC Bank',
        'ndb' => 'NDB Bank',
        'nsb' => 'NSB',
        'pabc' => 'Pan Asia Bank',
        'peoples' => "People's Bank",
        'sampath' => 'Sampath Bank',
        'seylan' => 'Seylan Bank',
        _ => bank.toUpperCase(),
      };

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

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
