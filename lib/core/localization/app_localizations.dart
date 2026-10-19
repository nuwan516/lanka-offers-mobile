import 'package:flutter/material.dart';

import 'redesign_strings.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Common
      'appName': 'Lanka Offers',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'save': 'Save',
      'share': 'Share',
      'viewDetails': 'View Details',
      'seeAll': 'See All',

      // Home
      'featuredOffers': 'Featured Offers',
      'nearbyOffers': 'Nearby Offers',
      'trendingCategories': 'Trending Categories',
      'recentlyViewed': 'Recently Viewed',
      'allOffers': 'All Offers',
      'homeBannerTitle': 'Bank card offers, in one place',
      'homeBannerBadge': 'LIVE OFFERS',
      'homeBannerSubtitle': 'Dining • Supermarkets • Hotels • Installments',
      'quickFilters': 'Quick Filters',
      'endingSoon': 'Ending Soon',
      'nearby': 'Nearby',
      'myCards': 'My Cards',
      'verified': 'Verified',
      'trending': 'Trending',
      'currentLocation': 'Current Location',

      // Search
      'searchHint': 'Search offers, shops, events...',
      'recentSearches': 'Recent Searches',
      'popularSearches': 'Popular Searches',
      'noResults': 'No results found',

      // Filters
      'filter': 'Filter',
      'sort': 'Sort',
      'apply': 'Apply',
      'reset': 'Reset',

      // Offer Detail
      'validUntil': 'Valid Until',
      'termsAndConditions': 'Terms & Conditions',
      'contactInfo': 'Contact Information',
      'similarOffers': 'Similar Offers',
      'locations': 'Locations',

      // Saved
      'savedOffers': 'Saved Offers',
      'noSavedOffers': 'No saved offers yet',

      // Profile
      'profile': 'Profile',
      'preferences': 'Preferences',
      'settings': 'Settings',
      'about': 'About',
      'language': 'Language',
      'location': 'Location',
      'notifications': 'Notifications',
      'helpSupport': 'Help & Support',
      'account': 'Account',
      'saved': 'Saved',
      'viewed': 'Viewed',
      'shared': 'Shared',
      'privacyPolicy': 'Privacy Policy',
      'termsOfService': 'Terms of Service',
      'signOut': 'Sign Out',
      'signOutConfirm': 'Are you sure you want to sign out?',
      'ok': 'OK',
      'openSettings': 'Open Settings',
      'locationServicesDisabled':
          'Location services are disabled. Please enable location services in your device settings.',
      'locationPermissionRequired':
          'Location permission is required to show your current location. Please enable it in app settings.',
      'offerDetails': 'Offer Details',
      'category': 'Category',
      'tags': 'Tags',
      'phone': 'Phone',
      'email': 'Email',
      'website': 'Website',
      'getDirections': 'Get Directions',
      'saveOffer': 'Save Offer',
      'offerSaved': 'Offer saved',
      'offerUnsaved': 'Offer unsaved',
      'noNewNotifications': 'No new notifications',
      'noEventsFound': 'No events found',
      'tryAdjustingFilters': 'Try adjusting your filters',
      'eventsMap': 'Events Map',
      'mapView': 'Map View',
      'aboutApp': 'About Lanka Offers',
      'appVersion':
          'Version 1.0.0\n\nA comprehensive app for discovering offers and events across Sri Lanka.',
      'viewYourSavedOffers': 'View your saved offers',
      'yourBrowsingHistory': 'Your browsing history',
      'manageYourBankCards': 'Manage your bank cards',
      'manageNotificationSettings': 'Manage notification settings',
      'getHelpAndContactSupport': 'Get help and contact support',
      'appVersionAndInformation': 'App version and information',
      'readOurPrivacyPolicy': 'Read our privacy policy',
      'readOurTermsOfService': 'Read our terms of service',
      'signedOut': 'Signed out',

      // Offer Types
      'bank': 'Bank',
      'shop': 'Shop',
      'promo': 'Promo',
      'events': 'Events',

      // Urgency
      'endingToday': 'Ending Today',
      'daysLeft': '{days} days left',
    },
    'si': {
      // Common
      'appName': 'ශ්‍රී ලංකා දීමනා',
      'loading': 'පූරණය වෙමින්...',
      'error': 'දෝෂයක්',
      'retry': 'නැවත උත්සාහ කරන්න',
      'cancel': 'අවලංගු කරන්න',
      'save': 'සුරකින්න',
      'share': 'බෙදාගන්න',
      'viewDetails': 'විස්තර බලන්න',
      'seeAll': 'සියල්ල බලන්න',

      // Home
      'featuredOffers': 'විශේෂ දීමනා',
      'nearbyOffers': 'ආසන්න දීමනා',
      'trendingCategories': 'ප්‍රවණතා කාණ්ඩ',
      'recentlyViewed': 'මෑතදී බැලූ',
      'allOffers': 'සියලුම දීමනා',
      'homeBannerTitle': 'බැංකු කාඩ්පත් දීමනා, එක තැනකින්',
      'homeBannerBadge': 'සජීවී දීමනා',
      'homeBannerSubtitle': 'ආහාර • සුපිරි වෙළඳසල් • හෝටල් • වාරික',
      'quickFilters': 'ඉක්මන් පෙරහන',
      'endingSoon': 'ඉක්මනින් අවසන් වේ',
      'nearby': 'ආසන්න',
      'myCards': 'මගේ කාඩ්පත්',
      'verified': 'සත්‍යාපනය කරන ලද',
      'trending': 'ප්‍රවණතාව',
      'currentLocation': 'වර්තමාන ස්ථානය',

      // Search
      'searchHint': 'දීමනා, වෙළඳසැල්, ඉසව් සොයන්න...',
      'recentSearches': 'මෑත සෙවීම්',
      'popularSearches': 'ජනප්‍රිය සෙවීම්',
      'noResults': 'ප්‍රතිඵල නැත',

      // Filters
      'filter': 'පෙරහන',
      'sort': 'වර්ගීකරණය',
      'apply': 'යොදන්න',
      'reset': 'නැවත සැකසීම',

      // Offer Detail
      'validUntil': 'වලංගු වන්නේ',
      'termsAndConditions': 'කොන්දේසි සහ නියම',
      'contactInfo': 'සම්බන්ධතා තොරතුරු',
      'similarOffers': 'සමාන දීමනා',
      'locations': 'ස්ථාන',

      // Saved
      'savedOffers': 'සුරක්ෂිත දීමනා',
      'noSavedOffers': 'තවමත් සුරක්ෂිත දීමනා නැත',

      // Profile
      'profile': 'පැතිකඩ',
      'preferences': 'අභිමතයන්',
      'settings': 'සැකසීම්',
      'about': 'පිළිබඳව',
      'language': 'භාෂාව',
      'location': 'ස්ථානය',
      'notifications': 'දැනුම්දීම්',
      'helpSupport': 'උදව් සහ සහාය',
      'account': 'ගිණුම',
      'saved': 'සුරක්ෂිත',
      'viewed': 'බැලූ',
      'shared': 'බෙදාගත්',
      'privacyPolicy': 'රහස්‍යතා ප්‍රතිපත්තිය',
      'termsOfService': 'සේවා කොන්දේසි',
      'signOut': 'ඉවත් වන්න',
      'signOutConfirm': 'ඔබට ඉවත් වීමට අවශ්‍ය බව විශ්වාසද?',
      'ok': 'හරි',
      'openSettings': 'සැකසීම් විවෘත කරන්න',
      'locationServicesDisabled':
          'ස්ථාන සේවා අක්‍රිය කර ඇත. කරුණාකර ඔබගේ උපාංග සැකසීම්වල ස්ථාන සේවා සක්‍රිය කරන්න.',
      'locationPermissionRequired':
          'වර්තමාන ස්ථානය පෙන්වීමට ස්ථාන අවසරය අවශ්‍ය වේ. කරුණාකර එය යෙදුම් සැකසීම්වල සක්‍රිය කරන්න.',
      'offerDetails': 'දීමනා විස්තර',
      'category': 'කාණ්ඩය',
      'tags': 'ටැග්',
      'phone': 'දුරකථන',
      'email': 'විද්‍යුත් තැපෑල',
      'website': 'වෙබ් අඩවිය',
      'getDirections': 'දිශාවන් ලබාගන්න',
      'saveOffer': 'දීමනාව සුරකින්න',
      'offerSaved': 'දීමනාව සුරක්ෂිත කරන ලදී',
      'offerUnsaved': 'දීමනාව ඉවත් කරන ලදී',
      'noNewNotifications': 'නව දැනුම්දීම් නැත',
      'noEventsFound': 'ඉසව් හමු නොවීය',
      'tryAdjustingFilters': 'ඔබගේ පෙරහන් සකස් කිරීමට උත්සාහ කරන්න',
      'eventsMap': 'ඉසව් සිතියම',
      'mapView': 'සිතියම් දර්ශනය',
      'aboutApp': 'ශ්‍රී ලංකා දීමනා පිළිබඳව',
      'appVersion':
          'අනුවාදය 1.0.0\n\nශ්‍රී ලංකාව පුරා දීමනා සහ ඉසව් සොයා ගැනීම සඳහා සවිස්තරාත්මක යෙදුමක්.',
      'viewYourSavedOffers': 'ඔබගේ සුරක්ෂිත දීමනා බලන්න',
      'yourBrowsingHistory': 'ඔබගේ පිරික්සුම් ඉතිහාසය',
      'manageYourBankCards': 'ඔබගේ බැංකු කාඩ්පත් කළමනාකරණය කරන්න',
      'manageNotificationSettings': 'දැනුම්දීම් සැකසීම් කළමනාකරණය කරන්න',
      'getHelpAndContactSupport': 'උදව් ලබාගෙන සහාය අමතන්න',
      'appVersionAndInformation': 'යෙදුම් අනුවාදය සහ තොරතුරු',
      'readOurPrivacyPolicy': 'අපගේ රහස්‍යතා ප්‍රතිපත්තිය කියවන්න',
      'readOurTermsOfService': 'අපගේ සේවා කොන්දේසි කියවන්න',
      'signedOut': 'ඉවත් විය',

      // Offer Types
      'bank': 'බැංකු',
      'shop': 'වෙළඳසැල',
      'promo': 'ප්‍රවර්ධන',
      'events': 'ඉසව්',

      // Urgency
      'endingToday': 'අද අවසන් වේ',
      'daysLeft': '{days} දින ඉතිරිව ඇත',
    },
    'ta': {
      // Common
      'appName': 'இலங்கை சலுகைகள்',
      'loading': 'ஏற்றுகிறது...',
      'error': 'பிழை',
      'retry': 'மீண்டும் முயற்சிக்கவும்',
      'cancel': 'ரத்துசெய்',
      'save': 'சேமி',
      'share': 'பகிர்',
      'viewDetails': 'விவரங்களைக் காண்க',
      'seeAll': 'அனைத்தையும் பார்க்க',

      // Home
      'featuredOffers': 'சிறப்பு சலுகைகள்',
      'nearbyOffers': 'அருகிலுள்ள சலுகைகள்',
      'trendingCategories': 'பிரபலமான வகைகள்',
      'recentlyViewed': 'சமீபத்தில் பார்த்தவை',
      'allOffers': 'அனைத்து சலுகைகள்',
      'homeBannerTitle': 'வங்கி அட்டை சலுகைகள், ஒரே இடத்தில்',
      'homeBannerBadge': 'நேரடி சலுகைகள்',
      'homeBannerSubtitle': 'உணவு • சூப்பர் மார்க்கெட் • ஹோட்டல் • தவணை',
      'quickFilters': 'விரைவு வடிகட்டிகள்',
      'endingSoon': 'விரைவில் முடிகிறது',
      'nearby': 'அருகில்',
      'myCards': 'எனது அட்டைகள்',
      'verified': 'சரிபார்க்கப்பட்டது',
      'trending': 'பிரபலமான',
      'currentLocation': 'தற்போதைய இடம்',

      // Search
      'searchHint': 'சலுகைகள், கடைகள், நிகழ்வுகளைத் தேடுங்கள்...',
      'recentSearches': 'சமீபத்திய தேடல்கள்',
      'popularSearches': 'பிரபலமான தேடல்கள்',
      'noResults': 'முடிவுகள் இல்லை',

      // Filters
      'filter': 'வடிகட்டி',
      'sort': 'வரிசைப்படுத்து',
      'apply': 'பயன்படுத்து',
      'reset': 'மீட்டமை',

      // Offer Detail
      'validUntil': 'செல்லுபடியாகும் வரை',
      'termsAndConditions': 'விதிமுறைகள் மற்றும் நிபந்தனைகள்',
      'contactInfo': 'தொடர்பு தகவல்',
      'similarOffers': 'இதேபோன்ற சலுகைகள்',
      'locations': 'இடங்கள்',

      // Saved
      'savedOffers': 'சேமிக்கப்பட்ட சலுகைகள்',
      'noSavedOffers': 'இன்னும் சேமிக்கப்பட்ட சலுகைகள் இல்லை',

      // Profile
      'profile': 'சுயவிவரம்',
      'preferences': 'விருப்பங்கள்',
      'settings': 'அமைப்புகள்',
      'about': 'பற்றி',
      'language': 'மொழி',
      'location': 'இடம்',
      'notifications': 'அறிவிப்புகள்',
      'helpSupport': 'உதவி மற்றும் ஆதரவு',
      'account': 'கணக்கு',
      'saved': 'சேமிக்கப்பட்டது',
      'viewed': 'பார்த்தது',
      'shared': 'பகிரப்பட்டது',
      'privacyPolicy': 'தனியுரிமை கொள்கை',
      'termsOfService': 'சேவை விதிமுறைகள்',
      'signOut': 'வெளியேறு',
      'signOutConfirm': 'நீங்கள் வெளியேற விரும்புகிறீர்களா?',
      'ok': 'சரி',
      'openSettings': 'அமைப்புகளைத் திற',
      'locationServicesDisabled':
          'இடம் சேவைகள் முடக்கப்பட்டுள்ளன. உங்கள் சாதன அமைப்புகளில் இடம் சேவைகளை இயக்கவும்.',
      'locationPermissionRequired':
          'உங்கள் தற்போதைய இடத்தைக் காட்ட இட அனுமதி தேவை. தயவுசெய்து அதை பயன்பாட்டு அமைப்புகளில் இயக்கவும்.',
      'offerDetails': 'சலுகை விவரங்கள்',
      'category': 'வகை',
      'tags': 'குறிச்சொற்கள்',
      'phone': 'தொலைபேசி',
      'email': 'மின்னஞ்சல்',
      'website': 'வலைத்தளம்',
      'getDirections': 'திசைகளைப் பெறு',
      'saveOffer': 'சலுகையைச் சேமி',
      'offerSaved': 'சலுகை சேமிக்கப்பட்டது',
      'offerUnsaved': 'சலுகை நீக்கப்பட்டது',
      'noNewNotifications': 'புதிய அறிவிப்புகள் இல்லை',
      'noEventsFound': 'நிகழ்வுகள் கிடைக்கவில்லை',
      'tryAdjustingFilters': 'உங்கள் வடிகட்டிகளை சரிசெய்ய முயற்சிக்கவும்',
      'eventsMap': 'நிகழ்வுகள் வரைபடம்',
      'mapView': 'வரைபடக் காட்சி',
      'aboutApp': 'இலங்கை சலுகைகள் பற்றி',
      'appVersion':
          'பதிப்பு 1.0.0\n\nஇலங்கை முழுவதும் சலுகைகள் மற்றும் நிகழ்வுகளைக் கண்டறிய ஒரு விரிவான பயன்பாடு.',
      'viewYourSavedOffers': 'உங்கள் சேமிக்கப்பட்ட சலுகைகளைப் பார்க்க',
      'yourBrowsingHistory': 'உங்கள் உலாவல் வரலாறு',
      'manageYourBankCards': 'உங்கள் வங்கி அட்டைகளை நிர்வகிக்கவும்',
      'manageNotificationSettings': 'அறிவிப்பு அமைப்புகளை நிர்வகிக்கவும்',
      'getHelpAndContactSupport': 'உதவி பெறவும் ஆதரவைத் தொடர்பு கொள்ளவும்',
      'appVersionAndInformation': 'பயன்பாட்டு பதிப்பு மற்றும் தகவல்',
      'readOurPrivacyPolicy': 'எங்கள் தனியுரிமை கொள்கையைப் படிக்கவும்',
      'readOurTermsOfService': 'எங்கள் சேவை விதிமுறைகளைப் படிக்கவும்',
      'signedOut': 'வெளியேறியது',

      // Offer Types
      'bank': 'வங்கி',
      'shop': 'கடை',
      'promo': 'விளம்பரம்',
      'events': 'நிகழ்வுகள்',

      // Urgency
      'endingToday': 'இன்று முடிகிறது',
      'daysLeft': '{days} நாட்கள் மீதமுள்ளன',
    },
  };

  static const Map<String, Map<String, String>> _phaseOneValues = {
    'en': {
      'homeNav': 'Home',
      'exploreNav': 'Explore',
      'savedNav': 'Saved',
      'settingsNav': 'Settings',
      'findNextOffer': 'Find your next card offer',
      'verifiedBankOffers': 'Verified offers from Sri Lankan banks',
      'searchBankOffers': 'Search banks, merchants or offers',
      'chooseCards': 'Choose Cards',
      'chooseBanksCards': 'Choose your banks and cards',
      'relevantOffers': 'Get more relevant offers based on the cards you use.',
      'noMatchingOffers': 'No matching offers',
      'tryAnotherSearch': 'Try another bank, merchant or category.',
      'noSavedBody': 'Save offers to find them quickly later.',
      'exploreOffers': 'Explore Offers',
      'storedOnDevice': 'Saved offers are stored on this device.',
      'myBanksCards': 'My banks and cards',
      'appSettings': 'App settings',
      'support': 'Support',
      'clearRecent': 'Clear recent searches',
      'clearSaved': 'Clear saved offers',
      'reportOffer': 'Report incorrect offer',
      'sendFeedback': 'Send feedback',
      'aboutLankaOffers': 'About Lanka Offers',
      'preferredCategories': 'Preferred categories',
      'preferredDistricts': 'Preferred districts',
      'nearbyRadius': 'Nearby radius',
      'savePreferences': 'Save preferences',
      'clearAll': 'Clear All',
      'banks': 'Banks',
      'cardTypes': 'Card types',
      'cardNetworks': 'Card networks',
      'creditCard': 'Credit card',
      'debitCard': 'Debit card',
      'preferencesSaved': 'Preferences saved',
      'allBankOffers': 'All bank offers',
      'filters': 'Filters',
      'applyFilters': 'Apply Filters',
      'couldntLoadOffers': "Couldn't load offers",
      'connectionRetry': 'Check your connection and try again.',
      'noOffers': 'No offers available',
      'noOffersBody': 'Check back soon for new bank card offers.',
      'expiringSoon': 'Expiring Soon',
      'expired': 'Expired',
      'specialOffer': 'Special offer',
      'eligibleCards': 'Eligible cards',
      'offerInformation': 'Offer information',
      'lastVerified': 'Last verified',
      'sourceUnavailable': 'Official source is unavailable',
      'locationOff': 'Location is turned off',
      'locationOffBody': 'Enable location to discover offers near you.',
      'enableLocation': 'Enable Location',
      'notNow': 'Not Now',
      'surveyTitle': 'What should Lanka Offers add next?',
      'surveyBody':
          'We are preparing more ways to discover offers and activities near you. Which feature would you use most?',
      'surveyShops': 'Local shop and restaurant offers',
      'surveyEvents': 'Events and activities',
      'surveyBoth': 'Both',
      'surveyEnough': 'Bank offers are enough for me',
      'submit': 'Submit',
      'dontAskAgain': "Don't Ask Again",
    },
    'si': {
      'homeNav': 'මුල් පිටුව',
      'exploreNav': 'ගවේෂණය',
      'savedNav': 'සුරැකි',
      'settingsNav': 'සැකසුම්',
      'findNextOffer': 'ඔබේ මීළඟ කාඩ් දීමනාව සොයන්න',
      'verifiedBankOffers': 'ශ්‍රී ලංකා බැංකුවල තහවුරු කළ දීමනා',
      'searchBankOffers': 'බැංකු, වෙළඳුන් හෝ දීමනා සොයන්න',
      'chooseCards': 'කාඩ් තෝරන්න',
      'chooseBanksCards': 'ඔබේ බැංකු සහ කාඩ් තෝරන්න',
      'relevantOffers': 'ඔබ භාවිත කරන කාඩ් අනුව වඩා අදාළ දීමනා ලබා ගන්න.',
      'noMatchingOffers': 'ගැළපෙන දීමනා නැත',
      'tryAnotherSearch':
          'වෙනත් බැංකුවක්, වෙළෙන්දෙක් හෝ කාණ්ඩයක් උත්සාහ කරන්න.',
      'noSavedBody': 'පසුව ඉක්මනින් සොයා ගැනීමට දීමනා සුරකින්න.',
      'exploreOffers': 'දීමනා ගවේෂණය කරන්න',
      'storedOnDevice': 'සුරැකි දීමනා මෙම උපාංගයේ තබා ඇත.',
      'myBanksCards': 'මගේ බැංකු සහ කාඩ්',
      'appSettings': 'යෙදුම් සැකසුම්',
      'support': 'සහාය',
      'clearRecent': 'මෑත සෙවීම් මකන්න',
      'clearSaved': 'සුරැකි දීමනා මකන්න',
      'reportOffer': 'වැරදි දීමනාවක් වාර්තා කරන්න',
      'sendFeedback': 'ප්‍රතිචාර යවන්න',
      'aboutLankaOffers': 'Lanka Offers ගැන',
      'savePreferences': 'අභිමත සුරකින්න',
      'clearAll': 'සියල්ල මකන්න',
      'banks': 'බැංකු',
      'cardTypes': 'කාඩ් වර්ග',
      'cardNetworks': 'කාඩ් ජාල',
      'creditCard': 'ක්‍රෙඩිට් කාඩ්',
      'debitCard': 'ඩෙබිට් කාඩ්',
      'preferencesSaved': 'අභිමත සුරකින ලදී',
    },
    'ta': {
      'homeNav': 'முகப்பு',
      'exploreNav': 'ஆராய்க',
      'savedNav': 'சேமித்தவை',
      'settingsNav': 'அமைப்புகள்',
      'findNextOffer': 'உங்கள் அடுத்த அட்டைச் சலுகையைக் கண்டறியுங்கள்',
      'verifiedBankOffers': 'இலங்கை வங்கிகளின் சரிபார்க்கப்பட்ட சலுகைகள்',
      'searchBankOffers': 'வங்கிகள், வணிகர்கள் அல்லது சலுகைகளைத் தேடுங்கள்',
      'chooseCards': 'அட்டைகளைத் தேர்வுசெய்',
      'chooseBanksCards': 'உங்கள் வங்கிகளையும் அட்டைகளையும் தேர்வுசெய்க',
      'relevantOffers':
          'நீங்கள் பயன்படுத்தும் அட்டைகளின் அடிப்படையில் பொருத்தமான சலுகைகளைப் பெறுங்கள்.',
      'noMatchingOffers': 'பொருந்தும் சலுகைகள் இல்லை',
      'tryAnotherSearch': 'வேறு வங்கி, வணிகர் அல்லது வகையை முயற்சிக்கவும்.',
      'noSavedBody': 'பின்னர் விரைவாகக் கண்டுபிடிக்க சலுகைகளைச் சேமிக்கவும்.',
      'exploreOffers': 'சலுகைகளை ஆராய்க',
      'storedOnDevice': 'சேமித்த சலுகைகள் இந்தச் சாதனத்தில் உள்ளன.',
      'myBanksCards': 'என் வங்கிகளும் அட்டைகளும்',
      'appSettings': 'செயலி அமைப்புகள்',
      'support': 'ஆதரவு',
      'clearRecent': 'சமீபத்திய தேடல்களை அழி',
      'clearSaved': 'சேமித்த சலுகைகளை அழி',
      'reportOffer': 'தவறான சலுகையைப் புகாரளி',
      'sendFeedback': 'கருத்தை அனுப்பு',
      'aboutLankaOffers': 'Lanka Offers பற்றி',
      'savePreferences': 'விருப்பங்களைச் சேமி',
      'clearAll': 'அனைத்தையும் அழி',
      'banks': 'வங்கிகள்',
      'cardTypes': 'அட்டை வகைகள்',
      'cardNetworks': 'அட்டை வலையமைப்புகள்',
      'creditCard': 'கடன் அட்டை',
      'debitCard': 'பற்று அட்டை',
      'preferencesSaved': 'விருப்பங்கள் சேமிக்கப்பட்டன',
    },
  };

  /// [text] with `{name}` placeholders replaced from [params].
  String format(String key, Map<String, Object> params) {
    var value = text(key);
    params.forEach((name, v) => value = value.replaceAll('{$name}', '$v'));
    return value;
  }

  String text(String key) =>
      redesignStrings[locale.languageCode]?[key] ??
      redesignStrings['en']?[key] ??
      _phaseOneValues[locale.languageCode]?[key] ??
      _phaseOneValues['en']?[key] ??
      _getLocalizedValue(key);

  String get appName => _localizedValues[locale.languageCode]!['appName']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get retry => _localizedValues[locale.languageCode]!['retry']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get share => _localizedValues[locale.languageCode]!['share']!;
  String get viewDetails =>
      _localizedValues[locale.languageCode]!['viewDetails']!;
  String get seeAll => _localizedValues[locale.languageCode]!['seeAll']!;
  String get featuredOffers =>
      _localizedValues[locale.languageCode]!['featuredOffers']!;
  String get nearbyOffers =>
      _localizedValues[locale.languageCode]!['nearbyOffers']!;
  String get trendingCategories =>
      _localizedValues[locale.languageCode]!['trendingCategories']!;
  String get recentlyViewed =>
      _localizedValues[locale.languageCode]!['recentlyViewed']!;
  String get allOffers => _localizedValues[locale.languageCode]!['allOffers']!;
  String get quickFilters =>
      _localizedValues[locale.languageCode]!['quickFilters']!;
  String get endingSoon =>
      _localizedValues[locale.languageCode]!['endingSoon']!;
  String get nearby => _localizedValues[locale.languageCode]!['nearby']!;
  String get myCards => _localizedValues[locale.languageCode]!['myCards']!;
  String get verified => _localizedValues[locale.languageCode]!['verified']!;
  String get trending => _localizedValues[locale.languageCode]!['trending']!;
  String get currentLocation =>
      _localizedValues[locale.languageCode]!['currentLocation']!;
  String get searchHint =>
      _localizedValues[locale.languageCode]!['searchHint']!;
  String get recentSearches =>
      _localizedValues[locale.languageCode]!['recentSearches']!;
  String get popularSearches =>
      _localizedValues[locale.languageCode]!['popularSearches']!;
  String get noResults => _localizedValues[locale.languageCode]!['noResults']!;
  String get filter => _localizedValues[locale.languageCode]!['filter']!;
  String get sort => _localizedValues[locale.languageCode]!['sort']!;
  String get apply => _localizedValues[locale.languageCode]!['apply']!;
  String get reset => _localizedValues[locale.languageCode]!['reset']!;
  String get validUntil =>
      _localizedValues[locale.languageCode]!['validUntil']!;
  String get termsAndConditions =>
      _localizedValues[locale.languageCode]!['termsAndConditions']!;
  String get contactInfo =>
      _localizedValues[locale.languageCode]!['contactInfo']!;
  String get similarOffers =>
      _localizedValues[locale.languageCode]!['similarOffers']!;
  String get locations => _localizedValues[locale.languageCode]!['locations']!;
  String get savedOffers =>
      _localizedValues[locale.languageCode]!['savedOffers']!;
  String get noSavedOffers =>
      _localizedValues[locale.languageCode]!['noSavedOffers']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get preferences =>
      _localizedValues[locale.languageCode]!['preferences']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get about => _localizedValues[locale.languageCode]!['about']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get notifications =>
      _localizedValues[locale.languageCode]!['notifications']!;
  String get helpSupport =>
      _localizedValues[locale.languageCode]!['helpSupport']!;
  String get bank => _localizedValues[locale.languageCode]!['bank']!;
  String get shop => _localizedValues[locale.languageCode]!['shop']!;
  String get promo => _localizedValues[locale.languageCode]!['promo']!;
  String get events => _localizedValues[locale.languageCode]!['events']!;
  String get endingToday =>
      _localizedValues[locale.languageCode]!['endingToday']!;
  String get location => _getLocalizedValue('location');
  String get account => _getLocalizedValue('account');
  String get saved => _getLocalizedValue('saved');
  String get viewed => _getLocalizedValue('viewed');
  String get shared => _getLocalizedValue('shared');
  String get privacyPolicy => _getLocalizedValue('privacyPolicy');
  String get termsOfService => _getLocalizedValue('termsOfService');
  String get signOut => _getLocalizedValue('signOut');
  String get signOutConfirm => _getLocalizedValue('signOutConfirm');
  String get ok => _getLocalizedValue('ok');
  String get openSettings => _getLocalizedValue('openSettings');
  String get locationServicesDisabled =>
      _getLocalizedValue('locationServicesDisabled');
  String get locationPermissionRequired =>
      _getLocalizedValue('locationPermissionRequired');
  String get offerDetails => _getLocalizedValue('offerDetails');
  String get category => _getLocalizedValue('category');
  String get tags => _getLocalizedValue('tags');
  String get phone => _getLocalizedValue('phone');
  String get email => _getLocalizedValue('email');
  String get website => _getLocalizedValue('website');
  String get getDirections => _getLocalizedValue('getDirections');
  String get saveOffer => _getLocalizedValue('saveOffer');
  String get offerSaved => _getLocalizedValue('offerSaved');
  String get offerUnsaved => _getLocalizedValue('offerUnsaved');
  String get noNewNotifications => _getLocalizedValue('noNewNotifications');
  String get noEventsFound => _getLocalizedValue('noEventsFound');
  String get tryAdjustingFilters => _getLocalizedValue('tryAdjustingFilters');
  String get eventsMap => _getLocalizedValue('eventsMap');
  String get mapView => _getLocalizedValue('mapView');
  String get aboutApp => _getLocalizedValue('aboutApp');
  String get appVersion => _getLocalizedValue('appVersion');
  String get viewYourSavedOffers => _getLocalizedValue('viewYourSavedOffers');
  String get yourBrowsingHistory => _getLocalizedValue('yourBrowsingHistory');
  String get manageYourBankCards => _getLocalizedValue('manageYourBankCards');
  String get manageNotificationSettings =>
      _getLocalizedValue('manageNotificationSettings');
  String get getHelpAndContactSupport =>
      _getLocalizedValue('getHelpAndContactSupport');
  String get appVersionAndInformation =>
      _getLocalizedValue('appVersionAndInformation');
  String get readOurPrivacyPolicy => _getLocalizedValue('readOurPrivacyPolicy');
  String get readOurTermsOfService =>
      _getLocalizedValue('readOurTermsOfService');
  String get signedOut => _getLocalizedValue('signedOut');

  String daysLeft(int days) {
    final template = _getLocalizedValue('daysLeft');
    return template.replaceAll('{days}', days.toString());
  }

  String _getLocalizedValue(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key; // Fallback to key name if not found
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'si', 'ta'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
