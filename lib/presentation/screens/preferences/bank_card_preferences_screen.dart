import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
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
      final discoveredNetworks = offers
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.text('myBanksCards')),
        actions: [
          TextButton(
            onPressed:
                () => setState(() {
                  _selectedBanks.clear();
                  _cardTypes.clear();
                  _networks.clear();
                }),
            child: Text(l10n.text('clearAll')),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Section(
                    title: l10n.text('banks'),
                    children:
                        _banks
                            .map(
                              (bank) => FilterChip(
                                avatar: CircleAvatar(
                                  child: Text(bank.characters.first),
                                ),
                                label: Text(bank),
                                selected: _selectedBanks.contains(bank),
                                onSelected:
                                    (selected) => setState(
                                      () =>
                                          selected
                                              ? _selectedBanks.add(bank)
                                              : _selectedBanks.remove(bank),
                                    ),
                              ),
                            )
                            .toList(),
                  ),
                  _Section(
                    title: l10n.text('cardTypes'),
                    children:
                        [l10n.text('creditCard'), l10n.text('debitCard')]
                            .map(
                              (type) => FilterChip(
                                label: Text(type),
                                selected: _cardTypes.contains(type),
                                onSelected:
                                    (selected) => setState(
                                      () =>
                                          selected
                                              ? _cardTypes.add(type)
                                              : _cardTypes.remove(type),
                                    ),
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
                                    (selected) => setState(
                                      () =>
                                          selected
                                              ? _networks.add(network)
                                              : _networks.remove(network),
                                    ),
                              ),
                            )
                            .toList(),
                  ),
                  if (_selectedBanks.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Card Matching Preview',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Offers from ${_selectedBanks.join(', ')} matching ${_cardTypes.isEmpty ? "All Card Types" : _cardTypes.join(" or ")}${_networks.isEmpty ? "" : " on ${_networks.join(', ')}"} will be matched.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.text('savePreferences')),
                  ),
                ],
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
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    ),
  );
}
