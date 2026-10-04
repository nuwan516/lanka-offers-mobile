import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/phase_two_survey_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../common/widgets/bank_badge.dart';
import '../../common/widgets/error_view.dart';
import '../../common/widgets/loading_shimmer.dart';
import '../../common/widgets/offer_card.dart';
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
  String? _selectedBank;
  String? _selectedCategory;

  static const List<String> _bankList = [
    'All Banks',
    'Commercial Bank',
    'HNB',
    'Sampath Bank',
    'Bank of Ceylon',
    'Seylan Bank',
    'People\'s Bank',
    'DFCC Bank',
    'NDB Bank',
    'NSB',
    'Amex',
  ];

  static const List<Map<String, dynamic>> _categories = [
    {'name': 'All Categories', 'icon': Icons.grid_view_rounded},
    {'name': 'Dining', 'icon': Icons.restaurant_rounded},
    {'name': 'Hotels & Travel', 'icon': Icons.hotel_rounded},
    {'name': 'Supermarket', 'icon': Icons.local_grocery_store_rounded},
    {'name': 'Fashion', 'icon': Icons.checkroom_rounded},
    {'name': 'Electronics', 'icon': Icons.devices_rounded},
    {'name': 'Healthcare', 'icon': Icons.local_hospital_rounded},
    {'name': 'Fuel & Auto', 'icon': Icons.local_gas_station_rounded},
  ];

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
      () => _hasPreferences = preferences.selectedBanks.isNotEmpty ||
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
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
                    onChanged: (value) => setModalState(() => response = value),
                  ),
                FilledButton(
                  onPressed: response == null
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

  List<BankOffer> _filterOffers(List<BankOffer> offers) {
    var result = offers;
    if (_selectedBank != null && _selectedBank != 'All Banks') {
      final q = _selectedBank!.toLowerCase().replaceAll(' bank', '').trim();
      result = result
          .where((o) => o.bankName.toLowerCase().contains(q))
          .toList();
    }
    if (_selectedCategory != null && _selectedCategory != 'All Categories') {
      final q = _selectedCategory!.toLowerCase();
      result = result
          .where((o) => o.category.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
              appBar: AppBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_offer_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.appName,
                      style: AppTextStyles.h2.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: l10n.searchHint,
                    onPressed: () => context.push('/search'),
                    icon: Icon(
                      Icons.search,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Saved Offers',
                    onPressed: () => context.push('/saved'),
                    icon: Icon(
                      Icons.bookmark_border_rounded,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              body: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is HomeLoading) return const LoadingShimmer.feed();
                  if (state is HomeError) {
                    return ErrorView(
                      message: l10n.text('connectionRetry'),
                      onRetry: () =>
                          context.read<HomeBloc>().add(LoadHomeData()),
                    );
                  }
                  if (state is! HomeLoaded) return const SizedBox.shrink();

                  final filteredFeatured = _filterOffers(state.featuredOffers);
                  final filteredAll = _filterOffers(state.allOffers);
                  final filteredNearby = _filterOffers(state.nearbyOffers);
                  final endingSoon = filteredAll.where(_expiresSoon).toList();

                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<HomeBloc>().add(RefreshHomeData()),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      children: [
                        // Hero Banner with modern gradient and search bar trigger
                        _buildHeroBanner(context, isDark, l10n),

                        const SizedBox(height: 18),

                        // Bank Quick-Filter Horizontal Scroll
                        _buildBankFilterRow(isDark),

                        const SizedBox(height: 14),

                        // Category Quick-Filter Horizontal Scroll
                        _buildCategoryFilterRow(isDark),

                        // Card Personalization Banner
                        if (!_hasPreferences) ...[
                          const SizedBox(height: 18),
                          _buildPersonalizeCardBanner(context, isDark, l10n),
                        ],

                        // Featured Offers Section
                        if (filteredFeatured.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            context: context,
                            title: l10n.featuredOffers,
                            count: filteredFeatured.length,
                            onSeeAll: () => context.push('/explore'),
                          ),
                          const SizedBox(height: 12),
                          for (int i = 0; i < filteredFeatured.take(4).length; i++)
                            OfferCard(
                              offer: filteredFeatured[i],
                              contextOffers: filteredFeatured,
                              initialIndex: i,
                            ),
                        ],

                        // Ending Soon Section
                        if (endingSoon.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            context: context,
                            title: l10n.endingSoon,
                            count: endingSoon.length,
                            icon: Icons.local_fire_department_rounded,
                            iconColor: AppColors.urgentRed,
                            onSeeAll: () => context.push('/explore'),
                          ),
                          const SizedBox(height: 12),
                          for (int i = 0; i < endingSoon.take(3).length; i++)
                            OfferCard(
                              offer: endingSoon[i],
                              contextOffers: endingSoon,
                              initialIndex: i,
                            ),
                        ],

                        // Nearby Offers Teaser
                        if (filteredNearby.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            context: context,
                            title: l10n.nearbyOffers,
                            count: filteredNearby.length,
                            icon: Icons.near_me_rounded,
                            iconColor: isDark ? AppColors.primaryLight : AppColors.primary,
                            actionLabel: 'View on Map',
                            onSeeAll: () => context.push('/explore'),
                          ),
                          const SizedBox(height: 12),
                          for (int i = 0; i < filteredNearby.take(3).length; i++)
                            OfferCard(
                              offer: filteredNearby[i],
                              contextOffers: filteredNearby,
                              initialIndex: i,
                            ),
                        ],

                        // All Verified Offers Section
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          context: context,
                          title: l10n.text('allBankOffers'),
                          count: filteredAll.length,
                        ),
                        const SizedBox(height: 12),
                        if (filteredAll.isEmpty)
                          _buildEmptyFilterState(isDark)
                        else
                          for (int i = 0; i < filteredAll.take(15).length; i++)
                            OfferCard(
                              offer: filteredAll[i],
                              contextOffers: filteredAll,
                              initialIndex: i,
                            ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            );
  }

  Widget _buildHeroBanner(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFE03C31), const Color(0xFFB8251A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.primary).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SRI LANKA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '10+ Banks Verified',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.text('findNextOffer'),
            style: AppTextStyles.h1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dining discounts, 1-for-1 deals, installment plans & cashback',
            style: AppTextStyles.body2.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          // Search Bar Trigger
          Semantics(
            button: true,
            label: l10n.text('searchBankOffers'),
            child: InkWell(
              onTap: () => context.push('/search'),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155).withValues(alpha: 0.8)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.text('searchBankOffers'),
                        style: AppTextStyles.body2.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Filter',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankFilterRow(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filter by Bank',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            if (_selectedBank != null && _selectedBank != 'All Banks')
              GestureDetector(
                onTap: () => setState(() => _selectedBank = null),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _bankList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final bank = _bankList[index];
              final isSelected = (_selectedBank == null && index == 0) ||
                  _selectedBank == bank;

              if (index == 0) {
                return _buildFilterChip(
                  label: bank,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedBank = null),
                );
              }

              final brandColor = BankBadge.bankBrandColor(bank);
              final initials = BankBadge.bankInitials(bank);

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedBank = isSelected ? null : bank;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? brandColor
                        : (isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.surfaceVariant),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? brandColor
                          : (isDark ? AppColors.darkBorder : AppColors.border),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : brandColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        bank,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterRow(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            if (_selectedCategory != null && _selectedCategory != 'All Categories')
              GestureDetector(
                onTap: () => setState(() => _selectedCategory = null),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final name = cat['name'] as String;
              final icon = cat['icon'] as IconData;
              final isSelected = (_selectedCategory == null && index == 0) ||
                  _selectedCategory == name;

              return _buildFilterChip(
                label: name,
                icon: icon,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    if (index == 0) {
                      _selectedCategory = null;
                    } else {
                      _selectedCategory = isSelected ? null : name;
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeBg = isDark ? AppColors.primaryLight : AppColors.primary;
    final inactiveBg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final inactiveFg = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final borderColor = isSelected
        ? activeBg
        : (isDark ? AppColors.darkBorder : AppColors.border);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : inactiveFg,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : inactiveFg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizeCardBanner(
      BuildContext context, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryLight : AppColors.primary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.credit_card_rounded,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.text('chooseBanksCards'),
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.text('relevantOffers'),
                  style: AppTextStyles.body2.copyWith(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await context.push('/preferences');
              _prepareLocalExperience();
            },
            child: Text(
              l10n.text('chooseCards'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required int count,
    IconData? icon,
    Color? iconColor,
    String? actionLabel,
    VoidCallback? onSeeAll,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel ?? 'See all',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyFilterState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.filter_alt_off_rounded,
            size: 40,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'No offers match the selected filters',
            style: AppTextStyles.h4.copyWith(
              fontSize: 14,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try clearing your bank or category filter to see more deals',
            textAlign: TextAlign.center,
            style: AppTextStyles.body2.copyWith(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () {
              setState(() {
                _selectedBank = null;
                _selectedCategory = null;
              });
            },
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  bool _expiresSoon(BankOffer offer) {
    if (offer.validity.hasNoConfiguredExpiry) return false;
    final days = offer.validity.validUntil.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 7;
  }
}
