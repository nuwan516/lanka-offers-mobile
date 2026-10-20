import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/pressable.dart';
import '../../common/widgets/language_selector.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmClear(
    BuildContext context, {
    required String title,
    required String key,
  }) async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.lg),
            ),
            title: Text(title),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.negative,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clear'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      await getIt<SharedPreferences>().remove(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorder = isDark ? AppColors.dBorder : AppColors.lBorder;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.text('settingsNav'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Trust & Security Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.dSurface : AppColors.lSurface,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.positive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: AppColors.positive,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '100% Privacy & Local Storage',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Preferences and bookmarks stay on your phone. No tracking.',
                        style: TextStyle(
                          fontSize: 12,
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
            ),
          ),
          const SizedBox(height: 8),

          _Header(l10n.preferences),
          _CardGroup(
            isDark: isDark,
            children: [
              _SettingTile(
                icon: Icons.credit_card_rounded,
                title: l10n.text('myBanksCards'),
                onTap: () => context.push('/preferences'),
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: Icons.category_outlined,
                title: l10n.text('preferredCategories'),
                subtitle: 'Coming in a future API update',
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: Icons.location_city_outlined,
                title: l10n.text('preferredDistricts'),
                subtitle: 'Coming in a future API update',
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: Icons.radar_rounded,
                title: l10n.text('nearbyRadius'),
                subtitle: '10 km',
              ),
            ],
          ),

          _Header(l10n.text('appSettings')),
          _CardGroup(
            isDark: isDark,
            children: [
              _SettingTile(
                icon: Icons.language_rounded,
                title: l10n.language,
                onTap:
                    () => showDialog<void>(
                      context: context,
                      builder: (_) => const LanguageSelectorDialog(),
                    ),
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: Icons.location_on_outlined,
                title: l10n.location,
                subtitle: l10n.text('locationOffBody'),
                onTap: () => getIt.get<SharedPreferences>(),
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: Icons.history_rounded,
                title: l10n.text('clearRecent'),
                onTap:
                    () => _confirmClear(
                      context,
                      title: l10n.text('clearRecent'),
                      key: StorageKeys.recentSearches,
                    ),
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: Icons.bookmark_remove_outlined,
                title: l10n.text('clearSaved'),
                onTap:
                    () => _confirmClear(
                      context,
                      title: l10n.text('clearSaved'),
                      key: StorageKeys.savedOffers,
                    ),
              ),
            ],
          ),

          _Header(l10n.text('support')),
          _CardGroup(
            isDark: isDark,
            children: [
              _SettingTile(
                icon: Icons.flag_outlined,
                title: l10n.text('reportOffer'),
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: Icons.feedback_outlined,
                title: l10n.text('sendFeedback'),
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: Icons.privacy_tip_outlined,
                title: l10n.privacyPolicy,
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: Icons.description_outlined,
                title: l10n.termsOfService,
              ),
              _Divider(isDark: isDark),
              _SettingTile(
                icon: Icons.info_outline_rounded,
                title: l10n.text('aboutLankaOffers'),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _CardGroup extends StatelessWidget {
  const _CardGroup({required this.isDark, required this.children});
  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cardBorder = isDark ? AppColors.dBorder : AppColors.lBorder;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.dSurface : AppColors.lSurface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: cardBorder, width: 1.0),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: isDark ? AppColors.dBorder : AppColors.lBorder,
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.dTextSecondary : AppColors.lTextSecondary;

    return Pressable(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: AppColors.accent, size: 22),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
        subtitle:
            subtitle != null
                ? Text(
                  subtitle!,
                  style: TextStyle(fontSize: 12, color: secondary),
                )
                : null,
        trailing:
            onTap != null
                ? Icon(
                  Icons.chevron_right_rounded,
                  color:
                      isDark
                          ? AppColors.dTextTertiary
                          : AppColors.lTextTertiary,
                  size: 20,
                )
                : null,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 16, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
  );
}
