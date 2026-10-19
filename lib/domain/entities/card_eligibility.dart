class CardEligibility {
  final List<String> cardTypes;
  final List<String> networks;
  final List<String> includedCards;
  final List<String> excludedCards;
  final List<String> restrictions;

  const CardEligibility({
    this.cardTypes = const [],
    this.networks = const [],
    this.includedCards = const [],
    this.excludedCards = const [],
    this.restrictions = const [],
  });

  bool get isEmpty =>
      cardTypes.isEmpty &&
      networks.isEmpty &&
      includedCards.isEmpty &&
      excludedCards.isEmpty &&
      restrictions.isEmpty;

  bool get isNotEmpty => !isEmpty;

  bool get isCreditOnly =>
      cardTypes.contains('Credit Card') && !cardTypes.contains('Debit Card');

  bool get isDebitOnly =>
      cardTypes.contains('Debit Card') && !cardTypes.contains('Credit Card');

  bool get isCreditAndDebit =>
      cardTypes.contains('Credit Card') && cardTypes.contains('Debit Card');

  bool get hasExclusions => excludedCards.isNotEmpty;

  bool get hasTierRequirements => includedCards.isNotEmpty;

  /// Human-friendly display summary of card eligibility requirements
  String get displaySummary {
    final parts = <String>[];

    if (includedCards.isNotEmpty) {
      parts.add(includedCards.join(' / '));
    } else if (cardTypes.isNotEmpty) {
      parts.add(cardTypes.join(' & '));
    }

    if (networks.isNotEmpty) {
      parts.add('(${networks.join(', ')})');
    }

    if (excludedCards.isNotEmpty) {
      parts.add('[Excludes: ${excludedCards.join(', ')}]');
    }

    return parts.isEmpty ? 'All Cards' : parts.join(' ');
  }

  factory CardEligibility.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CardEligibility();

    List<String> parseList(String key) {
      final raw = json[key];
      if (raw is! List<dynamic>) return const [];
      return raw
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return CardEligibility(
      cardTypes: parseList('cardTypes'),
      networks: parseList('networks'),
      includedCards: parseList('includedCards'),
      excludedCards: parseList('excludedCards'),
      restrictions: parseList('restrictions'),
    );
  }

  Map<String, dynamic> toJson() => {
    'cardTypes': cardTypes,
    'networks': networks,
    'includedCards': includedCards,
    'excludedCards': excludedCards,
    'restrictions': restrictions,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardEligibility &&
          runtimeType == other.runtimeType &&
          _listEquals(cardTypes, other.cardTypes) &&
          _listEquals(networks, other.networks) &&
          _listEquals(includedCards, other.includedCards) &&
          _listEquals(excludedCards, other.excludedCards) &&
          _listEquals(restrictions, other.restrictions);

  @override
  int get hashCode => Object.hashAll([
    ...cardTypes,
    ...networks,
    ...includedCards,
    ...excludedCards,
    ...restrictions,
  ]);

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
