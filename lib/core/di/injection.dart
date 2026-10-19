import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/offer_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/offer_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../services/language_service.dart';
import '../services/location_service.dart';
import '../services/phase_two_survey_service.dart';
import '../../domain/usecases/get_all_offers.dart';
import '../../domain/usecases/get_banks.dart';
import '../../domain/usecases/get_offers_by_type.dart';
import '../../domain/usecases/search_offers.dart';
import '../../domain/usecases/filter_offers.dart';
import '../../domain/usecases/get_nearby_offers.dart';
import '../../domain/usecases/save_offer.dart';
import '../../domain/usecases/unsave_offer.dart';
import '../../domain/usecases/get_saved_offers.dart';
import '../../domain/usecases/toggle_offer_favorite.dart';
import '../../presentation/screens/home/bloc/home_bloc.dart';
import '../../presentation/screens/search/bloc/search_bloc.dart';
import '../../presentation/screens/saved/bloc/saved_bloc.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Services
  getIt.registerSingleton<LanguageService>(LanguageService(sharedPreferences));
  getIt.registerSingleton<LocationService>(LocationService());
  getIt.registerSingleton<PhaseTwoSurveyService>(
    PhaseTwoSurveyService(sharedPreferences),
  );

  // Repositories
  getIt.registerLazySingleton<OfferRepository>(() => OfferRepositoryImpl());

  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(getIt<SharedPreferences>()),
  );

  // Use cases
  getIt.registerLazySingleton(() => GetAllOffers(getIt<OfferRepository>()));
  getIt.registerLazySingleton(() => GetOffersByType(getIt<OfferRepository>()));
  getIt.registerLazySingleton(() => GetBanks(getIt<OfferRepository>()));
  getIt.registerLazySingleton(() => SearchOffers(getIt<OfferRepository>()));
  getIt.registerLazySingleton(() => FilterOffers(getIt<OfferRepository>()));
  getIt.registerLazySingleton(() => GetNearbyOffers(getIt<OfferRepository>()));
  getIt.registerLazySingleton(() => SaveOffer(getIt<UserRepository>()));
  getIt.registerLazySingleton(() => UnsaveOffer(getIt<UserRepository>()));
  getIt.registerLazySingleton(() => GetSavedOffers(getIt<UserRepository>()));
  getIt.registerLazySingleton(
    () => ToggleOfferFavorite(getIt<UserRepository>()),
  );

  // BLoCs
  getIt.registerFactory(
    () => HomeBloc(
      getAllOffers: getIt<GetAllOffers>(),
      getNearbyOffers: getIt<GetNearbyOffers>(),
      getBanks: getIt<GetBanks>(),
    ),
  );

  getIt.registerFactory(
    () => SearchBloc(
      searchOffers: getIt<SearchOffers>(),
      userRepository: getIt<UserRepository>(),
    ),
  );

  getIt.registerFactory(
    () => SavedBloc(
      userRepository: getIt<UserRepository>(),
      offerRepository: getIt<OfferRepository>(),
    ),
  );
}
