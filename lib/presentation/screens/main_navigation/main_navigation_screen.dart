import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../routes/tab_navigation.dart';
import '../explore/explore_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../saved/saved_offers_screen.dart';

/// The four primary destinations: Home, Explore (browse, nearby, banks),
/// Saved and Settings. Search is reached from the search bars.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const int _exploreIndex = 1;

  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const SavedOffersScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    TabNavigation.exploreRequest.addListener(_onExploreRequest);
  }

  @override
  void dispose() {
    TabNavigation.exploreRequest.removeListener(_onExploreRequest);
    super.dispose();
  }

  /// Home asks for Explore (bank shortcut, category, nearby). The Explore
  /// screen reads and clears the request when it is built.
  void _onExploreRequest() {
    if (TabNavigation.exploreRequest.value != null &&
        _currentIndex != _exploreIndex) {
      setState(() => _currentIndex = _exploreIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.text('homeNav'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore_rounded),
            label: l10n.text('exploreNav'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border_rounded),
            selectedIcon: const Icon(Icons.favorite_rounded),
            label: l10n.text('savedNav'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l10n.text('settingsNav'),
          ),
        ],
      ),
    );
  }
}
