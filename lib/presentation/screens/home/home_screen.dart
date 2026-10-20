import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/banks.dart';
import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/semantics/offer_semantics.dart';
import '../../../core/services/phase_two_survey_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/pressable.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../../domain/entities/bank_summary.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../common/widgets/balance_header.dart';
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
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed:
                              response == null
                                  ? null
                                  : () async {
                                    await service.submitResponse(
                                      response!,
                                      DateTime.now(),
                                    );
                                    if (context.mounted) Navigator.pop(context);
                                  },
                          child: Text(l10n.text('submitFeedback')),
                        ),
                        TextButton(
                          onPressed: () async {
                            await service.optOut();
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
                    child: _Header(
                      isDark: isDark,
                      l10n: l10n,
                      totalOffers:
                          state is HomeLoaded ? state.allOffers.length : null,
                    ),
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
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
  const _Header({
    required this.isDark,
    required this.l10n,
    this.totalOffers,
  });

  final bool isDark;
  final AppLocalizations l10n;
  final int? totalOffers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary =
        isDark ? AppColors.dTextSecondary : AppColors.lTextSecondary;
    final cardBorder = isDark ? AppColors.dBorder : AppColors.lBorder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
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
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.positive.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Radii.pill),
                  border: Border.all(
                    color: AppColors.positive.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 13,
                      color: AppColors.positive,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'STAGED 100%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.positive,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (totalOffers != null && totalOffers! > 0) ...[
            const SizedBox(height: 16),
            BalanceHeader(
              count: totalOffers!,
              label: 'Verified Bank Deals',
              deltaText: 'Live & active across Sri Lanka',
              isPositive: true,
            ),
          ],
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: l10n.text('searchBankOffers'),
            child: Pressable(
              onTap: () => context.push('/search'),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.dSurfaceHigh : AppColors.lSurface,
                  border: Border.all(color: cardBorder, width: 1.0),
                  borderRadius: BorderRadius.circular(Radii.md),
                  boxShadow:
                      isDark
                          ? null
                          : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.text('searchBankOffers'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: secondary, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Neobank Quick Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickAction(
                icon: Icons.near_me_outlined,
                label: l10n.text('nearbyOffers'),
                isDark: isDark,
                onTap:
                    () => TabNavigation.openExplore(
                      const ExploreRequest(segment: ExploreSegment.nearby),
                    ),
              ),
              _QuickAction(
                icon: Icons.credit_card_outlined,
                label: l10n.text('myCards'),
                isDark: isDark,
                onTap: () => context.push('/preferences'),
              ),
              _QuickAction(
                icon: Icons.timer_outlined,
                label: l10n.text('endingSoon'),
                isDark: isDark,
                onTap: () => TabNavigation.openExplore(const ExploreRequest()),
              ),
              _QuickAction(
                icon: Icons.explore_outlined,
                label: l10n.text('allOffers'),
                isDark: isDark,
                onTap: () => TabNavigation.openExplore(const ExploreRequest()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.dSurfaceHigh : AppColors.lSurfaceHigh;
    final fg = isDark ? AppColors.dTextPrimary : AppColors.lTextPrimary;
    final border = isDark ? AppColors.dBorder : AppColors.lBorder;

    return Pressable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(Radii.pill),
              border: Border.all(color: border, width: 0.8),
            ),
            child: Icon(icon, color: fg, size: 22),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
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

/// The ten supported banks with neobank card tiles.
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
        isDark ? AppColors.dTextSecondary : AppColors.lTextSecondary;
    final border = isDark ? AppColors.dBorder : AppColors.lBorder;
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
      child: Pressable(
        onTap: none ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            color:
                none
                    ? (isDark
                        ? AppColors.dBackground
                        : AppColors.lSurfaceHigh)
                    : (isDark ? AppColors.dSurface : AppColors.lSurface),
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: border, width: 1.0),
            boxShadow:
                none || isDark
                    ? null
                    : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Text(
                      bank.short,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (count != null && count! > 0)
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: secondary,
                        fontFeatures: AppTextStyles.tabularFeatures,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                bank.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  height: 1.25,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondary,
                    fontFeatures: AppTextStyles.tabularFeatures,
                  ),
                ),
              ],
            ],
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
    final border = isDark ? AppColors.dBorder : AppColors.lBorder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.dSurface : AppColors.lSurface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: border, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.text('chooseBanksCards'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.text('relevantOffers'),
                    style: TextStyle(
                      height: 1.35,
                      fontSize: 12.5,
                      color:
                          isDark
                              ? AppColors.dTextSecondary
                              : AppColors.lTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
              ),
              onPressed: () => context.push('/preferences'),
              child: Text(
                l10n.text('chooseCards'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
