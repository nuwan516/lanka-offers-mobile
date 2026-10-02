import 'price_range.dart';

class Ticketing {
  final bool required;
  final PriceRange? priceRange;
  final bool? earlyBirdAvailable;
  final DateTime? earlyBirdDeadline;
  final int? ticketsAvailable;
  final int? ticketsSold;
  final String? bookingUrl;

  Ticketing({
    required this.required,
    this.priceRange,
    this.earlyBirdAvailable,
    this.earlyBirdDeadline,
    this.ticketsAvailable,
    this.ticketsSold,
    this.bookingUrl,
  });
}
