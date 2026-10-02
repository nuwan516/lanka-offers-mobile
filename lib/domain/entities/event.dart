import 'base_offer.dart';
import 'venue.dart';
import 'event_date_time.dart';
import 'ticketing.dart';
import 'amenities.dart';
import '../../core/enums/event_type.dart';

class Event extends BaseOffer {
  final String providerName;
  final EventType eventType;
  final String organizer;
  final Venue venue;
  final EventDateTime eventDateTime;
  final Ticketing? ticketing;
  final Amenities amenities;
  final String ageRestriction; // 'all_ages', '18+', '21+'
  final bool familyFriendly;

  Event({
    required super.uniqueId,
    required super.title,
    required super.description,
    required super.category,
    required super.subcategories,
    required super.locations,
    required super.validity,
    super.contact,
    required super.images,
    super.featuredImage,
    required super.quality,
    super.metrics,
    required this.providerName,
    required this.eventType,
    required this.organizer,
    required this.venue,
    required this.eventDateTime,
    this.ticketing,
    required this.amenities,
    required this.ageRestriction,
    required this.familyFriendly,
  });

  String getDisplayValue() {
    if (ticketing != null && ticketing!.required) {
      if (ticketing!.priceRange != null) {
        return 'Rs. ${ticketing!.priceRange!.min} - Rs. ${ticketing!.priceRange!.max}';
      }
      return 'Tickets Available';
    }
    return 'Free Entry';
  }

  @override
  List<Object?> get props => [
    ...super.props,
    providerName,
    eventType,
    organizer,
    venue,
    eventDateTime,
    ticketing,
    amenities,
    ageRestriction,
    familyFriendly,
  ];
}
