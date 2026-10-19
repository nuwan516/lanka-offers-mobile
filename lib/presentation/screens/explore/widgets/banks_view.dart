import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/banks.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../common/widgets/skeletons.dart';
import '../../../common/widgets/state_views.dart';
import '../../home/home_screen.dart' show BankTile;
import '../cubit/banks_cubit.dart';

/// The ten supported banks with live offer counts. A bank with no active
/// offers is listed honestly and is not tappable.
class BanksView extends StatelessWidget {
  const BanksView({super.key, required this.onOpenBank});

  final ValueChanged<String> onOpenBank;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<BanksCubit, BanksState>(
      builder: (context, state) {
        if (state.status == BanksStatus.loading) {
          return const SkeletonBody();
        }
        // On failure the list is still shown (counts unknown) so a bank can
        // be opened; a notice explains why counts are missing.
        final counts = {
          for (final b in state.banks) b.code: b.activeOfferCount,
        };
        return RefreshIndicator(
          onRefresh: () => context.read<BanksCubit>().load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (state.status == BanksStatus.failed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.text('bankCountUnavailable'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              for (final bank in CanonicalBanks.all)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BankTile(
                    bank: bank,
                    count: counts[bank.code],
                    l10n: l10n,
                    onTap: () => onOpenBank(bank.code),
                  ),
                ),
              if (state.status == BanksStatus.failed)
                LoadFailedView(
                  onRetry: () => context.read<BanksCubit>().load(),
                ),
            ],
          ),
        );
      },
    );
  }
}
