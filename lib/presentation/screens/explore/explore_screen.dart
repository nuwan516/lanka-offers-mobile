import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/location_service.dart';
import '../../../domain/repositories/offer_repository.dart';
import '../../../domain/usecases/get_banks.dart';
import '../../../domain/usecases/get_nearby_offers.dart';
import '../../routes/tab_navigation.dart';
import 'cubit/banks_cubit.dart';
import 'cubit/browse_cubit.dart';
import 'cubit/nearby_cubit.dart';
import 'widgets/banks_view.dart';
import 'widgets/browse_view.dart';
import 'widgets/nearby_view.dart';

/// The Explore hub: Browse (all offers), Nearby (confirmed branches) and Banks.
///
/// Used both as a tab and as the `/explore` route.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => BrowseCubit(getIt<OfferRepository>())),
      BlocProvider(
        create:
            (_) => NearbyCubit(
              getNearbyOffers: getIt<GetNearbyOffers>(),
              locationService: getIt<LocationService>(),
            ),
      ),
      BlocProvider(create: (_) => BanksCubit(getIt<GetBanks>())..load()),
    ],
    child: const _ExploreHub(),
  );
}

class _ExploreHub extends StatefulWidget {
  const _ExploreHub();

  @override
  State<_ExploreHub> createState() => _ExploreHubState();
}

class _ExploreHubState extends State<_ExploreHub> {
  ExploreSegment _segment = ExploreSegment.browse;

  @override
  void initState() {
    super.initState();
    // Consume a pending request from Home (bank shortcut, category, nearby).
    final request = TabNavigation.exploreRequest.value;
    TabNavigation.exploreRequest.value = null;
    _segment = request?.segment ?? ExploreSegment.browse;
    final browse = context.read<BrowseCubit>();
    browse.load(
      BrowseFilters(
        bankCode: request?.bankCode,
        category: request?.category,
        scope: request?.scope,
      ),
    );
    if (_segment == ExploreSegment.nearby) {
      context.read<NearbyCubit>().refresh();
    }
  }

  void _select(ExploreSegment segment) {
    if (segment == _segment) return;
    setState(() => _segment = segment);
    if (segment == ExploreSegment.nearby &&
        context.read<NearbyCubit>().state.status == NearbyStatus.idle) {
      context.read<NearbyCubit>().refresh();
    }
  }

  void _openBank(String code) {
    context.read<BrowseCubit>().load(BrowseFilters(bankCode: code));
    setState(() => _segment = ExploreSegment.browse);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: canPop ? const BackButton() : null,
        title: Text(l10n.text('exploreNav')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ExploreSegment>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ExploreSegment.browse,
                    label: Text(l10n.text('segBrowse')),
                  ),
                  ButtonSegment(
                    value: ExploreSegment.nearby,
                    label: Text(l10n.text('segNearby')),
                  ),
                  ButtonSegment(
                    value: ExploreSegment.banks,
                    label: Text(l10n.text('segBanks')),
                  ),
                ],
                selected: {_segment},
                onSelectionChanged: (s) => _select(s.first),
              ),
            ),
          ),
          Expanded(
            child: switch (_segment) {
              ExploreSegment.browse => const BrowseView(),
              ExploreSegment.nearby => const NearbyView(),
              ExploreSegment.banks => BanksView(onOpenBank: _openBank),
            },
          ),
        ],
      ),
    );
  }
}
