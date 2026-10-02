import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
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
                        const Icon(Icons.bookmark_border, size: 64),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noSavedOffers,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.text('noSavedBody'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.text('storedOnDevice'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.push('/explore'),
                          child: Text(l10n.text('exploreOffers')),
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
                  padding: const EdgeInsets.all(12),
                  itemCount: state.offers.length,
                  itemBuilder:
                      (_, index) => Dismissible(
                        key: ValueKey(state.offers[index].uniqueId),
                        direction: DismissDirection.endToStart,
                        background: const ColoredBox(
                          color: Colors.red,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                          ),
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
