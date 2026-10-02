# Mobile App Architecture — Lanka Offers

## 1. Overview
`lanka-offers-mobile` is a Flutter (v3.44+ / Dart 3.12+) consumer application built following Clean Architecture principles:
- **Presentation Layer**: Flutter widgets, BLoC state management (`flutter_bloc`), dynamic theme, and GoRouter navigation.
- **Domain Layer**: Pure Dart entities, value objects, and business services (card eligibility matching, location bounding, saved offer domain logic). Zero dependencies on Flutter UI or remote APIs.
- **Data Layer**: Repositories implementing domain contracts, remote API datasources (`ApiOffersDatasource`), local storage (`SharedPreferences`), and data transfer objects with robust JSON serialization.
- **Core Layer**: Shared utilities, design tokens, error definitions, and app constants.

---

## 2. Dependency Inversion Boundary

```
[ Presentation (BLoC / UI) ]
            │
            ▼
   [ Domain Entities / Repositories (Interfaces) ]
            ▲
            │
      [ Data Repositories (Implementations) ]
            │
            ▼
  [ Remote API / Local SharedPreferences ]
```

---

## 3. Remote API Contract Consumption
The mobile app communicates exclusively with the public read-only API:
- Base URL configured via compile-time `--dart-define=API_BASE_URL=...`
- Endpoints consumed:
  - `GET /api/offers` (Filtered, paginated consumer offers)
  - `GET /api/offers/:id` (Full offer details including merchant locations)
  - `GET /api/merchants` (Active merchant catalog)
  - `GET /api/banks` (Supported Sri Lankan banks metadata)
  - `GET /api/health` (API health check)

---

## 4. Key Subsystems
- **Card Matching Engine**: `lib/domain/services/card_matching_service.dart` evaluates user-selected payment cards against bank offer eligibility restrictions (`card_eligibility`).
- **Location & Maps**: Flutter Map using OpenStreetMap tiles (`flutter_map` / `latlong2`). Honors the 7 explicit `location_scope` types from the backend with zero invented coordinates.
- **Continuous Detail Paging**: Horizontal `PageView` browsing of offers with cached index tracking and seamless state synchronization.
