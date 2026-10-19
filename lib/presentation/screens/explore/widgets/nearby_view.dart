import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/semantics/offer_semantics.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../common/widgets/skeletons.dart';
import '../../../common/widgets/offer_card.dart';
import '../../../common/widgets/state_views.dart';
import '../cubit/nearby_cubit.dart';
import 'nearby_map.dart';

const List<double> _radii = [5, 10, 25, 50];

class NearbyView extends StatefulWidget {
  const NearbyView({super.key});

  @override
  State<NearbyView> createState() => _NearbyViewState();
}

class _NearbyViewState extends State<NearbyView> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<NearbyCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return BlocBuilder<NearbyCubit, NearbyState>(
      builder: (context, state) {
        final place =
            state.place.isDevice
                ? l10n.text('nearbyYourLocation')
                : state.place.name!;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed:
                            state.status == NearbyStatus.locating
                                ? null
                                : cubit.useDeviceLocation,
                        icon: const Icon(Icons.my_location, size: 18),
                        label: Text(l10n.text('nearbyUseMyLocation')),
                      ),
                      Text(
                        l10n.text('nearbyChooseCity'),
                        style: TextStyle(color: secondary, fontSize: 12.5),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final city in presetCities)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: ChoiceChip(
                              label: Text(city.name!),
                              selected:
                                  !state.place.isDevice &&
                                  state.place.name == city.name,
                              onSelected: (_) => cubit.selectCity(city),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (state.issue != LocationIssue.none)
                    _IssueNotice(issue: state.issue),
                  Row(
                    children: [
                      Text(
                        l10n.text('nearbyRadius'),
                        style: TextStyle(color: secondary, fontSize: 12.5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final r in _radii)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 8,
                                  ),
                                  child: ChoiceChip(
                                    label: Text('${r.round()} km'),
                                    selected: state.radiusKm == r,
                                    onSelected: (_) => cubit.setRadius(r),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                        segments: [
                          ButtonSegment(
                            value: false,
                            icon: const Icon(Icons.list, size: 18),
                            tooltip: l10n.text('viewList'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: const Icon(Icons.map_outlined, size: 18),
                            tooltip: l10n.text('viewMap'),
                          ),
                        ],
                        selected: {_showMap},
                        onSelectionChanged:
                            (s) => setState(() => _showMap = s.first),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _results(context, state, place, l10n, secondary)),
          ],
        );
      },
    );
  }

  Widget _results(
    BuildContext context,
    NearbyState state,
    String place,
    AppLocalizations l10n,
    Color secondary,
  ) {
    switch (state.status) {
      case NearbyStatus.idle:
      case NearbyStatus.locating:
      case NearbyStatus.loading:
        return const SkeletonBody();
      case NearbyStatus.failed:
        return LoadFailedView(onRetry: context.read<NearbyCubit>().refresh);
      case NearbyStatus.loaded:
        if (state.offers.isEmpty) {
          return StateMessage(
            icon: Icons.location_off_outlined,
            title: l10n.text('nearbyEmpty'),
            hint: l10n.text('nearbyEmptyHint'),
          );
        }
        if (_showMap) {
          return NearbyMap(
            place: state.place,
            offers: state.offers.where(OfferSemantics.canShowOnMap).toList(),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.format('nearbyFound', {
                  'count': state.offers.length,
                  'radius': state.radiusKm.round(),
                  'place': place,
                }),
                style: TextStyle(color: secondary),
              ),
            ),
            for (var i = 0; i < state.offers.length; i++)
              OfferCard(
                offer: state.offers[i],
                contextOffers: state.offers,
                initialIndex: i,
              ),
            const SizedBox(height: 8),
            Text(
              l10n.text('nearbyNote'),
              style: TextStyle(color: secondary, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.text('nearbyPrivacy'),
              style: TextStyle(color: secondary, fontSize: 12.5, height: 1.4),
            ),
          ],
        );
    }
  }
}

class _IssueNotice extends StatelessWidget {
  const _IssueNotice({required this.issue});

  final LocationIssue issue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message =
        issue == LocationIssue.unavailable
            ? l10n.text('nearbyUnavailable')
            : l10n.text('nearbyDenied');
    final canOpenSettings =
        issue == LocationIssue.deniedForever ||
        issue == LocationIssue.servicesOff;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: isDark ? const Color(0xFFF5C27A) : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, height: 1.35),
            ),
          ),
          if (canOpenSettings)
            TextButton(
              onPressed: () => getIt<LocationService>().openAppSettings(),
              child: Text(l10n.openSettings),
            ),
        ],
      ),
    );
  }
}
