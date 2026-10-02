class UserPreferences {
  final List<String> selectedBanks;
  final List<String> cardTypes;
  final List<String> cardNetworks;
  final List<String> preferredCategories;
  final List<String> preferredDistricts;
  final double? preferredRadiusKm;
  final List<String> savedCards;
  final bool notificationsEnabled;

  UserPreferences({
    this.selectedBanks = const [],
    this.cardTypes = const [],
    this.cardNetworks = const [],
    required this.preferredCategories,
    required this.preferredDistricts,
    this.preferredRadiusKm,
    required this.savedCards,
    required this.notificationsEnabled,
  });

  Map<String, Object?> toJson() => {
    'selectedBanks': selectedBanks,
    'cardTypes': cardTypes,
    'cardNetworks': cardNetworks,
    'preferredCategories': preferredCategories,
    'preferredDistricts': preferredDistricts,
    'preferredRadiusKm': preferredRadiusKm,
    'savedCards': savedCards,
    'notificationsEnabled': notificationsEnabled,
  };

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();
    return UserPreferences(
      selectedBanks: strings('selectedBanks'),
      cardTypes: strings('cardTypes'),
      cardNetworks: strings('cardNetworks'),
      preferredCategories: strings('preferredCategories'),
      preferredDistricts: strings('preferredDistricts'),
      preferredRadiusKm: (json['preferredRadiusKm'] as num?)?.toDouble(),
      savedCards: strings('savedCards'),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
    );
  }
}
