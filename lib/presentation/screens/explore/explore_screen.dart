import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/location_service.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../common/widgets/error_view.dart';
import '../../common/widgets/offer_card.dart';
import 'bloc/explore_bloc.dart';
import 'bloc/explore_event.dart';
import 'bloc/explore_state.dart';
import 'widgets/map_view_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<ExploreBloc>()..add(LoadExploreOffers()),
    child: const _ExploreView(),
  );
}

class _ExploreView extends StatelessWidget {
  const _ExploreView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('allBankOffers')),
        actions: [
          BlocBuilder<ExploreBloc, ExploreState>(
            builder: (context, state) {
              if (state is! ExploreLoaded) return const SizedBox.shrink();
              return IconButton(
                tooltip: state.isMapView ? 'Switch to list view' : 'Switch to map view',
                icon: Icon(state.isMapView ? Icons.view_list : Icons.map_outlined),
                onPressed: () => context.read<ExploreBloc>().add(ToggleMapView()),
              );
            },
          ),
          BlocBuilder<ExploreBloc, ExploreState>(
            builder: (context, state) {
              if (state is! ExploreLoaded) return const SizedBox.shrink();
              // Count active filters for badge display
              final filterCount = [
                state.selectedCategory,
                state.selectedDistrict,
                state.selectedBank,
                if (state.matchMyCards) 'myCards',
                if (state.nearbyOnly) 'nearby',
              ].length;
              return Badge(
                isLabelVisible: filterCount > 0,
                label: Text('$filterCount'),
                child: IconButton(
                  tooltip: l10n.text('filters'),
                  icon: const Icon(Icons.tune),
                  onPressed: () => _showFilters(context, state),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ExploreBloc, ExploreState>(
        builder: (context, state) {
          if (state is ExploreLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExploreError) {
            return ErrorView(
              message: l10n.text('connectionRetry'),
              onRetry: () => context.read<ExploreBloc>().add(LoadExploreOffers()),
            );
          }
          if (state is! ExploreLoaded) return const SizedBox.shrink();

          // Show active filter chips above the list so the user always knows
          // which filters are currently applied.
          final activeFilters = <String>[
            if (state.nearbyOnly) 'Nearby (Within 20km)',
            if (state.matchMyCards) 'Matching My Cards',
            if (state.selectedBank != null) 'Bank: ${state.selectedBank}',
            if (state.selectedCategory != null) state.selectedCategory!,
            if (state.selectedDistrict != null) state.selectedDistrict!,
          ];

          if (state.isMapView) {
            return MapViewScreen(
              offers: state.offers,
              userLatitude: state.userLatitude,
              userLongitude: state.userLongitude,
            );
          }

          if (state.offers.isEmpty) {
            return Column(
              children: [
                if (activeFilters.isNotEmpty) _FilterChips(
                  filters: activeFilters,
                  onClear: () => context.read<ExploreBloc>().add(LoadExploreOffers()),
                ),
                Expanded(
                  child: Center(child: Text(l10n.text('noOffers'))),
                ),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ExploreBloc>().add(RefreshExploreOffers()),
            child: CustomScrollView(
              slivers: [
                if (activeFilters.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _FilterChips(
                      filters: activeFilters,
                      onClear: () =>
                          context.read<ExploreBloc>().add(LoadExploreOffers()),
                    ),
                  ),
                SliverList.builder(
                  itemCount: state.offers.length,
                  itemBuilder: (_, index) =>
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: OfferCard(
                          offer: state.offers[index],
                          contextOffers: state.offers,
                          initialIndex: index,
                        ),
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showFilters(BuildContext context, ExploreLoaded state) async {
    String? category = state.selectedCategory;
    String? district = state.selectedDistrict;
    String? bank = state.selectedBank;
    bool matchMyCards = state.matchMyCards;
    bool nearbyOnly = state.nearbyOnly;
    double? userLat = state.userLatitude;
    double? userLng = state.userLongitude;
    final bloc = context.read<ExploreBloc>();
    final l10n = AppLocalizations.of(context)!;

    // Build category list from the actual loaded offers — do not use a
    // hardcoded list that may not match what the API actually returns.
    final categories = state.offers
        .map((o) => o.category)
        .toSet()
        .toList()
      ..sort();

    // Build bank list from the loaded offers.
    final banks = state.offers
        .map((o) => o.bankName)
        .toSet()
        .toList()
      ..sort();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.text('filters'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              // Nearby toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Nearby (Within 20 km)'),
                subtitle: const Text('Only show confirmed branch locations near you'),
                value: nearbyOnly,
                onChanged: (val) async {
                  if (val) {
                    final pos = await getIt<LocationService>().getCurrentPosition();
                    if (pos != null) {
                      setState(() {
                        nearbyOnly = true;
                        userLat = pos.latitude;
                        userLng = pos.longitude;
                      });
                    } else {
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                            content: Text('Could not access current location. Please check location permissions.'),
                          ),
                        );
                      }
                    }
                  } else {
                    setState(() => nearbyOnly = false);
                  }
                },
              ),
              const Divider(height: 16),
              // Match My Cards toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Matching My Cards'),
                subtitle: const Text('Only show offers valid for my saved cards'),
                value: matchMyCards,
                onChanged: (val) => setState(() => matchMyCards = val),
              ),
              const Divider(height: 16),
              // Bank filter — dynamically populated from real offers.
              DropdownButtonFormField<String>(
                value: bank,
                decoration: InputDecoration(labelText: l10n.text('banks')),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All banks'),
                  ),
                  ...banks.map(
                    (b) => DropdownMenuItem(value: b, child: Text(b)),
                  ),
                ],
                onChanged: (value) => setState(() => bank = value),
              ),
              const SizedBox(height: 12),
              // Category filter — dynamically populated from real offers.
              DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(labelText: l10n.category),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All categories'),
                  ),
                  ...categories.map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
                  ),
                ],
                onChanged: (value) => setState(() => category = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: district,
                decoration: InputDecoration(
                  labelText: l10n.text('preferredDistricts'),
                ),
                items: const [
                  DropdownMenuItem<String>(value: null, child: Text('All districts')),
                  DropdownMenuItem(value: 'Colombo', child: Text('Colombo')),
                  DropdownMenuItem(value: 'Gampaha', child: Text('Gampaha')),
                  DropdownMenuItem(value: 'Kandy', child: Text('Kandy')),
                  DropdownMenuItem(value: 'Galle', child: Text('Galle')),
                  DropdownMenuItem(value: 'Matara', child: Text('Matara')),
                  DropdownMenuItem(value: 'Kurunegala', child: Text('Kurunegala')),
                  DropdownMenuItem(value: 'Negombo', child: Text('Negombo')),
                ],
                onChanged: (value) => setState(() => district = value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      bloc.add(LoadExploreOffers());
                      Navigator.pop(sheetContext);
                    },
                    child: Text(l10n.text('clearAll')),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      bloc.add(
                        LoadExploreOffers(
                          category: category,
                          district: district,
                          bank: bank,
                          matchMyCards: matchMyCards,
                          nearbyOnly: nearbyOnly,
                          userLatitude: userLat,
                          userLongitude: userLng,
                        ),
                      );
                      Navigator.pop(sheetContext);
                    },
                    child: Text(l10n.text('applyFilters')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows currently active filter chips above the offer list with a "clear all"
/// button so the user always knows what constraints are applied.
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.filters, required this.onClear});
  final List<String> filters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    child: Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final f in filters)
          Chip(
            label: Text(f),
            visualDensity: VisualDensity.compact,
          ),
        ActionChip(
          label: Text(AppLocalizations.of(context)!.text('clearAll')),
          avatar: const Icon(Icons.close, size: 16),
          visualDensity: VisualDensity.compact,
          onPressed: onClear,
        ),
      ],
    ),
  );
}
