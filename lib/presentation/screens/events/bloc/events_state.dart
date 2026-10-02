import 'package:equatable/equatable.dart';
import '../../../../domain/entities/event.dart' as event_entity;
import '../../../../core/enums/event_type.dart';

abstract class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {
  const EventsInitial();
}

class EventsLoading extends EventsState {
  const EventsLoading();
}

class EventsLoaded extends EventsState {
  final List<event_entity.Event> events;
  final EventType? selectedEventType;
  final String? sortBy;
  final String? searchQuery;

  const EventsLoaded({
    required this.events,
    this.selectedEventType,
    this.sortBy,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [events, selectedEventType, sortBy, searchQuery];
}

class EventsError extends EventsState {
  final String message;

  const EventsError(this.message);

  @override
  List<Object?> get props => [message];
}
