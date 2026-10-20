import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../common/widgets/error_view.dart';
import '../../common/widgets/offer_card.dart';
import 'bloc/saved_bloc.dart';
import 'bloc/saved_event.dart';
import 'bloc/saved_state.dart';

class SavedOffersScreen extends StatelessWidget {
  const SavedOffersScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<SavedBloc>()..add(LoadSavedOffers()),
    child: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.savedOffers)),
          body: BlocBuilder<SavedBloc, SavedState>(
            builder: (context, state) {
              if (state is SavedLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is SavedError) {
                return ErrorView(
                  message: l10n.text('connectionRetry'),
                  onRetry:
                      () => context.read<SavedBloc>().add(LoadSavedOffers()),
                );
              }
              if (state is! SavedLoaded) return const SizedBox.shrink();
              if (state.offers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                          child: const Icon(
                            Icons.bookmark_border_rounded,
                            size: 36,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.noSavedOffers,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.text('noSavedBody'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                isDark
                                    ? AppColors.dTextSecondary
                                    : AppColors.lTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? AppColors.dSurfaceHigh
                                    : AppColors.lSurfaceHigh,
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                          child: Text(
                            l10n.text('storedOnDevice'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.onAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Radii.md),
                            ),
                          ),
                          onPressed: () => context.push('/explore'),
                          child: Text(
                            l10n.text('exploreOffers'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh:
                    () async =>
                        context.read<SavedBloc>().add(RefreshSavedOffers()),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.offers.length,
                  itemBuilder:
                      (_, index) => Dismissible(
                        key: ValueKey(state.offers[index].uniqueId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.negative,
                            borderRadius: BorderRadius.circular(Radii.lg),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed:
                            (_) => context.read<SavedBloc>().add(
                              UnsaveOffer(state.offers[index].uniqueId),
                            ),
                        child: OfferCard(
                          offer: state.offers[index],
                          contextOffers: state.offers,
                          initialIndex: index,
                        ),
                      ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
