import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../../domain/entities/user_preferences.dart';
import '../../../domain/repositories/offer_repository.dart';
import '../../../domain/repositories/user_repository.dart';

class BankCardPreferencesScreen extends StatefulWidget {
  const BankCardPreferencesScreen({super.key});

  @override
  State<BankCardPreferencesScreen> createState() =>
      _BankCardPreferencesScreenState();
}

class _BankCardPreferencesScreenState extends State<BankCardPreferencesScreen> {
  final _selectedBanks = <String>{};
  final _cardTypes = <String>{};
  final _networks = <String>{};
  List<String> _banks = const [];
  List<String> _availableNetworks = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final offers =
        (await getIt<OfferRepository>().getAllOffers())
            .whereType<BankOffer>()
            .toList();
    final preferences = await getIt<UserRepository>().getPreferences();
    if (!mounted) return;
    setState(() {
      _banks = offers.map((e) => e.bankName).toSet().toList()..sort();
      final discoveredNetworks =
          offers
              .expand((e) => e.cardEligibility?.networks ?? <String>[])
              .where((e) => e.isNotEmpty)
              .toSet();
      final allNetworks = {'Visa', 'Mastercard', 'Amex', ...discoveredNetworks};
      _availableNetworks = allNetworks.toList()..sort();
      _selectedBanks.addAll(preferences.selectedBanks);
      _cardTypes.addAll(preferences.cardTypes);
      _networks.addAll(preferences.cardNetworks);
      _loading = false;
    });
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    final old = await getIt<UserRepository>().getPreferences();
    await getIt<UserRepository>().savePreferences(
      UserPreferences(
        selectedBanks: _selectedBanks.toList(),
        cardTypes: _cardTypes.toList(),
        cardNetworks: _networks.toList(),
        preferredCategories: old.preferredCategories,
        preferredDistricts: old.preferredDistricts,
        preferredRadiusKm: old.preferredRadiusKm,
        savedCards: old.savedCards,
        notificationsEnabled: old.notificationsEnabled,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.text('preferencesSaved')),
      ),
    );
    Navigator.of(context).maybePop();
  }

  void _onToggleBank(String bank, bool selected) {
    HapticFeedback.selectionClick();
    setState(() {
      selected ? _selectedBanks.add(bank) : _selectedBanks.remove(bank);
    });
  }

  void _onToggleType(String type, bool selected) {
    HapticFeedback.selectionClick();
    setState(() {
      selected ? _cardTypes.add(type) : _cardTypes.remove(type);
    });
  }

  void _onToggleNetwork(String network, bool selected) {
    HapticFeedback.selectionClick();
    setState(() {
      selected ? _networks.add(network) : _networks.remove(network);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayBank =
        _selectedBanks.isNotEmpty ? _selectedBanks.first : 'Lanka Offers';
    final displayType =
        _cardTypes.isNotEmpty ? _cardTypes.first : 'Credit Card';
    final displayNetwork =
        _networks.isNotEmpty ? _networks.first : 'Visa / Mastercard';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('myBanksCards')),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedBanks.clear();
                _cardTypes.clear();
                _networks.clear();
              });
            },
            child: Text(l10n.text('clearAll')),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        children: [
                          // Bank Card Filter Preferences Summary
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0F5F5C),
                                  Color(0xFF0A4644),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F5F5C).withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.credit_card_rounded, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Card Filter Preferences',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'LOCAL ONLY',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  displayBank,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$displayType • $displayNetwork',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 14, color: Colors.white.withValues(alpha: 0.85)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Your bank preferences are saved on this device. No card numbers or personal details are collected or stored.',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.85),
                                            fontSize: 11,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _Section(
                            title: l10n.text('banks'),
                            children:
                                _banks
                                    .map(
                                      (bank) => FilterChip(
                                        avatar: CircleAvatar(
                                          backgroundColor:
                                              AppColors.accent.withValues(
                                                alpha: 0.15,
                                              ),
                                          child: Text(
                                            bank.characters.first,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.accent,
                                            ),
                                          ),
                                        ),
                                        label: Text(bank),
                                        selected: _selectedBanks.contains(bank),
                                        onSelected:
                                            (s) => _onToggleBank(bank, s),
                                      ),
                                    )
                                    .toList(),
                          ),
                          _Section(
                            title: l10n.text('cardTypes'),
                            children:
                                [
                                  l10n.text('creditCard'),
                                  l10n.text('debitCard'),
                                ]
                                    .map(
                                      (type) => FilterChip(
                                        label: Text(type),
                                        selected: _cardTypes.contains(type),
                                        onSelected:
                                            (s) => _onToggleType(type, s),
                                      ),
                                    )
                                    .toList(),
                          ),
                          _Section(
                            title: l10n.text('cardNetworks'),
                            children:
                                _availableNetworks
                                    .map(
                                      (network) => FilterChip(
                                        label: Text(network),
                                        selected: _networks.contains(network),
                                        onSelected:
                                            (s) => _onToggleNetwork(network, s),
                                      ),
                                    )
                                    .toList(),
                          ),
                          if (_selectedBanks.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? AppColors.dSurfaceHigh
                                        : AppColors.lSurfaceHigh,
                                borderRadius: BorderRadius.circular(Radii.md),
                                border: Border.all(
                                  color:
                                      isDark
                                          ? AppColors.dBorder
                                          : AppColors.lBorder,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.verified_outlined,
                                        size: 16,
                                        color: AppColors.positive,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Card Matching Preview',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Offers from ${_selectedBanks.join(', ')} matching ${_cardTypes.isEmpty ? "All Card Types" : _cardTypes.join(" or ")}${_networks.isEmpty ? "" : " on ${_networks.join(', ')}"} will be matched.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          isDark
                                              ? AppColors.dTextSecondary
                                              : AppColors.lTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    // Pinned 56px CTA above safe area
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: AppButton(
                        label: l10n.text('savePreferences'),
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
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
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    ),
  );
}
