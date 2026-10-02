class Restrictions {
  final List<String> keyRestrictions;
  final bool? bookingRequired;
  final double? minTransaction;
  final double? maxTransaction;

  Restrictions({
    required this.keyRestrictions,
    this.bookingRequired,
    this.minTransaction,
    this.maxTransaction,
  });
}
