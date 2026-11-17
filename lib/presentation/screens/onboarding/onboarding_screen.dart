import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/location_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  List<(IconData, String, String)> _pages(AppLocalizations l10n) => [
    (
      Icons.account_balance_outlined,
      l10n.text('onboardTitleOffers'),
      l10n.text('onboardBodyOffers'),
    ),
    (
      Icons.credit_card_rounded,
      l10n.text('onboardTitleCards'),
      l10n.text('onboardBodyCards'),
    ),
    (
      Icons.near_me_outlined,
      l10n.text('onboardTitleNearby'),
      l10n.text('onboardBodyNearby'),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _pages(l10n);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(l10n.text('onboardSkip')),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Icon(
                              page.$1,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
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
                            child: Text(l10n.text('onboardAllowLocation')),
                          ),
                          TextButton(
                            onPressed: _finish,
                            child: Text(l10n.text('onboardWithoutLocation')),
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
                          child: Text(
                            _page == 0
                                ? l10n.text('onboardGetStarted')
                                : l10n.text('onboardContinue'),
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
