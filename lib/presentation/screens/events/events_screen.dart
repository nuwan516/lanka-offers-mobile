import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/enums/event_type.dart';
import '../../../core/localization/app_localizations.dart';
import 'bloc/events_bloc.dart';
import 'bloc/events_event.dart';
import 'bloc/events_state.dart';
import '../../common/widgets/event_card.dart';
import '../../common/widgets/error_view.dart';
import 'widgets/map_view_screen.dart' as events_map;

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<EventsBloc>()..add(const LoadEvents()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.events),
          actions: [
            BlocBuilder<EventsBloc, EventsState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () {
                    if (state is EventsLoaded) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => events_map.EventsMapViewScreen(
                                events: state.events,
                              ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterBottomSheet(context),
            ),
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () => _showSortBottomSheet(context),
            ),
          ],
        ),
        body: BlocBuilder<EventsBloc, EventsState>(
          builder: (context, state) {
            if (state is EventsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is EventsError) {
              return ErrorView(
                message: state.message,
                onRetry:
                    () => context.read<EventsBloc>().add(const RefreshEvents()),
              );
            }

            if (state is EventsLoaded) {
              if (state.events.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.event_busy,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noEventsFound,
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.tryAdjustingFilters,
                        style: AppTextStyles.body2,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<EventsBloc>().add(const RefreshEvents());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.events.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: EventCard(event: state.events[index]),
                    );
                  },
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => BlocBuilder<EventsBloc, EventsState>(
            builder: (context, state) {
              final currentState = state is EventsLoaded ? state : null;
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Filter Events', style: AppTextStyles.h2),
                    const SizedBox(height: 24),
                    Text('Event Type', style: AppTextStyles.h4),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChip(
                          'All',
                          null,
                          currentState?.selectedEventType,
                          context,
                        ),
                        _buildFilterChip(
                          'Concert',
                          EventType.concert,
                          currentState?.selectedEventType,
                          context,
                        ),
                        _buildFilterChip(
                          'Workshop',
                          EventType.workshop,
                          currentState?.selectedEventType,
                          context,
                        ),
                        _buildFilterChip(
                          'Conference',
                          EventType.conference,
                          currentState?.selectedEventType,
                          context,
                        ),
                        _buildFilterChip(
                          'Sports',
                          EventType.sports,
                          currentState?.selectedEventType,
                          context,
                        ),
                        _buildFilterChip(
                          'Cultural',
                          EventType.cultural,
                          currentState?.selectedEventType,
                          context,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<EventsBloc>().add(const RefreshEvents());
                        },
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildFilterChip(
    String label,
    EventType? type,
    EventType? selectedType,
    BuildContext context,
  ) {
    final isSelected = type == selectedType;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        context.read<EventsBloc>().add(
          FilterEventsByType(eventType: selected ? type : null),
        );
      },
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => BlocBuilder<EventsBloc, EventsState>(
            builder: (context, state) {
              final currentState = state is EventsLoaded ? state : null;
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sort By', style: AppTextStyles.h2),
                    const SizedBox(height: 24),
                    _buildSortOption(
                      'Date (Upcoming First)',
                      'date',
                      currentState?.sortBy,
                      context,
                    ),
                    _buildSortOption(
                      'Popularity',
                      'popularity',
                      currentState?.sortBy,
                      context,
                    ),
                    _buildSortOption(
                      'Distance',
                      'distance',
                      currentState?.sortBy,
                      context,
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildSortOption(
    String label,
    String value,
    String? currentSort,
    BuildContext context,
  ) {
    final isSelected = value == currentSort;
    return ListTile(
      title: Text(label),
      trailing:
          isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        context.read<EventsBloc>().add(SortEvents(value));
        Navigator.pop(context);
      },
    );
  }
}
