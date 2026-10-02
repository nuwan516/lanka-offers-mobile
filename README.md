# Lanka Offers — Flutter Consumer Mobile Application

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.12+-teal.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

Clean Architecture consumer mobile application for exploring, filtering, and discovering Sri Lankan credit and debit card offers.

---

## 1. What This Repository Owns
- Complete consumer Flutter application for Android and iOS.
- BLoC-driven state management for home, explore, saved offers, search, preferences, and details.
- User payment card management and client-side card eligibility matching engine.
- OpenStreetMap and GPS nearby offer discovery honoring backend location scopes.
- Continuous horizontal detail paging browsing experience.

## 2. What This Repository Explicitly Does NOT Own
- **Database / Backend**: No direct database access or Neon credentials.
- **Scraping**: No scrapers or web extractors.
- **Admin Workflow**: No admin controls, publishing, or manual review interfaces.

---

## 3. Architecture

Built strictly with Flutter **Clean Architecture**:
```
lib/
├── core/                     # Dependency injection, theme tokens, constants, utilities
├── data/
│   ├── datasources/remote/   # Remote public REST API client (ApiOffersDatasource)
│   ├── models/               # DTOs and JSON serializers
│   └── repositories/         # OfferRepositoryImpl with in-memory caching
├── domain/
│   ├── entities/             # BankOffer, CardEligibility, UserCard, etc.
│   ├── repositories/         # OfferRepository abstract interface
│   └── services/             # CardMatchingService
└── presentation/
    ├── common/               # Shared widgets (OfferCard, LKAppBar, LKScaffold)
    ├── routes/               # GoRouter configuration & deep linking
    └── screens/              # Home, Explore, Search, Detail, Preferences, Saved
```

---

## 4. Configuration & Environments

The application receives its API configuration at compile time via `--dart-define`.

```bash
# Production
flutter run --dart-define=API_BASE_URL=https://api.lanka-offers.me

# Local Backend API
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001
```

---

## 5. Development & Testing Commands

| Command | Description |
|---|---|
| `flutter analyze` | Run Dart static analysis (ensures 0 errors) |
| `flutter test` | Run all unit, widget, and domain test suites |
| `flutter run` | Launch app on connected physical device or emulator |
| `flutter build apk --debug` | Build debug APK for manual Android testing |
| `flutter build appbundle --release` | Build release Android App Bundle |

---

## 6. Testing Strategy
- `test/phase6_consumer_test.dart`: Verifies remote API deserialization, query parameters, and error mapping.
- `test/phase7_card_eligibility_test.dart`: Verifies payment card matching against Visa, Mastercard, Amex, credit/debit criteria.
- `test/phase8_detail_paging_test.dart`: Verifies continuous horizontal browsing and index synchronization.
