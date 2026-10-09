import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../home/home_screen.dart';
import '../explore/explore_screen.dart';
import '../saved/saved_offers_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const SavedOffersScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navItems = [
      {
        'label': l10n.text('homeNav'),
        'icon': Icons.local_fire_department_outlined,
        'activeIcon': Icons.local_fire_department_rounded,
      },
      {
        'label': l10n.text('exploreNav'),
        'icon': Icons.explore_outlined,
        'activeIcon': Icons.explore_rounded,
      },
      {
        'label': l10n.text('savedNav'),
        'icon': Icons.favorite_border_rounded,
        'activeIcon': Icons.favorite_rounded,
      },
      {
        'label': l10n.text('settingsNav'),
        'icon': Icons.person_outline_rounded,
        'activeIcon': Icons.person_rounded,
      },
    ];

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE),
              width: 0.8,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final isSelected = _currentIndex == index;
                final item = navItems[index];

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    splashColor: AppColors.primary.withValues(alpha: 0.1),
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: isSelected ? 12 : 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : const Color(0xFFFFF0F0))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isSelected
                                ? (item['activeIcon'] as IconData)
                                : (item['icon'] as IconData),
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkTextTertiary
                                    : const Color(0xFF7A7E85)),
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkTextTertiary
                                    : const Color(0xFF7A7E85)),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 14,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC700),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ] else
                          const SizedBox(height: 4.5),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

}
