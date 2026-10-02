class Deal {
  final String type; // 'discount', 'cashback', 'freebie'
  final double value;
  final String description;
  final double? originalPrice;
  final double? salePrice;

  Deal({
    required this.type,
    required this.value,
    required this.description,
    this.originalPrice,
    this.salePrice,
  });
}
