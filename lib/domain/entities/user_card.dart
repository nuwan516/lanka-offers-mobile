class UserCard {
  final String bank;
  final String cardType;
  final String? network;
  final String? tier;
  final bool isCorporate;

  const UserCard({
    required this.bank,
    required this.cardType,
    this.network,
    this.tier,
    this.isCorporate = false,
  });

  String get displayName {
    final parts = <String>[bank];
    if (network != null && network!.isNotEmpty) parts.add(network!);
    if (tier != null && tier!.isNotEmpty) parts.add(tier!);
    if (isCorporate) parts.add('Corporate');
    parts.add(cardType);
    return parts.join(' ');
  }

  Map<String, dynamic> toJson() => {
    'bank': bank,
    'cardType': cardType,
    if (network != null) 'network': network,
    if (tier != null) 'tier': tier,
    'isCorporate': isCorporate,
  };

  factory UserCard.fromJson(Map<String, dynamic> json) => UserCard(
    bank: json['bank']?.toString() ?? '',
    cardType: json['cardType']?.toString() ?? 'Credit Card',
    network: json['network']?.toString(),
    tier: json['tier']?.toString(),
    isCorporate: json['isCorporate'] as bool? ?? false,
  );

  /// String serialization for storage in List<String> savedCards
  String toStorageString() {
    return [
      bank,
      cardType,
      network ?? '',
      tier ?? '',
      isCorporate ? '1' : '0',
    ].join('|');
  }

  factory UserCard.fromStorageString(String str) {
    final parts = str.split('|');
    if (parts.length >= 2) {
      return UserCard(
        bank: parts[0].trim(),
        cardType: parts[1].trim(),
        network:
            parts.length > 2 && parts[2].trim().isNotEmpty
                ? parts[2].trim()
                : null,
        tier:
            parts.length > 3 && parts[3].trim().isNotEmpty
                ? parts[3].trim()
                : null,
        isCorporate: parts.length > 4 && parts[4].trim() == '1',
      );
    }
    // Fallback if plain string
    return UserCard(bank: str.trim(), cardType: 'Credit Card');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCard &&
          runtimeType == other.runtimeType &&
          bank.toLowerCase() == other.bank.toLowerCase() &&
          cardType.toLowerCase() == other.cardType.toLowerCase() &&
          network?.toLowerCase() == other.network?.toLowerCase() &&
          tier?.toLowerCase() == other.tier?.toLowerCase() &&
          isCorporate == other.isCorporate;

  @override
  int get hashCode => Object.hash(
    bank.toLowerCase(),
    cardType.toLowerCase(),
    network?.toLowerCase(),
    tier?.toLowerCase(),
    isCorporate,
  );
}
