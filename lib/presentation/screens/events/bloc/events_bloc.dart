import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/offer_repository.dart';
import '../../../../core/enums/offer_type.dart';
import '../../../../domain/entities/event.dart' as event_entity;
import 'events_event.dart';
import 'events_state.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final OfferRepository offerRepository;

  EventsBloc({required this.offerRepository}) : super(const EventsInitial()) {
    on<LoadEvents>(_onLoadEvents);
    on<RefreshEvents>(_onRefreshEvents);
    on<FilterEventsByType>(_onFilterEventsByType);
    on<SortEvents>(_onSortEvents);
    on<SearchEvents>(_onSearchEvents);
  }

  Future<void> _onLoadEvents(
    LoadEvents event,
    Emitter<EventsState> emit,
  ) async {
    emit(const EventsLoading());

    try {
      final allOffers = await offerRepository.getOffersByType(OfferType.event);
      final events = allOffers.cast<event_entity.Event>().toList();

      emit(EventsLoaded(events: events));
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  Future<void> _onRefreshEvents(
    RefreshEvents event,
    Emitter<EventsState> emit,
  ) async {
    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;
      emit(
        EventsLoaded(
          events: currentState.events,
          selectedEventType: currentState.selectedEventType,
          sortBy: currentState.sortBy,
          searchQuery: currentState.searchQuery,
        ),
      );
    }

    try {
      final allOffers = await offerRepository.getOffersByType(OfferType.event);
      var events = allOffers.cast<event_entity.Event>().toList();

      // Apply filters
      if (state is EventsLoaded) {
        final currentState = state as EventsLoaded;

        // Filter by event type
        if (currentState.selectedEventType != null) {
          events =
              events
                  .where((e) => e.eventType == currentState.selectedEventType)
                  .toList();
        }

        // Search filter
        if (currentState.searchQuery != null &&
            currentState.searchQuery!.isNotEmpty) {
          final query = currentState.searchQuery!.toLowerCase();
          events =
              events.where((e) {
                return e.title.toLowerCase().contains(query) ||
                    e.description.toLowerCase().contains(query) ||
                    e.organizer.toLowerCase().contains(query) ||
                    e.venue.name.toLowerCase().contains(query);
              }).toList();
        }

        // Sort
        if (currentState.sortBy != null) {
          switch (currentState.sortBy) {
            case 'date':
              events.sort(
                (a, b) =>
                    a.eventDateTime.start.compareTo(b.eventDateTime.start),
              );
              break;
            case 'popularity':
              events.sort((a, b) {
                final aScore = a.metrics?.popularityScore ?? 0.0;
                final bScore = b.metrics?.popularityScore ?? 0.0;
                return bScore.compareTo(aScore);
              });
              break;
            case 'distance':
              // Would need user location for this
              break;
          }
        }
      }

      emit(
        EventsLoaded(
          events: events,
          selectedEventType:
              state is EventsLoaded
                  ? (state as EventsLoaded).selectedEventType
                  : null,
          sortBy: state is EventsLoaded ? (state as EventsLoaded).sortBy : null,
          searchQuery:
              state is EventsLoaded
                  ? (state as EventsLoaded).searchQuery
                  : null,
        ),
      );
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  void _onFilterEventsByType(
    FilterEventsByType event,
    Emitter<EventsState> emit,
  ) {
    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;
      final filteredEvents =
          event.eventType == null
              ? currentState.events
              : currentState.events
                  .where((e) => e.eventType == event.eventType)
                  .toList();

      emit(
        EventsLoaded(
          events: filteredEvents,
          selectedEventType: event.eventType,
          sortBy: currentState.sortBy,
          searchQuery: currentState.searchQuery,
        ),
      );
    }
  }

  void _onSortEvents(SortEvents event, Emitter<EventsState> emit) {
    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;
      final sortedEvents = List<event_entity.Event>.from(currentState.events);

      switch (event.sortBy) {
        case 'date':
          sortedEvents.sort(
            (a, b) => a.eventDateTime.start.compareTo(b.eventDateTime.start),
          );
          break;
        case 'popularity':
          sortedEvents.sort((a, b) {
            final aScore = a.metrics?.popularityScore ?? 0.0;
            final bScore = b.metrics?.popularityScore ?? 0.0;
            return bScore.compareTo(aScore);
          });
          break;
        case 'distance':
          // Would need user location
          break;
      }

      emit(
        EventsLoaded(
          events: sortedEvents,
          selectedEventType: currentState.selectedEventType,
          sortBy: event.sortBy,
          searchQuery: currentState.searchQuery,
        ),
      );
    }
  }

  void _onSearchEvents(SearchEvents event, Emitter<EventsState> emit) {
    if (state is EventsLoaded) {
      final currentState = state as EventsLoaded;
      final query = event.query.toLowerCase();

      final filteredEvents =
          currentState.events.where((e) {
            return e.title.toLowerCase().contains(query) ||
                e.description.toLowerCase().contains(query) ||
                e.organizer.toLowerCase().contains(query) ||
                e.venue.name.toLowerCase().contains(query);
          }).toList();

      emit(
        EventsLoaded(
          events: filteredEvents,
          selectedEventType: currentState.selectedEventType,
          sortBy: currentState.sortBy,
          searchQuery: event.query,
        ),
      );
    }
  }
}
