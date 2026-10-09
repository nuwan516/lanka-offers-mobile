import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../common/widgets/error_view.dart';
import '../../common/widgets/offer_card.dart';
import 'bloc/explore_bloc.dart';
import 'bloc/explore_event.dart';
import 'bloc/explore_state.dart';
import 'widgets/map_view_screen.dart';

// ---------------------------------------------------------------------------
// Root: provides the ExploreBloc
// ---------------------------------------------------------------------------
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<ExploreBloc>()..add(LoadExploreOffers()),
        child: const _ExploreView(),
      );
}

// ---------------------------------------------------------------------------
// Main stateful view — owns scroll / map controllers and local UI state
// ---------------------------------------------------------------------------
class _ExploreView extends StatefulWidget {
  const _ExploreView();
  @override
  State<_ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<_ExploreView> {
  final MapController _mapController = MapController();
  final ScrollController _listScroll = ScrollController();

  /// Index of the offer card highlighted by the last map pin tap.
  int? _highlightedIndex;

  /// Category applied locally (on top of BLoC filters).
  String? _quickCategory;

  static const double _cardHeight = 178.0;

  @override
  void dispose() {
    _mapController.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  /// Called when a map pin is tapped — scroll list & highlight the card.
  void _onMarkerTapped(int idx) {
    setState(() => _highlightedIndex = idx);
    if (_listScroll.hasClients) {
      final offset =
          (idx * _cardHeight).clamp(0.0, _listScroll.position.maxScrollExtent);
      _listScroll.animateTo(offset,
          duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    }
  }

  /// Called when a card row is tapped — pan map to its first physical location.
  void _onCardFocused(BankOffer offer, int index) {
    setState(() => _highlightedIndex = index);
    final loc = offer.locations.where(_validCoord).firstOrNull;
    if (loc != null) {
      _mapController.move(LatLng(loc.latitude, loc.longitude), 14);
    }
  }

  static bool _validCoord(dynamic loc) =>
      loc.latitude != 0 &&
      loc.longitude != 0 &&
      loc.latitude >= -90 &&
      loc.latitude <= 90 &&
      loc.longitude >= -180 &&
      loc.longitude <= 180;

  static bool _isPhysical(BankOffer o) =>
      o.locationScope != 'ONLINE' &&
      o.locationScope != 'NATIONWIDE' &&
      o.locationScope != 'UNRESOLVED' &&
      o.locationScope != 'SELECTED_OUTLETS' &&
      o.locations.any(_validCoord);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocBuilder<ExploreBloc, ExploreState>(
        builder: (context, state) {
          if (state is ExploreLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExploreError) {
            return ErrorView(
              message: l10n.text('connectionRetry'),
              onRetry: () =>
                  context.read<ExploreBloc>().add(LoadExploreOffers()),
            );
          }
          if (state is! ExploreLoaded) return const SizedBox.shrink();

          // Full-screen map mode (toggle from AppBar)
          if (state.isMapView) {
            return MapViewScreen(
              offers: state.offers,
              userLatitude: state.userLatitude,
              userLongitude: state.userLongitude,
            );
          }

          // Apply local quick-category filter on top of BLoC results
          final displayed = _quickCategory == null
              ? state.offers
              : state.offers
                  .where((o) => o.category == _quickCategory)
                  .toList();

          final physicalOffers = displayed.where(_isPhysical).toList();
          final categories = state.offers
              .map((o) => o.category)
              .toSet()
              .toList()
            ..sort();

          final activeFilterLabels = <String>[
            if (state.nearbyOnly) 'Nearby',
            if (state.matchMyCards) 'My Cards',
            if (state.selectedBank != null) state.selectedBank!,
            if (state.selectedCategory != null) state.selectedCategory!,
            if (state.selectedDistrict != null) state.selectedDistrict!,
          ];

          final userLat = state.userLatitude;
          final userLng = state.userLongitude;
          final mapCenter = (userLat != null && userLng != null)
              ? LatLng(userLat, userLng)
              : (physicalOffers.isNotEmpty &&
                      physicalOffers.first.locations.any(_validCoord)
                  ? LatLng(
                      physicalOffers.first.locations
                          .firstWhere(_validCoord)
                          .latitude,
                      physicalOffers.first.locations
                          .firstWhere(_validCoord)
                          .longitude)
                  : const LatLng(6.9271, 79.8612)); // Colombo

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ExploreBloc>().add(RefreshExploreOffers()),
            child: CustomScrollView(
              controller: _listScroll,
              slivers: [
                // ─ App Bar ─────────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: AppColors.redGlowShadow,
                        ),
                        child: const Icon(
                          Icons.explore_rounded,
                          size: 16,
                          color: AppColors.flashYellow,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.text('allBankOffers'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Full-screen map',
                      icon: const Icon(Icons.map_outlined),
                      onPressed: () =>
                          context.read<ExploreBloc>().add(ToggleMapView()),
                    ),
                    Badge(
                      isLabelVisible: activeFilterLabels.isNotEmpty,
                      label: Text('${activeFilterLabels.length}'),
                      backgroundColor: AppColors.primary,
                      textColor: Colors.white,
                      child: IconButton(
                        tooltip: l10n.text('filters'),
                        icon: const Icon(Icons.tune_rounded),
                        onPressed: () => _showFilters(context, state),
                      ),
                    ),
                  ],
                ),

                // ─ Embedded Mini-Map (240 px) ──────────────────────────────
                SliverToBoxAdapter(
                  child: _MiniMap(
                    mapController: _mapController,
                    center: mapCenter,
                    physicalOffers: physicalOffers,
                    displayedOffers: displayed,
                    userLat: userLat,
                    userLng: userLng,
                    highlightedGlobalIndex: _highlightedIndex,
                    onMarkerTapped: _onMarkerTapped,
                    onExpandTapped: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MapViewScreen(
                          offers: displayed,
                          userLatitude: userLat,
                          userLongitude: userLng,
                        ),
                      ),
                    ),
                  ),
                ),

                // ─ Stats bar + Nearby toggle ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    child: Row(
                      children: [
                        _StatPill(
                          icon: Icons.list_alt_rounded,
                          label: 'All',
                          count: displayed.length,
                          color: cs.primary,
                          active: true,
                        ),
                        const SizedBox(width: 8),
                        _StatPill(
                          icon: Icons.place_rounded,
                          label: 'On Map',
                          count: physicalOffers.length,
                          color: Colors.green.shade700,
                          active: false,
                        ),
                        const Spacer(),
                        _NearbyToggle(
                          isActive: state.nearbyOnly,
                          userLat: userLat,
                          userLng: userLng,
                        ),
                      ],
                    ),
                  ),
                ),

                // ─ Category quick-filter pills ─────────────────────────────
                SliverToBoxAdapter(
                  child: _CategoryPills(
                    categories: categories,
                    selected: _quickCategory,
                    onSelected: (cat) => setState(() {
                      _quickCategory = (_quickCategory == cat) ? null : cat;
                      _highlightedIndex = null;
                    }),
                  ),
                ),

                // ─ Active filter chip strip ────────────────────────────────
                if (activeFilterLabels.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _FilterChipStrip(
                      filters: activeFilterLabels,
                      onClear: () {
                        context
                            .read<ExploreBloc>()
                            .add(LoadExploreOffers());
                        setState(() {
                          _quickCategory = null;
                          _highlightedIndex = null;
                        });
                      },
                    ),
                  ),

                // ─ Empty state ─────────────────────────────────────────────
                if (displayed.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 52, color: cs.outline),
                          const SizedBox(height: 12),
                          Text(l10n.text('noOffers'),
                              style:
                                  Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  ),

                // ─ Offer cards ─────────────────────────────────────────────
                if (displayed.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 24),
                    sliver: SliverList.builder(
                      itemCount: displayed.length,
                      itemBuilder: (_, index) {
                        final offer = displayed[index];
                        final highlighted = _highlightedIndex == index;
                        return GestureDetector(
                          onTap: () => _onCardFocused(offer, index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: highlighted
                                ? BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: cs.primary.withOpacity(0.22),
                                        blurRadius: 14,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  )
                                : null,
                            child: OfferCard(
                              offer: offer,
                              contextOffers: displayed,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Filter bottom sheet ───────────────────────────────────────────────────
  Future<void> _showFilters(
      BuildContext context, ExploreLoaded state) async {
    String? category = state.selectedCategory;
    String? district = state.selectedDistrict;
    String? bank = state.selectedBank;
    bool matchMyCards = state.matchMyCards;
    bool nearbyOnly = state.nearbyOnly;
    double? userLat = state.userLatitude;
    double? userLng = state.userLongitude;
    final bloc = context.read<ExploreBloc>();
    final l10n = AppLocalizations.of(context)!;
    final categories = state.offers
        .map((o) => o.category)
        .toSet()
        .toList()
      ..sort();
    final banks = state.offers
        .map((o) => o.bankName)
        .toSet()
        .toList()
      ..sort();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setS) => DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, sc) => SingleChildScrollView(
            controller: sc,
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, MediaQuery.viewInsetsOf(sheetCtx).bottom + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(l10n.text('filters'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: SwitchListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    title: const Text('Nearby (Within 20 km)'),
                    subtitle: const Text(
                        'Only show confirmed branch locations near you'),
                    value: nearbyOnly,
                    onChanged: (val) async {
                      if (val) {
                        final pos = await getIt<LocationService>()
                            .getCurrentPosition();
                        if (pos != null) {
                          setS(() {
                            nearbyOnly = true;
                            userLat = pos.latitude;
                            userLng = pos.longitude;
                          });
                        } else if (sheetCtx.mounted) {
                          ScaffoldMessenger.of(sheetCtx).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Could not access location. Check permissions.')),
                          );
                        }
                      } else {
                        setS(() => nearbyOnly = false);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: SwitchListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    title: const Text('Matching My Cards'),
                    subtitle: const Text(
                        'Only show offers valid for my saved cards'),
                    value: matchMyCards,
                    onChanged: (val) => setS(() => matchMyCards = val),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: bank,
                  decoration:
                      InputDecoration(labelText: l10n.text('banks')),
                  items: [
                    const DropdownMenuItem<String>(
                        value: null, child: Text('All banks')),
                    ...banks.map(
                        (b) => DropdownMenuItem(value: b, child: Text(b))),
                  ],
                  onChanged: (v) => setS(() => bank = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration:
                      InputDecoration(labelText: l10n.category),
                  items: [
                    const DropdownMenuItem<String>(
                        value: null, child: Text('All categories')),
                    ...categories.map(
                        (c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setS(() => category = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: district,
                  decoration: InputDecoration(
                      labelText: l10n.text('preferredDistricts')),
                  items: const [
                    DropdownMenuItem<String>(
                        value: null, child: Text('All districts')),
                    DropdownMenuItem(
                        value: 'Colombo', child: Text('Colombo')),
                    DropdownMenuItem(
                        value: 'Gampaha', child: Text('Gampaha')),
                    DropdownMenuItem(value: 'Kandy', child: Text('Kandy')),
                    DropdownMenuItem(value: 'Galle', child: Text('Galle')),
                    DropdownMenuItem(
                        value: 'Matara', child: Text('Matara')),
                    DropdownMenuItem(
                        value: 'Kurunegala', child: Text('Kurunegala')),
                    DropdownMenuItem(
                        value: 'Negombo', child: Text('Negombo')),
                  ],
                  onChanged: (v) => setS(() => district = v),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  TextButton(
                    onPressed: () {
                      bloc.add(LoadExploreOffers());
                      Navigator.pop(sheetCtx);
                      setState(() {
                        _quickCategory = null;
                        _highlightedIndex = null;
                      });
                    },
                    child: Text(l10n.text('clearAll')),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      bloc.add(LoadExploreOffers(
                        category: category,
                        district: district,
                        bank: bank,
                        matchMyCards: matchMyCards,
                        nearbyOnly: nearbyOnly,
                        userLatitude: userLat,
                        userLongitude: userLng,
                      ));
                      Navigator.pop(sheetCtx);
                    },
                    child: Text(l10n.text('applyFilters')),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Mini-map widget (240 px embedded viewport)
// =============================================================================
class _MiniMap extends StatelessWidget {
  const _MiniMap({
    required this.mapController,
    required this.center,
    required this.physicalOffers,
    required this.displayedOffers,
    required this.userLat,
    required this.userLng,
    required this.highlightedGlobalIndex,
    required this.onMarkerTapped,
    required this.onExpandTapped,
  });

  final MapController mapController;
  final LatLng center;
  final List<BankOffer> physicalOffers;
  final List<BankOffer> displayedOffers;
  final double? userLat;
  final double? userLng;
  final int? highlightedGlobalIndex;
  final void Function(int) onMarkerTapped;
  final VoidCallback onExpandTapped;

  static bool _validCoord(dynamic loc) =>
      loc.latitude != 0 &&
      loc.longitude != 0 &&
      loc.latitude >= -90 &&
      loc.latitude <= 90 &&
      loc.longitude >= -180 &&
      loc.longitude <= 180;

  List<Marker> _markers(BuildContext context) {
    final out = <Marker>[];
    if (userLat != null && userLng != null) {
      out.add(Marker(
        point: LatLng(userLat!, userLng!),
        width: 36,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 8)
            ],
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 18),
        ),
      ));
    }
    for (final offer in physicalOffers) {
      final globalIdx = displayedOffers.indexOf(offer);
      final highlighted = highlightedGlobalIndex == globalIdx;
      for (final loc in offer.locations.where(_validCoord)) {
        out.add(Marker(
          point: LatLng(loc.latitude, loc.longitude),
          width: highlighted ? 46 : 34,
          height: highlighted ? 46 : 34,
          child: GestureDetector(
            onTap: () => onMarkerTapped(globalIdx >= 0 ? globalIdx : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                color: highlighted
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white, width: highlighted ? 3 : 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary
                        .withOpacity(highlighted ? 0.5 : 0.2),
                    blurRadius: highlighted ? 12 : 5,
                    spreadRadius: highlighted ? 2 : 0,
                  ),
                ],
              ),
              child: Icon(Icons.account_balance,
                  color: Colors.white, size: highlighted ? 22 : 16),
            ),
          ),
        ));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 12,
              minZoom: 5,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.lanka_offers',
                maxZoom: 19,
              ),
              if (userLat != null && userLng != null)
                CircleLayer<String>(circles: [
                  CircleMarker<String>(
                    point: LatLng(userLat!, userLng!),
                    radius: 5000,
                    useRadiusInMeter: true,
                    color: AppColors.primary.withOpacity(0.07),
                    borderColor: AppColors.primary.withOpacity(0.25),
                    borderStrokeWidth: 1.5,
                  ),
                ]),
              MarkerLayer(markers: _markers(context)),
            ],
          ),
          // Top gradient scrim
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // "X on map" count pill (top-left)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.62),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${physicalOffers.length} on map',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          // Expand button (top-right)
          Positioned(
            top: 10,
            right: 10,
            child: _IconOverlayBtn(
              icon: Icons.open_in_full_rounded,
              tooltip: 'Full-screen map',
              onTap: onExpandTapped,
            ),
          ),
          // No-location notice
          if (physicalOffers.isEmpty)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Text(
                    'No branch locations for this filter',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Small circular icon button for map overlays
// =============================================================================
class _IconOverlayBtn extends StatelessWidget {
  const _IconOverlayBtn(
      {required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surface.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Icon(icon,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      );
}

// =============================================================================
// Stats pill (All / On Map)
// =============================================================================
class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.active,
  });
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.secondary : Colors.transparent,
            width: active ? 1.2 : 1,
          ),
          boxShadow: active ? AppColors.redGlowShadow : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: active ? AppColors.flashYellow : color),
          const SizedBox(width: 4),
          Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : color,
            ),
          ),
        ]),
      );
}

// =============================================================================
// Nearby toggle animated pill
// =============================================================================
class _NearbyToggle extends StatelessWidget {
  const _NearbyToggle(
      {required this.isActive, this.userLat, this.userLng});
  final bool isActive;
  final double? userLat;
  final double? userLng;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ExploreBloc>();
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        if (isActive) {
          bloc.add(LoadExploreOffers(nearbyOnly: false));
        } else {
          final pos = await getIt<LocationService>().getCurrentPosition();
          if (pos != null) {
            bloc.add(LoadExploreOffers(
              nearbyOnly: true,
              userLatitude: pos.latitude,
              userLongitude: pos.longitude,
            ));
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Location unavailable — check permissions')));
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.flashYellow : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF8B1010) : Colors.transparent,
            width: isActive ? 1.2 : 1,
          ),
          boxShadow: isActive ? AppColors.yellowGlowShadow : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            isActive ? Icons.near_me_rounded : Icons.near_me_disabled,
            size: 14,
            color: isActive ? const Color(0xFF8B1010) : cs.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Nearby ON' : 'Nearby',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isActive ? const Color(0xFF8B1010) : cs.onSurfaceVariant,
            ),
          ),
        ]),
      ),
    );
  }
}

// =============================================================================
// Category quick-filter horizontal scroll chips
// =============================================================================
class _CategoryPills extends StatelessWidget {
  const _CategoryPills(
      {required this.categories,
      required this.selected,
      required this.onSelected});
  final List<String> categories;
  final String? selected;
  final void Function(String) onSelected;

  static IconData _icon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('dining') || c.contains('restaur') || c.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (c.contains('hotel') || c.contains('travel') || c.contains('resort')) {
      return Icons.hotel_rounded;
    }
    if (c.contains('super') || c.contains('grocery')) {
      return Icons.local_grocery_store_rounded;
    }
    if (c.contains('fashion') || c.contains('apparel')) {
      return Icons.checkroom_rounded;
    }
    if (c.contains('health') || c.contains('pharma')) {
      return Icons.local_hospital_rounded;
    }
    if (c.contains('fuel') || c.contains('petrol')) {
      return Icons.local_gas_station_rounded;
    }
    if (c.contains('entertain') || c.contains('cinema')) {
      return Icons.movie_rounded;
    }
    if (c.contains('tech') || c.contains('electr')) {
      return Icons.devices_rounded;
    }
    return Icons.local_offer_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final sel = selected == cat;
          return FilterChip(
            avatar: Icon(
              _icon(cat),
              size: 14,
              color: sel ? AppColors.flashYellow : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            label: Text(
              cat,
              style: TextStyle(
                fontSize: 12,
                fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                color: sel ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            selected: sel,
            onSelected: (_) => onSelected(cat),
            selectedColor: AppColors.primary,
            checkmarkColor: AppColors.flashYellow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: sel ? AppColors.secondary : Colors.transparent,
                width: sel ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

// =============================================================================
// Active filter chip strip
// =============================================================================
class _FilterChipStrip extends StatelessWidget {
  const _FilterChipStrip(
      {required this.filters, required this.onClear});
  final List<String> filters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final f in filters)
              Chip(
                  label: Text(f,
                      style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact),
            ActionChip(
              label: Text(
                  AppLocalizations.of(context)!.text('clearAll'),
                  style: const TextStyle(fontSize: 12)),
              avatar: const Icon(Icons.close_rounded, size: 14),
              visualDensity: VisualDensity.compact,
              onPressed: onClear,
            ),
          ],
        ),
      );
}
