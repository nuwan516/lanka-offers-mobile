class Discount {
  final String type; // 'percentage', 'amount', 'bogo', 'installment', 'text'
  final dynamic value; // Can be double, String, etc.
  final String description;

  /// True only when the bank's own wording says "up to" for this figure.
  final bool isUpTo;

  Discount({
    required this.type,
    required this.value,
    required this.description,
    this.isUpTo = false,
  });
}
