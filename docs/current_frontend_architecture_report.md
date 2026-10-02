# Lanka Offers — Current Frontend Architecture Report

**Generated**: 2026-07-17
**Repository root**: `D:\lanka-space\lanka_offers`

---

## 1. Repository Structure

The project is a standard Flutter application with no `lib/config` directory. Key directories:

```
lib/
  app.dart                          # MaterialApp.router root widget
  main.dart                         # Entry point
  core/
    constants/                      # App-wide constants, storage keys, strings
    di/                             # GetIt dependency injection setup
    enums/                          # OfferType, EventType, ShopType, CoverageType, OfferStatus
    extensions/                     # Context, Date, String extensions
    localization/                   # AppLocalizations (inline map-based, no ARB files)
    services/                       # LanguageService, LocationService
    theme/                          # Colors, dimensions, text styles, theme
    utils/                          # CurrencyFormatter, DateFormatter, DistanceCalculator, Validators
  data/
    datasources/
      local/preferences_datasource.dart   # SharedPreferences wrapper
      mock/mock_offers_data.dart          # 2000-line static data with 34 records
    repositories/
      offer_repository_impl.dart          # Delegates to MockOffersData
      user_repository_impl.dart           # SharedPreferences-backed persistence
  domain/
    entities/                      # 20 entity files
    repositories/                  # 2 abstract interfaces
    usecases/                      # 9 use case classes
  presentation/
    common/widgets/                # error_view, event_card, language_selector,
                                   # loading_shimmer, map_view, offer_card
    routes/app_router.dart         # GoRouter config
    screens/
      events/   (bloc/, widgets/, events_screen.dart)
      explore/  (bloc/, widgets/, explore_screen.dart)
      home/     (bloc/, home_screen.dart)
      main_navigation/
      offer_detail/
      onboarding/
      profile/
      saved/    (bloc/, saved_offers_screen.dart)
      search/   (bloc/, search_screen.dart)
      splash/
test/
  widget_test.dart                # Default Flutter counter test, not project-specific
```

**Platform folders**: `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` contain framework-generated files and launcher icons. No custom platform configuration beyond standard Flutter defaults was found.

**Notable absence**: No `lib/config/` directory exists.

---

## 2. Architecture Validation

### Claimed: Clean Architecture

The project loosely follows Clean Architecture layers but has several violations.

### Layer responsibilities

| Layer | Owns | Depends on |
|---|---|---|
| **Domain** (innermost) | Entities, repository interfaces, use cases | Nothing outside Dart SDK |
| **Data** (outer) | Repository implementations, data sources | Domain layer, `shared_preferences`, `geolocator` |
| **Presentation** (outermost) | Screens, BLoCs, widgets, router | Domain layer, `flutter_bloc`, `go_router` |
| **Core** | Theme, DI, services, utils, localization | Various Flutter/third-party packages |

### Dependency direction

```
Presentation → Domain ← Data
       ↓            ↓
      Core ←··· Domain ···→ Core (enums imported by domain)
```

### Violations identified

1. **Domain entities import core enums** — `bank_offer.dart`, `shop_offer.dart`, `event.dart` import from `core/enums/`. This creates a dependency from domain→core (should be the reverse). Specifically:
   - `lib/domain/entities/bank_offer.dart` — no enum imports directly
   - `lib/domain/entities/shop_offer.dart:4` — imports `../../core/enums/shop_type.dart`
   - `lib/domain/entities/event.dart:6` — imports `../../core/enums/event_type.dart`
   - `lib/domain/usecases/filter_offers.dart:2` — imports `../../core/enums/offer_type.dart`
   - `lib/data/repositories/offer_repository.dart:1` — imports `../../core/enums/offer_type.dart`

2. **Repository interfaces import core** — `lib/domain/repositories/offer_repository.dart:1` imports `../../core/enums/offer_type.dart`. This is a domain layer file importing from core.

3. **Domain dependencies reference core** — `lib/domain/entities/base_offer.dart:7` imports `../../core/extensions/date_extensions.dart`.

4. **No DTO layer** — Data sources return domain entities directly. The mock data file directly instantiates `BankOffer`, `ShopOffer`, etc. There is no separation between API models and domain models.

5. **No remote data source interface** — `OfferRepositoryImpl` instantiates `MockOffersData` directly. There is no abstraction between the repository and its data source.

6. **BLoCs use `List<dynamic>` throughout** — Repository interfaces return `Future<List<dynamic>>`, losing type safety. Every BLoC must cast or duck-type entities.

7. **Presentation layer depends on `List<dynamic>`** — `HomeLoaded`, `SearchResultsLoaded`, `ExploreLoaded`, `SavedLoaded`, and `OfferDetailScreen` all receive `List<dynamic>` and rely on Duck typing (e.g., `offer.quality.confidenceScore`, `offer.uniqueId`).

8. **Core layer has mixed concerns** — `LocationService` (GPS), `LanguageService` (preferences), and `Theme` all live under `core/`, blurring the line between "core utilities" and "services."

9. **Mock data in production** — Mock data is in `lib/data/datasources/mock/` and imported directly by `offer_repository_impl.dart`. There is no environment-based switching mechanism.

### Summary

The architecture is **"Clean Architecture inspired"** with a domain layer that is mostly framework-free, but the separation between layers is incomplete. The main issues are:
- No DTO/API model layer
- `List<dynamic>` return types erasing type safety
- Domain layer has outward dependencies on core
- No dependency injection for data sources
- Mock data is hardwired in production code

---

## 3. Domain Model Analysis

### 3.1 BaseOffer (abstract)

**File**: `lib/domain/entities/base_offer.dart`

| Field | Type | Required | Notes |
|---|---|---|---|
| `uniqueId` | `String` | Yes | Primary identifier |
| `title` | `String` | Yes | Display title |
| `description` | `String` | Yes | Full description |
| `category` | `String` | Yes | Free-text category name |
| `subcategories` | `List<String>` | Yes | Tag-like subcategories |
| `locations` | `List<Location>` | Yes | At least one location |
| `validity` | `ValidityPeriod` | Yes | Date range |
| `contact` | `ContactInfo?` | No | Optional contact details |
| `images` | `List<String>` | Yes | Image URLs |
| `featuredImage` | `String?` | No | Primary image URL |
| `quality` | `QualityScore` | Yes | Confidence/grade |
| `metrics` | `EngagementMetrics?` | No | Views, saves, clicks |

**Equality**: Extends `Equatable` with all fields in `props`.

**Serialization**: None. No `toJson()`/`fromJson()` on any entity.

**Validation**: None. No validation logic in any entity.

**Provider name**: Abstract getter `String get providerName;` implemented by subclasses.

**Difficulties for backend mapping**:
- `category` is free-text, not an enum or ID reference
- `locations` is embedded composition, not ID references
- `images` is `List<String>` (URLs), no distinction between uploaded and linked images

### 3.2 BankOffer

**File**: `lib/domain/entities/bank_offer.dart`
**Extends**: `BaseOffer`
**Provider name**: Returns `bankName`

| Field | Type | Required | Notes |
|---|---|---|---|
| `bankName` | `String` | Yes | Bank name |
| `merchantName` | `String` | Yes | Merchant name |
| `discount` | `Discount?` | No | Can be null if installment-based |
| `installmentPlans` | `List<InstallmentPlan>?` | No | Can be null if discount-based |
| `applicableCards` | `List<String>` | Yes | String like 'VISA','MASTERCARD','CREDIT','DEBIT' |
| `restrictions` | `Restrictions?` | No | Terms and conditions |
| `minTransaction` | `double?` | No | Minimum spend |

**Difficulties for backend mapping**:
- `discount` and `installmentPlans` are mutually exclusive in usage but not enforced in code
- `applicableCards` uses string literals, no enum or ID reference
- No LKR currency wrapper; `minTransaction` is raw `double`

### 3.3 ShopOffer

**File**: `lib/domain/entities/shop_offer.dart`
**Extends**: `BaseOffer`
**Provider name**: Returns `shopName`

| Field | Type | Required | Notes |
|---|---|---|---|
| `shopName` | `String` | Yes | Shop/business name |
| `shopType` | `ShopType` | Yes | Enum: restaurant, retail, service, etc. |
| `discount` | `Discount` | Yes | Always present (not nullable) |
| `promoCode` | `String?` | No | Optional promo code |
| `minPurchaseAmount` | `double?` | No | Minimum spend |
| `hoursOfOperation` | `String?` | No | Free-text hours |
| `verified` | `bool` | Yes | Verification flag |
| `verificationDate` | `DateTime?` | No | When verified |
| `restrictions` | `Restrictions?` | No | Terms |

### 3.4 Promotion

**File**: `lib/domain/entities/promotion.dart`
**Extends**: `BaseOffer`

| Field | Type | Required | Notes |
|---|---|---|---|
| `providerName` | `String` | Yes | Overrides BaseOffer abstract getter |
| `promotionType` | `String` | Yes | Free-text: 'flash_sale', 'limited_time', 'seasonal' |
| `urgencyLevel` | `String` | Yes | Free-text: 'urgent', 'high', 'normal' |
| `deal` | `Deal` | Yes | Price/original/sale info |
| `stockStatus` | `String?` | No | Free-text: 'limited', 'available', 'sold_out' |
| `unitsAvailable` | `int?` | No | Inventory count |
| `unitsSold` | `int?` | No | Sold count |
| `flashDurationHours` | `int?` | No | For flash sales |
| `countdownEnabled` | `bool` | Yes | Show countdown timer |

**Difficulties for backend mapping**:
- `promotionType` and `urgencyLevel` are free-text strings, not enums
- `deal.type` is also free-text

### 3.5 Event

**File**: `lib/domain/entities/event.dart`
**Extends**: `BaseOffer`
**Provider name**: Returns `providerName`

| Field | Type | Required | Notes |
|---|---|---|---|
| `providerName` | `String` | Yes | Event organizer/provider |
| `eventType` | `EventType` | Yes | Enum from core/enums |
| `organizer` | `String` | Yes | Organizer name |
| `venue` | `Venue` | Yes | Location details |
| `eventDateTime` | `EventDateTime` | Yes | Start/end/door open |
| `ticketing` | `Ticketing?` | No | Ticket info |
| `amenities` | `Amenities` | Yes | Boolean flags |
| `ageRestriction` | `String` | Yes | Free-text: 'all_ages', '18+', '21+' |
| `familyFriendly` | `bool` | Yes | Family-friendly flag |

### 3.6 Supporting Entities

| Entity | File | Key Fields | Notes |
|---|---|---|---|
| `Location` | `domain/entities/location.dart` | `name`, `address`, `district`, `city`, `latitude`, `longitude` | No `toJson()`, no ID field |
| `ValidityPeriod` | `domain/entities/validity_period.dart` | `validFrom`, `validUntil`, `daysApplicable?`, `timeRestrictions?` | Uses raw `DateTime` |
| `Discount` | `domain/entities/discount.dart` | `type` (String), `value` (dynamic!), `description` | `value` is `dynamic` — can be double or String |
| `Restrictions` | `domain/entities/restrictions.dart` | `keyRestrictions`, `bookingRequired?`, `minTransaction?`, `maxTransaction?` | `keyRestrictions` is free-text |
| `QualityScore` | `domain/entities/quality_score.dart` | `confidenceScore` (0-1), `grade` (String) | No validation on grade values |
| `EngagementMetrics` | `domain/entities/engagement_metrics.dart` | `views`, `saves`, `clicks`, `popularityScore` | Purely mock/analytics data |
| `Deal` | `domain/entities/deal.dart` | `type` (String), `value` (double), `description`, `originalPrice?`, `salePrice?` | For promotions |
| `InstallmentPlan` | `domain/entities/installment_plan.dart` | `interestRate`, `months`, `description` | Simple |
| `Venue` | `domain/entities/venue.dart` | `name`, `address`, `capacity?`, `indoor` | For events |
| `EventDateTime` | `domain/entities/event_date_time.dart` | `start`, `end`, `doorsOpen?` | Uses raw `DateTime` |
| `Ticketing` | `domain/entities/ticketing.dart` | `required`, `priceRange?`, `earlyBirdAvailable?`, `earlyBirdDeadline?`, `ticketsAvailable?`, `ticketsSold?`, `bookingUrl?` | Rich ticketing model |
| `PriceRange` | `domain/entities/price_range.dart` | `min`, `max` | Raw doubles |
| `Amenities` | `domain/entities/amenities.dart` | `parkingAvailable`, `wheelchairAccessible`, `foodAvailable`, `wifiAvailable` | Boolean flags |
| `ContactInfo` | `domain/entities/contact_info.dart` | `phone?`, `email?`, `website?` | Lists of strings |
| `UserPreferences` | `domain/entities/user_preferences.dart` | `preferredCategories`, `preferredDistricts`, `preferredRadiusKm?`, `savedCards`, `notificationsEnabled` | Declared but barely used |

### Key issues across all entities

1. **No serialization** — Zero `toJson()`/`fromJson()` methods. Every entity must be mapped manually when introducing a backend.
2. **No validation** — No constructor assertions, no field validation.
3. **No currency type** — All monetary values are raw `double`. No LKR wrapper.
4. **Free-text string fields** — `category`, `promotionType`, `urgencyLevel`, `stockStatus`, `ageRestriction`, `daysApplicable`, `timeRestrictions` are all unconstrained strings.
5. **`dynamic` in Discount.value** — The `value` field is `dynamic` (accepts `double` or `String`), defeating type safety.
6. **No ID for Location** — `Location` has no standalone ID, making it difficult to reference from a backend.
7. **No GeoJSON/structured coordinate type** — `latitude`/`longitude` are raw doubles.

---

## 4. Repository and Use-Case Flow

### 4.1 Load the home page offers

```
HomeScreen (lib/presentation/screens/home/home_screen.dart)
→ LoadHomeData event
→ HomeBloc._onLoadHomeData (lib/presentation/screens/home/bloc/home_bloc.dart)
→ GetAllOffers.call() (lib/domain/usecases/get_all_offers.dart)
  → OfferRepository.getAllOffers() (lib/domain/repositories/offer_repository.dart)
  → OfferRepositoryImpl.getAllOffers() (lib/data/repositories/offer_repository_impl.dart)
    → MockOffersData.getAllOffers() (lib/data/datasources/mock/mock_offers_data.dart)
→ GetNearbyOffers.call(latitude, longitude, radius)
  → OfferRepository.getNearbyOffers() → OfferRepositoryImpl.getNearbyOffers()
    → MockOffersData.getNearbyOffers()
→ Returns: List<dynamic> (BankOffer | ShopOffer | Promotion | Event)
→ HomeBloc extracts featured (confidence >= 0.85, popularity >= 75), categories, nearby
→ HomeLoaded state emitted
→ HomeScreen rebuilds with featuredOffers, nearbyOffers, categories
```

### 4.2 Search offers

```
SearchScreen (lib/presentation/screens/search/search_screen.dart)
→ SearchQueryChanged(query) [debounced 500ms]
→ SearchBloc._onSearchQueryChanged → timer → PerformSearch(query)
→ SearchBloc._onPerformSearch
→ userRepository.addRecentSearch(query)
→ SearchOffers.call(query) (lib/domain/usecases/search_offers.dart)
  → OfferRepository.searchOffers(query)
  → OfferRepositoryImpl.searchOffers(query)
    → MockOffersData.searchOffers(query) — matches title, description, category, providerName
→ Returns: List<dynamic>
→ SearchResultsLoaded state
→ UI displays results
```

### 4.3 Filter offers

```
ExploreScreen (lib/presentation/screens/explore/explore_screen.dart)
→ LoadExploreOffers(filterType, category, district) or FilterOffers(type, category, district)
→ ExploreBloc._onLoadExploreOffers or _onFilterOffers
→ FilterOffers.call(type, category, district, latitude, longitude) (domain/usecases/filter_offers.dart)
  → OfferRepository.filterOffers(type, category, district, maxDistance, latitude, longitude)
  → OfferRepositoryImpl.filterOffers()
    → Starts with MockOffersData.getAllOffers()
    → Filters by type using `is BankOffer` checks
    → Filters by category string match
    → Filters by district string match
    → Optionally calls MockOffersData.getNearbyOffers()
→ Returns: List<dynamic>
→ ExploreLoaded state with offers, selected filters
```

### 4.4 Load nearby offers

```
HomeScreen
→ LoadHomeData event
→ HomeBloc._onLoadHomeData
→ GetNearbyOffers.call(latitude, longitude, radius)
  → OfferRepository.getNearbyOffers(latitude, longitude, radius)
  → OfferRepositoryImpl.getNearbyOffers(latitude, longitude, radius)
    → MockOffersData.getNearbyOffers(latitude, longitude, radiusKm)
      → Haversine distance calculation via DistanceCalculator
      → Filter by distance <= radius
→ Returns: List<dynamic>
→ HomeLoaded.nearbyOffers
```

### 4.5 Save an offer

```
OfferDetailScreen / OfferCard
→ SaveOffer event (or toggle)
→ ToggleOfferFavorite.call(offerId) (domain/usecases/toggle_offer_favorite.dart)
  → UserRepository.isOfferSaved(offerId)
  → UserRepositoryImpl.isOfferSaved → SharedPreferences string list check
  → If saved: UserRepositoryImpl.unsaveOffer (remove from list)
  → If not: UserRepositoryImpl.saveOffer (add to list)
→ Returns: bool (true = now saved, false = now unsaved)
→ UI updates favorite icon
```

### 4.6 Remove a saved offer

```
SavedScreen (lib/presentation/screens/saved/saved_offers_screen.dart)
→ UnsaveOffer(offerId) event
→ SavedBloc._onUnsaveOffer
→ userRepository.unsaveOffer(offerId)
  → UserRepositoryImpl.unsaveOffer
    → SharedPreferences.getStringList → remove → setStringList
→ SavedLoaded state with updated offers list
```

### 4.7 Toggle favorite

```
OfferCard
→ ToggleOfferFavorite.call(offerId)
  → UserRepository.isOfferSaved
  → save or unsave accordingly
→ Returns boolean
→ UI toggles heart/favorite icon
```

### 4.8 Open an offer detail page

```
Route: /offer/:id
→ GoRouter → OfferDetailScreen(offerId: id) (lib/presentation/screens/offer_detail/offer_detail_screen.dart)
→ Screen calls getOfferById(id) via use case or directly
  → OfferRepository.getOfferById(id)
  → OfferRepositoryImpl.getOfferById(id)
    → MockOffersData.getOfferById(id) — linear search
→ Returns: dynamic (BankOffer | ShopOffer | Promotion | Event)
→ UI renders full offer detail
→ Also loads similar offers via OfferRepository.getSimilarOffers
```

### 4.9 Browse events

```
EventsScreen (lib/presentation/screens/events/events_screen.dart)
→ LoadEvents event
→ EventsBloc._onLoadEvents
→ offerRepository.getOffersByType(OfferType.event)
  → OfferRepositoryImpl.getOffersByType
    → MockOffersData.getEvents()
→ Returns: List<dynamic>, cast to List<Event>
→ EventsLoaded state
→ UI renders event cards, map, filters, sorting
```

---

## 5. Mock Data Assessment

**File**: `lib/data/datasources/mock/mock_offers_data.dart` (~2032 lines)

### Counts

| Type | Count |
|---|---|
| `BankOffer` | 14 |
| `ShopOffer` | 8 |
| `Promotion` | 5 |
| `Event` | 7 |
| **Total** | **34** |

### Count by bank (BankOffer)
| Bank | Count |
|---|---|
| HNB | 3 (`hnb_hilton_001`, `hnb_jetwing_007`, `hnb_ceyair_011`) |
| BOC | 3 (`boc_abans_002`, `boc_odel_008`, `boc_cargills_012`) |
| Commercial Bank | 3 (`commercial_keells_003`, `commercial_ceyair_009`, `commercial_ceyair_013`) |
| Sampath Bank | 3 (`sampath_ceylon_004`, `sampath_ceyhealth_010`, `sampath_keells_014`) |
| NDB | 1 (`ndb_singer_005`) |
| DFCC | 1 (`dfcc_ceylinco_006`) |

### Count by category (all offers)
| Category | Count |
|---|---|
| Shopping | 6 |
| Dining | 5 |
| Entertainment | 3 |
| Travel | 3 |
| Services | 2 |
| Fashion | 2 |
| Food & Beverage | 2 |
| Electronics | 2 |
| Healthcare | 1 |
| Wellness | 1 |
| Home & Living | 1 |
| Technology | 1 |
| Sports | 1 |

### Uniqueness of IDs
**All 34 IDs are unique**. Pattern: `{type}_{provider}_{number}` (e.g., `hnb_hilton_001`).

### Date validity
Dates are generated dynamically at runtime via `DateTime.now()`:
- **validFrom**: All start before or on the current date (past or present)
- **validUntil**: All end in the future (current + days)
- All 34 offers are **currently valid** as of the report date
- The `promo_flash_phones_001` promotion has an 18-hour window from now minus 18 hours to now plus 6 hours, which could expire quickly

### Location consistency
- **29 of 34 offers** have locations in Colombo district (including sub-districts Colombo, Gampaha)
- **2 offers** have locations in Kandy (`commercial_keells_003`, `shop_pizza_hut_001`)
- **1 offer** has a location in Galle (`hnb_jetwing_007`)
- **2 offers** have duplicate addresses used across different offers (`Keells Super - Liberty Plaza` at `6.9147, 79.8500` appears in multiple offers)
- Some location names are generic ("Galle Road, Colombo 03") but coordinates are reasonably accurate

### Coordinate realism
Coordinates are realistic for Sri Lanka:
- Colombo area: lat ~6.8-6.95, lng ~79.84-79.90
- Kandy: lat ~7.29, lng ~80.63
- Galle: lat ~6.03, lng ~80.22
- All coordinates correspond to real-world locations (within ~100m accuracy)

### Bank/card eligibility
- `applicableCards` uses strings: `'VISA'`, `'MASTERCARD'`, `'CREDIT'`, `'DEBIT'`
- No standardization — `'CREDIT'` appears most frequently (10 offers), `'VISA'` appears in 1 offer
- `'MASTERCARD'` appears in 1 offer
- Some offers restrict to specific bank cards ("Valid for BOC cards only") but this is in free-text `restrictions.keyRestrictions`, not in a structured field

### Data duplication
- **Category string duplication**: "Dining" appears with both restaurant and shop offers
- **Location duplication**: `Keells Super - Liberty Plaza` coordinates `6.9147, 79.8500` are identical across `commercial_keells_003` and `sampath_keells_014`
- **Contact duplication**: Phone number `+94112345678` is a placeholder used in 10+ offers
- **Image duplication**: The same Unsplash URLs are reused across unrelated offers

### Image URLs
All 34 offers use **remote Unsplash URLs** (`https://images.unsplash.com/...`). No local assets or placeholder images. URLs are functional but:
- Some Unsplash images are reused across different offer types
- No offline fallback images
- No image height/width metadata

### Event ticketing realism
- 6 of 7 events have ticket pricing
- Price ranges are realistic (e.g., Rs. 500-2000 for food festival, Rs. 1000-5000 for cricket match)
- Ticket counts are consistent (e.g., venue capacity 30, tickets 20 for cooking workshop)
- Some URLs point to `.lk` domains that likely don't exist

### Entity constraint violations
- **Promotion `promo_flash_phones_001`**: `unitsAvailable: 8` but `unitsSold: 42` — more sold than available
- **ShopOffer `shop_ceylon_tea_005`**: `shopType` is `ShopType.restaurant` for a tea-tasting session (arguable)
- **Commerce Bank `commercial_ceyair_009`**: Title says "domestic flights", `applicableCards` includes `'CREDIT'`, but description says "economy class bookings" — no domestic economy class distinction
- Some offers with `discount.type = 'cashback'` have discount value as `10.0` (percentage) but title says "cashback" — the mock data mixes percentage and amount semantics

---

## 6. Local Persistence Analysis

### What is persisted
All persistence uses **SharedPreferences** via `UserRepositoryImpl` and `PreferencesDataSource`. No Hive usage found (despite being declared in `pubspec.yaml`).

### Storage keys (`lib/core/constants/storage_keys.dart`)
| Key | Purpose | Type |
|---|---|---|
| `saved_offers` | Saved offer IDs | `List<String>` |
| `preferences` | User preferences | String (stored as `preferences.toString()`, not JSON!) |
| `recent_searches` | Recent search queries | `List<String>` (max 10) |
| `recently_viewed` | Recently viewed offer IDs | `List<String>` (max 20) |
| `user_location` | User's last known location | `String?` |
| `onboarding_completed` | Onboarding completion flag | `bool` |
| `selected_cards` | Selected bank cards | `List<String>`? |
| `selected_language` | Language code | `String` |

### Serialization format
- Offer IDs are stored as plain strings in string lists
- `UserPreferences` is stored via `preferences.toString()` — this produces a Dart default toString (Instance of 'UserPreferences'), making it **unrecoverable**. The `getPreferences()` method doesn't even try to parse it; it returns defaults instead.
- No JSON serialization is used anywhere

### Full offers vs. IDs
Only **offer IDs** are stored, not full offer objects. When loading saved offers, the app:
1. Reads saved IDs from SharedPreferences
2. Calls `offerRepository.getAllOffers()` to get all offers
3. Filters to match the saved IDs

### Application restart survival
Saved IDs survive restarts because SharedPreferences persists to disk. However, restoring them requires the full offer list to be loaded first. If the data source changes (e.g., to a backend), deleted offers would still have IDs in the saved list but would return null from `getOfferById`.

### Stale local data risks
- **HIGH**: If a backend replaces mock data and an offer ID changes, saved IDs become orphaned
- **HIGH**: If an offer is removed from the backend, the saved list still contains its ID, causing a mismatch
- **MEDIUM**: No versioning or migration system for local data

### Favorites vs. Saved offers
**They are the same concept.** Both `saveOffer`/`unsaveOffer` and `ToggleOfferFavorite` operate on the same `saved_offers` key. The `ToggleOfferFavorite` use case checks `isOfferSaved` and toggles. There is no separate favorites concept.

### Concurrency risks
- `SharedPreferences` operations are async but not transactional
- If two saves/unsaves happen simultaneously, one could overwrite the other (race condition on read-modify-write)

### Migration/versioning
**None.** There is no preferences version key. If the storage format changes, old data is silently lost.

---

## 7. BLoC Analysis

### 7.1 HomeBloc

**File**: `lib/presentation/screens/home/bloc/home_bloc.dart`
**Purpose**: Load home screen data — all offers, featured, nearby, categories

**Events**: `LoadHomeData`, `RefreshHomeData`, `ChangeOfferType`
**States**: `HomeInitial`, `HomeLoading`, `HomeLoaded`, `HomeError`

**Dependencies**: `GetAllOffers`, `GetNearbyOffers`

**Issues**:
- Uses hardcoded `AppConstants.defaultLatitude`/`defaultLongitude` for nearby offers — never requests actual device location
- `_extractCategories` returns `List<Category>` with `IconData` from Flutter — UI logic in BLoC
- `_onRefreshHomeData` re-dispatches `LoadHomeData`, causing a double-loading sequence
- No debounce or cache
- No pagination — loads ALL offers every time
- `Future.delayed(800ms)` hardcoded for "loading experience"

### 7.2 ExploreBloc

**File**: `lib/presentation/screens/explore/bloc/explore_bloc.dart`
**Purpose**: Browse all offers with filtering and sorting

**Events**: `LoadExploreOffers`, `RefreshExploreOffers`, `FilterOffers`, `SortOffers`
**States**: `ExploreInitial`, `ExploreLoading`, `ExploreLoaded`, `ExploreError`

**Dependencies**: `GetAllOffers`, `FilterOffers`

**Issues**:
- `_onRefreshExploreOffers` re-dispatches `LoadExploreOffers` (double-dispatch pattern)
- `_onFilterOffers` re-dispatches `LoadExploreOffers` (double-dispatch pattern)
- Sorting is done client-side on an already-loaded list — won't work with paginated API
- Hardcoded default latitude/longitude for distance-based filtering
- `_sortOffers` has a broken distance sort that does nothing

### 7.3 SearchBloc

**File**: `lib/presentation/screens/search/bloc/search_bloc.dart`
**Purpose**: Search offers with debounce, track recent searches

**Events**: `SearchQueryChanged`, `PerformSearch`, `ClearSearch`, `LoadRecentSearches`, `LoadPopularSearches`
**States**: `SearchInitial`, `SearchLoading`, `SearchResultsLoaded`, `SearchError`

**Dependencies**: `SearchOffers`, `UserRepository`

**Issues**:
- `_onSearchQueryChanged` casts `(state as SearchInitial)` without checking type — will crash if called while in `SearchLoading` or `SearchResultsLoaded` state
- `_onClearSearch` also casts to `SearchInitial` unsafely
- Popular searches are hardcoded strings in the BLoC
- Debounce is implemented manually with `Timer` (acceptable but could use `Debounce` pattern)
- No debounce cancellation on BLoC close (it does cancel in `close()` — good)

### 7.4 SavedBloc

**File**: `lib/presentation/screens/saved/bloc/saved_bloc.dart`
**Purpose**: Load and manage saved offers

**Events**: `LoadSavedOffers`, `RefreshSavedOffers`, `UnsaveOffer`, `FilterByType`
**States**: `SavedInitial`, `SavedLoading`, `SavedLoaded`, `SavedError`

**Dependencies**: `UserRepository`, `OfferRepository`

**Issues**:
- `_onLoadSavedOffers` loads ALL offers from the repository and filters client-side — won't scale
- `_onRefreshSavedOffers` re-dispatches (double-dispatch)
- `_onFilterByType` uses `runtimeType.toString()` — fragile, breaks with minification
- No pagination

### 7.5 EventsBloc

**File**: `lib/presentation/screens/events/bloc/events_bloc.dart`
**Purpose**: Browse events with filtering, sorting, and search

**Events**: `LoadEvents`, `RefreshEvents`, `FilterEventsByType`, `SortEvents`, `SearchEvents`
**States**: `EventsInitial`, `EventsLoading`, `EventsLoaded`, `EventsError`

**Dependencies**: `OfferRepository`

**Issues**:
- `_onRefreshEvents` is a complex method that loads ALL events and then filters/sorts client-side. It duplicates logic from `_onLoadEvents`, `_onFilterEventsByType`, `_onSortEvents`, and `_onSearchEvents`
- All event search is client-side, filtering an already-loaded full list
- No pagination or lazy loading
- Casts `List<dynamic>` to `List<Event>` — will crash if non-event types appear in the event list
- No debounce on search events (unlike SearchBloc)

### Cross-BLoC issues

| Issue | Severity | BLoCs affected |
|---|---|---|
| Double-dispatch pattern (handler re-dispatches events) | Medium | HomeBloc, ExploreBloc, SavedBloc, EventsBloc |
| Unsafe `(state as ...)` casts | High | SearchBloc |
| `runtimeType.toString()` for type checking | High | SavedBloc |
| `List<dynamic>` lack of type safety | High | All BLoCs |
| No pagination | Medium | All BLoCs |
| No request cancellation | Medium | All BLoCs |
| Hardcoded default location | Low | HomeBloc, ExploreBloc |
| UI logic in BLoC (IconData, category extraction) | Low | HomeBloc |

---

## 8. Navigation Analysis

**File**: `lib/presentation/routes/app_router.dart`

### Routes

| Path | Screen | Notes |
|---|---|---|
| `/splash` | `SplashScreen` | Initial route |
| `/onboarding` | `OnboardingScreen` | First-time user flow |
| `/` | `MainNavigationScreen` | Main app shell (tabs: home/explore/saved/profile) |
| `/offer/:id` | `OfferDetailScreen` | Detail page via path parameter |
| `/search` | `SearchScreen` | Search screen |
| `/explore` | `ExploreScreen` | Browse/filter |
| `/events` | `EventsScreen` | Events screen |

### Issues

1. **No shell routes** — `MainNavigationScreen` is a flat route instead of using GoRouter's `ShellRoute`. This means navigation state IS managed internally by MainNavigationScreen (likely using IndexedStack or BottomNavigationBar), not by GoRouter. This makes deep-linking to tabs harder.

2. **No deep-link support** — No redirect logic, no auth guards, no deep-link handling. The router is a simple flat list.

3. **Unknown route handling** — No `errorBuilder` or unknown route handler configured. Unmatched routes would show a blank page.

4. **Offer detail uses `CustomTransitionPage`** with a no-op transition. This prevents swipe-to-go-back gestures, which is intentional but limits navigation UX.

5. **No auth redirect** — No redirect logic for authentication. All routes are accessible without auth.

6. **Event detail page missing** — There is no dedicated `/events/:id` route. Events appear to use the same `/offer/:id` detail screen.

7. **No typed route parameters** — Uses string path parameters. No route data validation.

8. **No deep-link to specific offers** — The `/offer/:id` route supports it in theory, but no deep-link configuration.

---

## 9. Dependency Injection Analysis

**File**: `lib/core/di/injection.dart`

### Setup
- Uses `GetIt` with manual registrations (not using `InjectableInit` code generation despite the `@InjectableInit()` annotation)
- No generated `.g.dart` file found
- All registrations are manual

### Registrations

| Type | Lifetime | Count |
|---|---|---|
| `SharedPreferences` | Singleton | 1 |
| `LanguageService` | Singleton | 1 |
| `LocationService` | Singleton | 1 |
| `OfferRepository` | LazySingleton | 1 |
| `UserRepository` | LazySingleton | 1 |
| Use cases | LazySingleton | 9 |
| BLoCs | Factory | 5 |

### Initialization order
1. `SharedPreferences.getInstance()` (async)
2. Services (LanguageService, LocationService)
3. Repositories
4. Use cases
5. BLoCs

### Issues

1. **No data source registration** — `OfferRepositoryImpl` hardcodes `MockOffersData`. To add a `RemoteOfferDataSource`, the DI setup must change.

2. **No environment switching** — No mechanism to swap mock vs. remote repositories.

3. **`@InjectableInit()` annotation but no generator run** — The annotation is present but `build_runner` has likely not been run. The code is all manual anyway.

4. **All BLoCs are factory** — Correct, each screen gets its own instance.

5. **Missing registrations**: `ToggleOfferFavorite` is registered but `FavoriteOffer` (as a separate concept) is not. `PreferencesDataSource` is never registered — it's declared but unused.

6. **No HTTP client registered** — No Dio or HTTP client in DI for future API use.

---

## 10. Localization Analysis

**File**: `lib/core/localization/app_localizations.dart`

### Supported languages
| Code | Language | Complete? |
|---|---|---|
| `en` | English | Full |
| `si` | Sinhala | Full |
| `ta` | Tamil | Full |

All three languages have complete translations for every string key (about 70 strings).

### Format
- Inline `Map<String, Map<String, String>>` — no ARB files, no Flutter intl generate
- Custom `LocalizationsDelegate` implementation
- Uses `replaceAll('{days}', ...)` for parameterized strings

### Hard-coded strings
- `lib/core/constants/app_strings.dart` contains **duplicate hardcoded English strings** that mirror the localization keys. This file appears to be unused by the actual code (the localization class is self-contained).
- Mock data content (`title`, `description` in mock_offers_data.dart) is entirely in English — **not localized**.

### Persistence
- Language selection is persisted via `SharedPreferences` key `selected_language`
- Default is `'en'`

### Switching mechanism
- In `app.dart`, the app state stores the current `Locale`
- `LanguageService.setLocale()` saves to SharedPreferences
- The `LanguageChangeExtension` on `BuildContext` allows locale switching from anywhere
- The app rebuilds with the new locale

### Sinhala/Tamil rendering
- Both Sinhala and Tamil use Unicode characters
- `google_fonts` is declared in `pubspec.yaml` to handle custom font rendering
- No special font configuration for Sinhala/Tamil glyphs was found in the theme

### Missing
- `dayLeft` parameterized string is the only parameterized localization
- No RTL layout support (Sinhala and Tamil use LTR scripts, but some Tamil users expect some RTL elements)
- Mock data not localized

---

## 11. Map and Location Analysis

### Location permission handling (`lib/core/services/location_service.dart`)
- Uses `geolocator` package for GPS position
- Uses `geocoding` package for reverse geocoding
- Uses `permission_handler` for opening app settings
- Properly chains: service enabled → permission check → request if denied → return null if deniedForever
- Timeout of 20 seconds on position retrieval
- Accuracy: `LocationAccuracy.medium`

### Current-location retrieval
- Returns `Position?` — nullable on all error paths
- Graceful error handling: catches all exceptions and returns null
- Uses `Geolocator.getCurrentPosition()` (one-shot, not continuous)

### Distance calculation (`lib/core/utils/distance_calculator.dart`)
- Uses **Haversine formula** — correct
- Returns distance in kilometers
- `formatDistance()` shows meters for <1km, km for >=1km
- Earth radius: 6371km (correct)

### Nearby-offer filtering
- Done client-side in `MockOffersData.getNearbyOffers()`
- Calculates Haversine distance from user coords to offer's first location
- Default radius: 10km (`AppConstants.defaultRadiusKm`)
- Uses hardcoded Colombo coordinates by default (`6.9271, 79.8612`)

### Map views
- `lib/presentation/common/widgets/map_view.dart` — generic map widget
- `lib/presentation/screens/events/widgets/map_view_screen.dart` — events map
- `lib/presentation/screens/explore/widgets/map_view_screen.dart` — explore map
- Uses `flutter_map` with OpenStreetMap tiles (no API key required)
- Markers are generated from offer/event locations

### Issues

1. **No map clustering** — All markers shown individually. 34+ markers on a small map would be cluttered.
2. **No coordinate validation** — No bounds checking on latitude/longitude.
3. **No denied-permission UX** — When location is denied, the app silently uses Colombo defaults without informing the user.
4. **`permission_handler` is imported but location_service.dart uses `geolocator`'s own permission API** — `openAppSettings()` is the only place `permission_handler` is used. Redundant dependency.
5. **Web and desktop behavior** — `geolocator` and `geocoding` have limited web support. Desktop is untested.
6. **Android manifest** — Needs to be checked for `ACCESS_FINE_LOCATION` permission declaration.
7. **Nearby offers are calculated locally**, not via repository — the `OfferRepository.getNearbyOffers` method exists but currently delegates to the same local Haversine calculation.

