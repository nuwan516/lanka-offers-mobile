import 'package:go_router/go_router.dart';
import '../../domain/entities/bank_offer.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/main_navigation/main_navigation_screen.dart';
import '../screens/offer_detail/offer_detail_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/preferences/bank_card_preferences_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const MainNavigationScreen(),
    ),
    GoRoute(
      path: '/offer/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        final extraMap =
            state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : null;
        final offers = extraMap?['offers'] as List<BankOffer>?;
        final initialIndex = extraMap?['initialIndex'] as int?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: OfferDetailScreen(
            offerId: id,
            contextOffers: offers,
            initialIndex: initialIndex,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
      },
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/explore',
      builder: (context, state) => const ExploreScreen(),
    ),
    GoRoute(
      path: '/preferences',
      builder: (context, state) => const BankCardPreferencesScreen(),
    ),
  ],
);
