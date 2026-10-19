import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/banks.dart';
import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/semantics/offer_semantics.dart';
import '../../../core/services/phase_two_survey_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../../domain/entities/bank_summary.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../common/widgets/skeletons.dart';
import '../../common/widgets/offer_card.dart';
import '../../common/widgets/state_views.dart';
import '../../routes/tab_navigation.dart';
import 'bloc/home_bloc.dart';
import 'bloc/home_event.dart';
import 'bloc/home_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<HomeBloc>()..add(LoadHomeData()),
    child: const _HomeView(),
  );
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
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
                        RadioGroup<String>(
                          groupValue: response,
                          onChanged:
                              (value) => setModalState(() => response = value),
                          child: Column(
                            children: [
                              for (final option in [
                                'surveyShops',
                                'surveyEvents',
                                'surveyBoth',
                                'surveyEnough',
                              ])
                                RadioListTile<String>(
                                  value: option,
                                  title: Text(l10n.text(option)),
                                ),
                            ],
                          ),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh:
                  () async => context.read<HomeBloc>().add(RefreshHomeData()),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(isDark: isDark, l10n: l10n),
                  ),
                  if (state is HomeLoaded)
                    ..._loadedSlivers(context, state, l10n),
                  if (state is HomeError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: LoadFailedView(
                        onRetry:
                            () => context.read<HomeBloc>().add(LoadHomeData()),
                      ),
                    ),
                  if (state is! HomeLoaded && state is! HomeError)
                    const SliverToBoxAdapter(child: SkeletonFeed()),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _loadedSlivers(
    BuildContext context,
    HomeLoaded state,
    AppLocalizations l10n,
  ) {
    final live =
        state.allOffers
            .where((o) => !OfferSemantics.isExpired(o.validity))
            .toList();
    final highest =
        (live.where((o) => o.discount?.type == 'percentage').toList()..sort(
              (a, b) => ((b.discount!.value as num?) ?? 0).compareTo(
                (a.discount!.value as num?) ?? 0,
              ),
            ))
            .take(6)
            .toList();
    final endingSoon =
        (live.where((o) => OfferSemantics.isEndingSoon(o.validity)).toList()
              ..sort(
                (a, b) => OfferSemantics.daysLeft(
                  a.validity,
                )!.compareTo(OfferSemantics.daysLeft(b.validity)!),
              ))
            .take(4)
            .toList();
    final categories =
        state.categories
            .where((c) => c.name.toLowerCase() != 'all')
            .take(8)
            .toList();

    return [
      if (!_hasPreferences)
        SliverToBoxAdapter(child: _PersonalizePrompt(l10n: l10n)),
      SliverToBoxAdapter(
        child: _Section(
          title: l10n.text('sectionBanks'),
          child: _BankGrid(banks: state.banks),
        ),
      ),
      if (categories.isNotEmpty)
        SliverToBoxAdapter(
          child: _Section(
            title: l10n.text('sectionCategories'),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in categories)
                  ActionChip(
                    avatar: Icon(c.icon, size: 16),
                    label: Text(c.name),
                    onPressed:
                        () => TabNavigation.openExplore(
                          ExploreRequest(category: c.name),
                        ),
                  ),
              ],
            ),
          ),
        ),
      if (live.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyOffersView(),
          ),
        )
      else
        _offersSliver(l10n.text('sectionHighestDiscounts'), highest, l10n),
      if (endingSoon.isNotEmpty)
        _offersSliver(l10n.text('sectionEndingSoon'), endingSoon, l10n),
    ];
  }

  Widget _offersSliver(
    String title,
    List<BankOffer> offers,
    AppLocalizations l10n,
  ) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      () => TabNavigation.openExplore(const ExploreRequest()),
                  child: Text(l10n.seeAll),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: offers.length,
            itemBuilder:
                (_, i) => OfferCard(
                  offer: offers[i],
                  contextOffers: offers,
                  initialIndex: i,
                ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isDark, required this.l10n});

  final bool isDark;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.text('findNextOffer'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.text('verifiedBankOffers'),
            style: TextStyle(color: secondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: l10n.text('searchBankOffers'),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/search'),
              child: Ink(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurfaceVariant : AppColors.surface,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: secondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.text('searchBankOffers'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed:
                () => TabNavigation.openExplore(
                  const ExploreRequest(segment: ExploreSegment.nearby),
                ),
            icon: const Icon(Icons.near_me_outlined, size: 18),
            label: Text(l10n.text('nearbyOffers')),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// The ten supported banks. Counts come from `/api/banks`; a bank with no
/// active offers is shown as such instead of being hidden or linked.
class _BankGrid extends StatelessWidget {
  const _BankGrid({required this.banks});

  final List<BankSummary> banks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final counts = {for (final b in banks) b.code: b.activeOfferCount};
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 4 : 2;
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final bank in CanonicalBanks.all)
              SizedBox(
                width: width,
                child: BankTile(
                  bank: bank,
                  count: counts[bank.code],
                  l10n: l10n,
                  onTap:
                      () => TabNavigation.openExplore(
                        ExploreRequest(bankCode: bank.code),
                      ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class BankTile extends StatelessWidget {
  const BankTile({
    super.key,
    required this.bank,
    required this.count,
    required this.l10n,
    required this.onTap,
  });

  final CanonicalBank bank;

  /// Null = the API did not report a count; 0 = reported, none active.
  final int? count;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final none = count == 0;
    final subtitle =
        count == null
            ? null
            : none
            ? l10n.text('bankNoActive')
            : l10n.format('bankActiveOffers', {'count': count!});

    return Semantics(
      button: !none,
      enabled: !none,
      label: [bank.name, if (subtitle != null) subtitle].join(', '),
      child: Material(
        color:
            none
                ? (isDark ? AppColors.darkBackground : AppColors.surfaceVariant)
                : (isDark ? AppColors.darkSurface : AppColors.surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: none ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? AppColors.primary.withValues(alpha: 0.25)
                              : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      bank.short,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bank.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: secondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalizePrompt extends StatelessWidget {
  const _PersonalizePrompt({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.text('chooseBanksCards'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.text('relevantOffers'),
                    style: const TextStyle(height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => context.push('/preferences'),
              child: Text(l10n.text('chooseCards')),
            ),
          ],
        ),
      ),
    );
  }
}
