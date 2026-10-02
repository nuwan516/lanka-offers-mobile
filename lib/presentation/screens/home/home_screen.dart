import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/phase_two_survey_service.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../common/widgets/error_view.dart';
import '../../common/widgets/loading_shimmer.dart';
import '../../common/widgets/offer_card.dart';
import 'bloc/home_bloc.dart';
import 'bloc/home_event.dart';
import 'bloc/home_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasPreferences = false;

  @override
  void initState() {
    super.initState();
    _prepareLocalExperience();
  }

  Future<void> _prepareLocalExperience() async {
    final preferences = await getIt<UserRepository>().getPreferences();
    final saved = await getIt<UserRepository>().getSavedOffers();
    final survey = getIt<PhaseTwoSurveyService>();
    await survey.recordAppOpen(DateTime.now());
    if (!mounted) return;
    setState(
      () =>
          _hasPreferences =
              preferences.selectedBanks.isNotEmpty ||
              preferences.cardTypes.isNotEmpty ||
              preferences.cardNetworks.isNotEmpty,
    );
    if (await survey.isEligible(savedCount: saved.length) && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showSurvey());
    }
  }

  Future<void> _showSurvey() async {
    String? response;
    final service = getIt<PhaseTwoSurveyService>();
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.text('surveyTitle'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.text('surveyBody')),
                        const SizedBox(height: 12),
                        for (final option in [
                          'surveyShops',
                          'surveyEvents',
                          'surveyBoth',
                          'surveyEnough',
                        ])
                          RadioListTile<String>(
                            value: option,
                            groupValue: response,
                            title: Text(l10n.text(option)),
                            onChanged:
                                (value) =>
                                    setModalState(() => response = value),
                          ),
                        FilledButton(
                          onPressed:
                              response == null
                                  ? null
                                  : () async {
                                    await service.submit(response: response!);
                                    if (context.mounted) Navigator.pop(context);
                                  },
                          child: Text(l10n.text('submit')),
                        ),
                        TextButton(
                          onPressed: () async {
                            await service.dismiss(optOut: false);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Text(l10n.text('notNow')),
                        ),
                        TextButton(
                          onPressed: () async {
                            await service.dismiss(optOut: true);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: Text(l10n.text('dontAskAgain')),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<HomeBloc>()..add(LoadHomeData()),
    child: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.appName),
            actions: [
              IconButton(
                tooltip: l10n.searchHint,
                onPressed: () => context.push('/search'),
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          body: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading) return const LoadingShimmer();
              if (state is HomeError) {
                return ErrorView(
                  message: l10n.text('connectionRetry'),
                  onRetry: () => context.read<HomeBloc>().add(LoadHomeData()),
                );
              }
              if (state is! HomeLoaded) return const SizedBox.shrink();
              return RefreshIndicator(
                onRefresh:
                    () async => context.read<HomeBloc>().add(RefreshHomeData()),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      l10n.text('findNextOffer'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.text('verifiedBankOffers')),
                    const SizedBox(height: 16),
                    Semantics(
                      button: true,
                      child: TextField(
                        readOnly: true,
                        onTap: () => context.push('/search'),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: l10n.text('searchBankOffers'),
                        ),
                      ),
                    ),
                    if (!_hasPreferences) ...[
                      const SizedBox(height: 16),
                      _ActionCard(
                        title: l10n.text('chooseBanksCards'),
                        body: l10n.text('relevantOffers'),
                        action: l10n.text('chooseCards'),
                        onPressed: () async {
                          await context.push('/preferences');
                          _prepareLocalExperience();
                        },
                      ),
                    ],
                    _OfferSection(
                      title: l10n.featuredOffers,
                      offers: state.featuredOffers,
                    ),
                    _OfferSection(
                      title: l10n.endingSoon,
                      offers: state.allOffers.where(_expiresSoon).toList(),
                    ),
                    _OfferSection(
                      title: l10n.text('allBankOffers'),
                      offers: state.allOffers,
                    ),
                    const SizedBox(height: 16),
                    _ActionCard(
                      title: l10n.text('locationOff'),
                      body: l10n.text('locationOffBody'),
                      action: l10n.text('enableLocation'),
                      onPressed: () => context.push('/explore'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ),
  );

  bool _expiresSoon(BankOffer offer) {
    if (offer.validity.hasNoConfiguredExpiry) return false;
    final days = offer.validity.validUntil.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 7;
  }
}

class _OfferSection extends StatelessWidget {
  const _OfferSection({required this.title, required this.offers});
  final String title;
  final List<BankOffer> offers;
  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();
    final displayed = offers.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (int i = 0; i < displayed.length; i++)
          OfferCard(
            offer: displayed[i],
            contextOffers: offers,
            initialIndex: i,
          ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.body,
    required this.action,
    required this.onPressed,
  });
  final String title;
  final String body;
  final String action;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: onPressed, child: Text(action)),
        ],
      ),
    ),
  );
}
