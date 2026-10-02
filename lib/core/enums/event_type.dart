enum EventType {
  foodFestival,
  concert,
  exhibition,
  workshop,
  conference,
  sports,
  cultural,
  other,
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.foodFestival:
        return 'Food Festival';
      case EventType.concert:
        return 'Concert';
      case EventType.exhibition:
        return 'Exhibition';
      case EventType.workshop:
        return 'Workshop';
      case EventType.conference:
        return 'Conference';
      case EventType.sports:
        return 'Sports';
      case EventType.cultural:
        return 'Cultural';
      case EventType.other:
        return 'Other';
    }
  }
}
