# Lanka Offers — API Readiness Report

**Generated**: 2026-07-17

---

## 1. Current State Summary

The entire app uses mock data via `MockOffersData` (34 static records). There is no network layer, no HTTP client, no API DTOs, and no environment-based switching.

---

## 2. What Can Remain Unchanged

### Domain interfaces
- `OfferRepository` (abstract) — method signatures are reasonable; only the implementation must change
- `UserRepository` (abstract) — method signatures are reasonable for user-specific data
- All use cases — they interact with repository interfaces and do not need changes

### Domain entities
- `BaseOffer`, `BankOffer`, `ShopOffer`, `Promotion`, `Event` — these will become the target type that API DTOs map to
- Supporting entities: `Location`, `ValidityPeriod`, `Discount`, `Restrictions`, `QualityScore`, `EngagementMetrics`, `InstallmentPlan`, `Venue`, `EventDateTime`, `Ticketing`, `PriceRange`, `Amenities`, `ContactInfo`, `Deal`

### Presentation layer
- Screens, BLoCs, widgets — they depend on domain entities and use cases. If the repository interface return types remain `List<dynamic>`, no presentation changes are needed. If types are made concrete, only BLoC cast logic changes.

### Localization
- `AppLocalizations` is self-contained and will not change

### Navigation
- `GoRouter` is backend-independent

---

## 3. What Must Change

### 3.1 Interfaces that can remain but need method signature refinement

| Current | Problem | Recommended |
|---|---|---|
| `Future<List<dynamic>>` | Type erasure | `Future<List<BaseOffer>>` |
| No pagination | All methods return all records | Add `{int page, int perPage}` params |
| No error types | All throw on failure | Define `Failure` types |

### 3.2 DTOs that must be created

New directory: `lib/data/models/` or `lib/data/datasources/remote/`

```
lib/data/models/
  offer_dto.dart              # Common offer fields from API
  bank_offer_dto.dart         # Bank-specific fields
  shop_offer_dto.dart         # Shop-specific fields
  promotion_dto.dart          # Promotion-specific fields
  event_dto.dart              # Event-specific fields
  location_dto.dart
  validity_period_dto.dart
  discount_dto.dart
  restrictions_dto.dart
  contact_info_dto.dart
  quality_score_dto.dart
  engagement_metrics_dto.dart
  installment_plan_dto.dart
  venue_dto.dart
  event_date_time_dto.dart
  ticketing_dto.dart
  price_range_dto.dart
  amenities_dto.dart
  paginated_response_dto.dart
  error_response_dto.dart
```

Each DTO needs:
- `factory FromJson(Map<String, dynamic> json)`
- `Map<String, dynamic> toJson()`

### 3.3 Mappers that must be created

New directory: `lib/data/mappers/`

```
lib/data/mappers/
  offer_mapper.dart           # OfferDTO → BaseOffer subtypes
  location_mapper.dart
  validity_period_mapper.dart
  discount_mapper.dart
  ...
```

### 3.4 Remote data source that must be created

```
lib/data/datasources/remote/
  offer_remote_datasource.dart
  auth_remote_datasource.dart
```

### 3.5 Network client requirements

- HTTP client (recommended: `Dio`)
- Base URL configuration
- Request/response interceptors
- Authentication header injection (Bearer token)
- Error mapping to domain-friendly types
- Timeout configuration

### 3.6 Repository implementation changes

`OfferRepositoryImpl` must:
- Accept both `OfferRemoteDataSource` and a local cache data source
- Fall back to cache when network is unavailable
- Map DTOs to domain entities via mapper layer
- Switch from `MockOffersData` to remote calls

### 3.7 Pagination requirements

Every list endpoint must support:
- `page` (integer, 1-based)
- `per_page` or `limit` (integer, default 20)
- Response must include: `data[]`, `total`, `page`, `per_page`, `total_pages`

BLoCs must be updated to:
- Append pages instead of replacing
- Track `hasMore` state
- Implement `loadMore` events

### 3.8 Local cache data source

```
lib/data/datasources/local/
  offer_cache_datasource.dart    # SQLite / Hive / SharedPreferences
```

Store:
- Recent offer lists (by type, search, filter)
- Individual offer details
- Last-fetched timestamps for TTL-based invalidation

### 3.9 Error mapping

Create a domain `Failure` class hierarchy:

```dart
sealed class Failure {}
class ServerFailure extends Failure { final int statusCode; final String message; }
class NetworkFailure extends Failure {}
class CacheFailure extends Failure {}
class AuthFailure extends Failure {}
```

Update repositories to return `Either<Failure, T>` or throw typed exceptions.

### 3.10 Offline handling

Strategy:
1. On network success: write response to local cache with timestamp
2. On network failure: read from local cache, check TTL
3. Show stale indicator if data is older than TTL
4. Queue save/unsave operations for sync when online

### 3.11 Saved-offer synchronization

Current: saved IDs stored only in SharedPreferences (device-local).
Required: saved offers stored on backend, synced to device.
- On login: merge local saved IDs with server list
- On save: call API, then update local storage
- On unsave: call API, then update local storage
- Handle conflict resolution (server wins by default)

### 3.12 Authentication preparation

Add to `lib/core/di/`:
- Auth token storage service
- Token refresh interceptor
- User session repository

Router updates:
- Auth guard redirect
- Post-login redirect to intended destination

---

## 4. Target Data Flow

```
Flutter UI (List<BaseOffer> / BankOffer / Event etc.)
→ BLoC (typed states)
→ Use case (typed parameters, typed return)
→ Repository interface (typed, paginated)
→ Repository implementation
  ├─ Remote data source (network call) ──→ DTO ──→ Mapper ──→ Domain entity
  └─ Local cache data source (fallback) ──→ Domain entity (cached)
```

---

## 5. Backend Contract Requirements

### Endpoint map

| # | Method | Path | Purpose | Paginated | Auth |
|---|---|---|---|---|---|
| 1 | GET | `/api/v1/offers` | List all offers | Yes | No |
| 2 | GET | `/api/v1/offers/{id}` | Get offer details | — | No |
| 3 | GET | `/api/v1/offers/search?q=` | Search offers | Yes | No |
| 4 | GET | `/api/v1/offers` | Filter by type/category/district | Yes | No |
| 5 | GET | `/api/v1/offers/nearby?lat=&lng=&radius=` | Nearby offers | Yes | No |
| 6 | GET | `/api/v1/offers/similar/{id}` | Similar offers | No | No |
| 7 | GET | `/api/v1/events` | List events | Yes | No |
| 8 | GET | `/api/v1/events/{id}` | Event details | — | No |
| 9 | GET | `/api/v1/categories` | List categories | No | No |
| 10 | GET | `/api/v1/banks` | List banks | No | No |
| 11 | POST | `/api/v1/users/saved-offers/{id}` | Save an offer | — | Yes |
| 12 | DELETE | `/api/v1/users/saved-offers/{id}` | Unsave an offer | — | Yes |
| 13 | GET | `/api/v1/users/saved-offers` | List saved offers | Yes | Yes |
| 14 | GET | `/api/v1/users/profile` | User profile | — | Yes |
| 15 | POST | `/api/v1/auth/login` | Authentication | — | — |
| 16 | POST | `/api/v1/auth/register` | Registration | — | — |
| 17 | POST | `/api/v1/auth/refresh` | Token refresh | — | — |
| 18 | GET | `/api/v1/users/recently-viewed` | Recently viewed | Yes | Yes |
| 19 | POST | `/api/v1/users/recently-viewed/{id}` | Track view | — | Yes |
| 20 | GET | `/api/v1/offers/categories/{category}` | Offers by category | Yes | No |

### Request/Response shapes

#### GET /api/v1/offers
```
Query params: ?page=1&per_page=20&type=bank_offer&category=Shopping&district=Colombo

Response 200:
{
  "data": [
    {
      "id": "hnb_hilton_001",
      "type": "bank_offer",
      "title": "20% Off at Hilton Colombo",
      "description": "...",
      "category": "Dining",
      "subcategories": ["Fine Dining", "Hotels"],
      "bank_name": "HNB",
      "merchant_name": "Hilton Colombo",
      "discount": { "type": "percentage", "value": 20.0, "description": "20% off" },
      "installment_plans": null,
      "applicable_cards": ["VISA", "MASTERCARD", "CREDIT"],
      "restrictions": { "key_restrictions": [...], "booking_required": true },
      "min_transaction": null,
      "locations": [
        {
          "name": "Hilton Colombo",
          "address": "2 Sir Chittampalam A Gardiner Mawatha, Colombo 02",
          "district": "Colombo",
          "city": "Colombo",
          "latitude": 6.9271,
          "longitude": 79.8612
        }
      ],
      "validity": {
        "valid_from": "2026-06-17T00:00:00Z",
        "valid_until": "2026-09-15T00:00:00Z",
        "days_applicable": "All Days",
        "time_restrictions": null
      },
      "contact": { "phone": ["+94112492492"], "email": ["info@hilton.com"], "website": "..." },
      "images": ["https://..."],
      "featured_image": "https://...",
      "quality_score": { "confidence": 0.95, "grade": "A" },
      "metrics": { "views": 1250, "saves": 89, "clicks": 156, "popularity_score": 78.5 },
      "created_at": "2026-06-01T00:00:00Z",
      "updated_at": "2026-07-01T00:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 34,
    "total_pages": 2
  }
}

Response 400/500:
{
  "error": {
    "code": "INVALID_PARAMETER",
    "message": "Invalid value for 'type' parameter",
    "details": {}
  }
}
```

#### GET /api/v1/events
```
Response: Same shape as offers but with event-specific fields:
- event_type (enum)
- organizer
- venue { name, address, capacity, indoor }
- event_date_time { start, end, doors_open }
- ticketing { required, price_range, early_bird, tickets_available, tickets_sold, booking_url }
- amenities { parking, wheelchair, food, wifi }
- age_restriction
- family_friendly
```

#### POST /api/v1/auth/login
```
Request:
{
  "email": "user@example.com",
  "password": "securepassword"
}

Response 200:
{
  "access_token": "eyJhbGciOi...",
  "refresh_token": "eyJhbGciOi...",
  "expires_in": 3600,
  "user": {
    "id": "user_001",
    "name": "User Name",
    "email": "user@example.com",
    "preferences": { ... }
  }
}
```

---

## 6. Implementation Estimates

| Component | Estimated effort | Priority |
|---|---|---|
| DTOs (18 files) | Medium | Phase 1 |
| Mappers (6 groups) | Medium | Phase 1 |
| Network client (Dio setup) | Low | Phase 1 |
| Remote data sources | Medium | Phase 1 |
| Repository implementation rewrite | Medium | Phase 2 |
| Pagination in BLoCs | Medium | Phase 2 |
| Error handling/failures | Medium | Phase 2 |
| Local cache | High | Phase 3 |
| Offline sync | High | Phase 3 |
| Auth integration | High | Phase 4 |
| Saved-offer sync | Medium | Phase 4 |
