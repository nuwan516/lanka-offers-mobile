class ValidityPeriod {
  final DateTime validFrom;
  final DateTime validUntil;
  final String? daysApplicable; // 'All Days', 'Weekdays', 'Weekends'
  final String? timeRestrictions; // '2PM - 5PM'

  ValidityPeriod({
    required this.validFrom,
    required this.validUntil,
    this.daysApplicable,
    this.timeRestrictions,
  });

  /// [validFrom]/[validUntil] are non-nullable, but the source offer may not
  /// report a start/end date at all. These sentinels stand in for "unknown"
  /// without ever being displayed as if they were a real scraped date —
  /// UI code must check for them and show a neutral label instead.
  static final DateTime unknownStartSentinel = DateTime(2020, 1, 1);
  static final DateTime noExpirySentinel = DateTime(2099, 12, 31);

  bool get hasNoConfiguredExpiry =>
      validUntil.isAtSameMomentAs(noExpirySentinel);
}
