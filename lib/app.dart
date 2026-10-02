import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/language_service.dart';
import 'core/di/injection.dart';
import 'presentation/routes/app_router.dart';

class LankaOffersApp extends StatefulWidget {
  const LankaOffersApp({super.key});

  @override
  State<LankaOffersApp> createState() => _LankaOffersAppState();
}

class _LankaOffersAppState extends State<LankaOffersApp> {
  Locale _locale = const Locale('en', '');
  final LanguageService _languageService = getIt<LanguageService>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final savedLocale = await _languageService.getSavedLocale();
    setState(() {
      _locale = savedLocale;
      _isLoading = false;
    });
  }

  void changeLocale(Locale newLocale) async {
    await _languageService.setLocale(newLocale);
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      title: 'Lanka Offers',
      theme: AppTheme.lightTheme,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LanguageService.supportedLocales,
      locale: _locale,
    );
  }
}

// Global key to access app state
final GlobalKey<_LankaOffersAppState> appStateKey =
    GlobalKey<_LankaOffersAppState>();

// Extension to change language from anywhere
extension LanguageChangeExtension on BuildContext {
  void changeLanguage(Locale locale) {
    final appState = appStateKey.currentState;
    appState?.changeLocale(locale);
  }
}
