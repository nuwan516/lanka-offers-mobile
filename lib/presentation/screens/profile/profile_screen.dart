import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../common/widgets/language_selector.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmClear(
    BuildContext context, {
    required String title,
    required String key,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await getIt<SharedPreferences>().remove(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('settingsNav'))),
      body: ListView(
        children: [
          _Header(l10n.preferences),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: Text(l10n.text('myBanksCards')),
            onTap: () => context.push('/preferences'),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(l10n.text('preferredCategories')),
            subtitle: const Text('Coming in a future API update'),
          ),
          ListTile(
            leading: const Icon(Icons.location_city_outlined),
            title: Text(l10n.text('preferredDistricts')),
            subtitle: const Text('Coming in a future API update'),
          ),
          ListTile(
            leading: const Icon(Icons.radar),
            title: Text(l10n.text('nearbyRadius')),
            subtitle: const Text('10 km'),
          ),
          _Header(l10n.text('appSettings')),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            onTap:
                () => showDialog<void>(
                  context: context,
                  builder: (_) => const LanguageSelectorDialog(),
                ),
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(l10n.location),
            subtitle: Text(l10n.text('locationOffBody')),
            onTap: () => getIt.get<SharedPreferences>(),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(l10n.text('clearRecent')),
            onTap:
                () => _confirmClear(
                  context,
                  title: l10n.text('clearRecent'),
                  key: StorageKeys.recentSearches,
                ),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_remove_outlined),
            title: Text(l10n.text('clearSaved')),
            onTap:
                () => _confirmClear(
                  context,
                  title: l10n.text('clearSaved'),
                  key: StorageKeys.savedOffers,
                ),
          ),
          _Header(l10n.text('support')),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(l10n.text('reportOffer')),
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: Text(l10n.text('sendFeedback')),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicy),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.termsOfService),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.text('aboutLankaOffers')),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}
