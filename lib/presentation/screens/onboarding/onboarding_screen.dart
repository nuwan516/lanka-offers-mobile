import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/location_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      Icons.account_balance_outlined,
      'All your bank offers in one place',
      'Discover dining, shopping, travel and service offers available for Sri Lankan bank cards.',
    ),
    (
      Icons.credit_card,
      'Choose your banks and cards',
      'Select the banks and card types you use to find more relevant offers.',
    ),
    (
      Icons.near_me_outlined,
      'Find offers near you',
      'Allow location access to discover offers around you, or continue without sharing your location.',
    ),
  ];

  Future<void> _finish({bool requestLocation = false}) async {
    if (requestLocation) {
      await getIt<LocationService>().requestPermission();
    }
    await getIt<SharedPreferences>().setBool(
      StorageKeys.onboardingCompleted,
      true,
    );
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _finish, child: const Text('Skip')),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        page.$1,
                        size: 112,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 40),
                      Text(
                        page.$2,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        page.$3,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child:
                _page == 2
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: () => _finish(requestLocation: true),
                          child: const Text('Allow Location'),
                        ),
                        TextButton(
                          onPressed: _finish,
                          child: const Text('Continue Without Location'),
                        ),
                      ],
                    )
                    : SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            () => _controller.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            ),
                        child: Text(_page == 0 ? 'Get Started' : 'Continue'),
                      ),
                    ),
          ),
        ],
      ),
    ),
  );
}
