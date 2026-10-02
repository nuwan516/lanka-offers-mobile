class Discount {
  final String type; // 'percentage', 'amount', 'bogo', 'installment'
  final dynamic value; // Can be double, String, etc.
  final String description;

  Discount({
    required this.type,
    required this.value,
    required this.description,
  });
}
