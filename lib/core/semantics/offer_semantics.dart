import '../../domain/entities/bank_offer.dart';
import '../../domain/entities/discount.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/validity_period.dart';

/// Single place for the financial wording rules shared by every screen.
///
/// The public API has no reliable "up to" flag, no structured maximum-discount
/// cap and no structured minimum spend, so nothing here invents them: the
/// qualifier comes only from the bank's own wording, and cap/minimum
/// statements are quoted verbatim from the terms rather than interpreted.
class OfferSemantics {
  OfferSemantics._();

  /// "Up to 50%" / "up to Rs. 50%": the captured group is the percentage.
  static final RegExp _upToPercent = RegExp(
    r'\bup\s*to\s+(?:rs\.?\s*)?(\d+(?:\.\d+)?)\s*%',
    caseSensitive: false,
  );

  /// Sri Lanka has no daylight saving; UTC+05:30 all year.
  static const Duration colomboOffset = Duration(hours: 5, minutes: 30);

  // ── Discount ───────────────────────────────────────────────────────────

  /// True only when [evidence] (title/description) says "up to N%" for the
  /// same figure as [percent]. "Up to 12 months 0% installments" must not turn
  /// an unrelated plain discount into an "up to" discount.
  static bool isUpToPercent(double percent, String? evidence) {
    if (evidence == null || evidence.isEmpty) return false;
    return _upToPercent
        .allMatches(evidence)
        .any((m) => double.parse(m.group(1)!).round() == percent.round());
  }

  /// Parses the API's `discount_percentage`, which is a bare number in the
  /// common case and free text otherwise (kept verbatim, never dropped).
  static Discount? parseDiscount(dynamic raw, {String? evidence}) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;

    final pct = double.tryParse(text);
    if (pct != null) {
      if (pct <= 0) return null;
      final upTo = isUpToPercent(pct, evidence);
      return Discount(
        type: 'percentage',
        value: pct,
        description: '${upTo ? 'Up to ' : ''}${pct.toStringAsFixed(0)}% off',
        isUpTo: upTo,
      );
    }

    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(text);
    return Discount(
      type: 'text',
      value: match != null ? double.tryParse(match.group(1)!) : null,
      description: text,
    );
  }

  /// Whole-number percentage for display ("30"), or null when [discount] is
  /// not a clean percentage.
  static String? percentLabel(Discount? discount) {
    if (discount == null || discount.type != 'percentage') return null;
    final v = discount.value;
    if (v is! num) return null;
    return '${v.round()}%';
  }

  // ── Validity (Sri Lanka calendar days) ─────────────────────────────────

  /// The calendar date of [instant] in Sri Lanka, as a UTC midnight value so
  /// two dates can be compared and subtracted without time-zone drift.
  static DateTime colomboDate(DateTime instant) {
    final c = instant.toUtc().add(colomboOffset);
    return DateTime.utc(c.year, c.month, c.day);
  }

  /// An offer stays valid through the whole of its last day (Sri Lanka time).
  static bool isExpired(ValidityPeriod validity, {DateTime? now}) {
    if (validity.hasNoConfiguredExpiry) return false;
    final today = colomboDate(now ?? DateTime.now());
    return colomboDate(validity.validUntil).isBefore(today);
  }

  /// Days remaining including today (0 = last day), or null when the offer has
  /// no configured expiry or has already expired.
  static int? daysLeft(ValidityPeriod validity, {DateTime? now}) {
    if (validity.hasNoConfiguredExpiry) return null;
    final today = colomboDate(now ?? DateTime.now());
    final days = colomboDate(validity.validUntil).difference(today).inDays;
    return days < 0 ? null : days;
  }

  static bool isEndingSoon(ValidityPeriod validity, {DateTime? now}) {
    final days = daysLeft(validity, now: now);
    return days != null && days <= 7;
  }

  // ── Terms statements (verbatim, never interpreted) ─────────────────────

  static final RegExp _capStatement = RegExp(
    r'(max(imum)?\s+(discount|saving|cashback)|discount\s+(is\s+)?(capped|limited)|capped\s+(at|to))',
    caseSensitive: false,
  );

  static final RegExp _minSpendStatement = RegExp(
    r'(min(imum)?\s+(spend|bill|transaction|purchase|value)|spend\s+(of\s+)?(at\s+least|over|above))',
    caseSensitive: false,
  );

  /// Term lines that mention a maximum-discount cap, quoted as written.
  static List<String> capStatements(Iterable<String> terms) =>
      terms.where((t) => _capStatement.hasMatch(t)).toList();

  /// Term lines that mention a minimum spend, quoted as written.
  static List<String> minSpendStatements(Iterable<String> terms) =>
      terms.where((t) => _minSpendStatement.hasMatch(t)).toList();

  // ── Location confidence ────────────────────────────────────────────────

  /// Scopes for which a map pin would be false precision.
  static const Set<String> _unpinnableScopes = {
    'ONLINE',
    'NATIONWIDE',
    'SELECTED_OUTLETS',
    'UNRESOLVED',
  };

  /// The geocoder sometimes resolves "Colombo, Sri Lanka" to the city centre and
  /// reports it as resolved. The API carries no precision flag, so a location
  /// whose address is only a place name (no street, no number, at most two
  /// words) is treated as area-level: it is never pinned and never given a
  /// distance, because that would present a town centre as a branch.
  static bool isAreaLevel(Location location) {
    final raw =
        (location.address.isNotEmpty ? location.address : location.name).trim();
    if (raw.isEmpty) return true;
    final place =
        raw
            .replaceFirst(
              RegExp(r',?\s*sri lanka\s*$', caseSensitive: false),
              '',
            )
            .trim();
    if (place.isEmpty) return true;
    final hasDigit = RegExp(r'\d').hasMatch(place);
    final hasComma = place.contains(',');
    final words = place.split(RegExp(r'\s+')).length;
    return !hasDigit && !hasComma && words <= 2;
  }

  /// Locations that are a real branch address rather than just an area.
  static List<Location> confirmedBranches(BankOffer offer) =>
      offer.locations.where((l) => !isAreaLevel(l)).toList();

  static bool hasConfirmedBranch(BankOffer offer) =>
      !_unpinnableScopes.contains(offer.locationScope) &&
      confirmedBranches(offer).isNotEmpty;

  /// Only offers with a confirmed branch may be pinned or given a distance.
  static bool canShowOnMap(BankOffer offer) => hasConfirmedBranch(offer);
}
