import 'package:equatable/equatable.dart';
import '../../../../core/enums/event_type.dart';

abstract class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

class LoadEvents extends EventsEvent {
  const LoadEvents();
}

class RefreshEvents extends EventsEvent {
  const RefreshEvents();
}

class FilterEventsByType extends EventsEvent {
  final EventType? eventType;

  const FilterEventsByType({this.eventType});

  @override
  List<Object?> get props => [eventType];
}

class SortEvents extends EventsEvent {
  final String sortBy; // 'date', 'popularity', 'distance'

  const SortEvents(this.sortBy);

  @override
  List<Object?> get props => [sortBy];
}

class SearchEvents extends EventsEvent {
  final String query;

  const SearchEvents(this.query);

  @override
  List<Object?> get props => [query];
}
