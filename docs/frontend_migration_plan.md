# Lanka Offers — Frontend Migration Plan

**Generated**: 2026-07-17

---

## Guiding Principles

1. **UI must keep working** during every phase — no regressions
2. **Mock data must remain** as a fallback for development/testing
3. **Phase in order of dependency**: DTOs → network → cache → auth
4. **One PR per sub-task**

---

## Phase 1: Foundation (DTOs, Mappers, Network Client)

**Goal**: Introduce the DTO layer, mappers, and network client without changing UI behavior. Keep mock data as the active data source. Verify with unit tests.

### Tasks

| # | Task | Files affected | Effort |
|---|---|---|---|
| 1.1 | Create `lib/data/models/` with 18 DTO files with `fromJson`/`toJson` | New files | Medium |
| 1.2 | Create `lib/data/mappers/` with mappers from DTO to domain entity | New files | Medium |
| 1.3 | Add `dio` to `pubspec.yaml` and configure HTTP client with base URL, timeouts, interceptors | `pubspec.yaml`, new `network_client.dart` | Low |
| 1.4 | Create `OfferRemoteDataSource` with all API call methods | New file | Medium |
| 1.5 | Create `AuthRemoteDataSource` with login/register/refresh | New file | Low |
| 1.6 | Create `Failure` types in domain layer | `lib/domain/failures/` | Low |
| 1.7 | Add `dio` and remote data sources to DI container | `lib/core/di/injection.dart` | Low |
| 1.8 | Write unit tests for DTO parsing (test with mock JSON responses) | New test files | Medium |
| 1.9 | Write unit tests for mappers (DTO → domain entity) | New test files | Medium |

### Success criteria
- All DTO round-trip tests pass (JSON → DTO → JSON)
- All mapper tests pass (DTO → domain entity fields are correctly mapped)
- `dio` client initializes with correct configuration
- `OfferRemoteDataSource` can be instantiated but is **not yet** active in the repository

### Risk
- JSON snake_case ↔ Dart camelCase mapping must be consistent
- `Discount.value` (dynamic) requires special handling in `DiscountDTO`

---

## Phase 2: Backend Integration (Offers, Events, Search, Filters)

**Goal**: Replace mock data for read-only operations (listing, details, search, filters, events) with real API calls. Mock data remains active for write operations until Phase 4.

### Tasks

| # | Task | Files affected | Effort |
|---|---|---|---|
| 2.1 | Update `OfferRepositoryImpl` to accept `OfferRemoteDataSource` + optionally use mock fallback | `offer_repository_impl.dart` | Medium |
| 2.2 | Update repository interface methods to support pagination (`page`, `perPage` params) | `offer_repository.dart`, all use cases, BLoCs | Medium |
| 2.3 | Implement `getAllOffers` via remote data source with DTO→entity mapping | `offer_repository_impl.dart` | Low |
| 2.4 | Implement `getOffersByType`, `getOfferById`, `searchOffers`, `filterOffers` via remote | `offer_repository_impl.dart` | Medium |
| 2.5 | Implement `getNearbyOffers` via remote (server-side distance calculation) | `offer_repository_impl.dart` | Low |
| 2.6 | Implement `getSimilarOffers` via remote | `offer_repository_impl.dart` | Low |
| 2.7 | Update HomeBloc to use paginated calls and typed return values | `home_bloc.dart` | Medium |
| 2.8 | Update ExploreBloc with pagination and typed returns | `explore_bloc.dart` | Medium |
| 2.9 | Update SearchBloc to search via API instead of client-side filter | `search_bloc.dart` | Low |
| 2.10 | Update EventsBloc to use typed `List<Event>` from repository | `events_bloc.dart` | Low |
| 2.11 | Update SavedBloc to load saved offers individually instead of filtering all offers | `saved_bloc.dart` | Medium |
| 2.12 | Add environment-based switching (mock vs. remote) via `app_config.dart` | New file | Low |
| 2.13 | Write integration tests for the full data flow | New test files | Medium |

### Success criteria
- App runs with mock data when configured
- App runs with remote data when environment variable changes
- All list operations support pagination (infinite scroll)
- No `List<dynamic>` in any state — all BLoCs use typed lists
- Search debounce fires API calls instead of local filter
- Events screen loads `List<Event>` from API

### Risk
- API response format may differ from current mock structure — coordinate with backend team (see Domain Backend Field Mapping doc)
- Pagination requires UI changes: scroll listeners, loading indicators at bottom
- No offline fallback yet — app crashes if network is unavailable

---

## Phase 3: Caching, Offline, and Synchronization

**Goal**: Add local cache and offline-first behavior so the app works without a network connection.

### Tasks

| # | Task | Files affected | Effort |
|---|---|---|---|
| 3.1 | Add `hive` or `drift` (SQLite) as local cache database | `pubspec.yaml` | Medium |
| 3.2 | Create `OfferCacheDataSource` with CRUD for offer lists and details | New file | High |
| 3.3 | Create `UserCacheDataSource` for saved IDs, recent searches, recently viewed | New file | Medium |
| 3.4 | Implement cache-first-write-through pattern in `OfferRepositoryImpl` | `offer_repository_impl.dart` | High |
| 3.5 | Add TTL-based cache invalidation | New utility | Medium |
| 3.6 | Add "stale data" indicator to offer cards (show when data was last synced) | New widget, minor UI update | Low |
| 3.7 | Implement offline save/unsave queue (sync when online) | New sync service | Medium |
| 3.8 | Add connectivity monitoring (connectivity_plus or similar) | New service | Low |
| 3.9 | Write cache unit tests and offline-scenario integration tests | New test files | Medium |

### Success criteria
- List screens work offline (shows cached data with staleness indicator)
- Cache is refreshed when network is available
- Save/unsave operations queued offline and synced when online
- TTL-based expiry: data older than `AppConstants.cacheExpiry` (24h) shows refresh prompt

### Risk
- Cache invalidation is complex: offers may be updated/expired on backend while cached locally
- Offline save queue conflicts: user saves an offer offline that was deleted on server
- Storage size: offer images are not cached locally, only offer metadata

---

## Phase 4: Authentication, Personalization, Notifications

**Goal**: Add user accounts, authentication, synced saved offers, and push notifications.

### Tasks

| # | Task | Files affected | Effort |
|---|---|---|---|
| 4.1 | Create auth screens (login, register, forgot password) | New screens | Medium |
| 4.2 | Implement Cognito user pool integration for Google sign-in | New auth service | High |
| 4.3 | Add token storage and auto-refresh interceptor | New token service, `dio` interceptor | Medium |
| 4.4 | Add auth guard to GoRouter (redirect to login if not authenticated) | `app_router.dart` | Low |
| 4.5 | Sync local saved offers with server on login (merge) | `user_repository_impl.dart` | Medium |
| 4.6 | Update save/unsave to call API + update local cache | `user_repository_impl.dart` | Low |
| 4.7 | Add user profile screen with preferences | `profile_screen.dart` | Low |
| 4.8 | Add push notifications via Firebase Cloud Messaging | New service, platform config | High |
| 4.9 | Add recently-viewed tracking with API sync | `user_repository_impl.dart` | Low |
| 4.10 | Write auth-related integration tests | New test files | Medium |

### Success criteria
- User can sign up, log in, log out
- Google sign-in works via Cognito
- Saved offers persist across devices after login
- App notifies about offer expiry and new offers
- Unauthenticated users are redirected to login only when trying to use profile/saved features

### Risk
- Token refresh race conditions
- Merging local saved offers with server offers can produce duplicates
- Push notification setup requires Firebase project and platform-specific configuration
- Cognito configuration requires AWS setup

---

## Phase Dependency Diagram

```
Phase 1: Foundation
  ↓
Phase 2: Backend Integration
  ↓
Phase 3: Caching & Offline
  ↓
Phase 4: Auth & Personalization
```

Phase 3 and Phase 4 could partially overlap (caching is needed for offline auth token storage).

---

## Testing Strategy per Phase

| Phase | Unit tests | Widget tests | Integration tests | Manual QA |
|---|---|---|---|---|
| 1 | DTO parsing, mapper conversion | — | — | None |
| 2 | Repository with mock remote | BLoC state changes | Full data flow | Verify each screen loads from mock/remote |
| 3 | Cache CRUD, sync logic | Offline indicators | Offline → online transition | Kill network, verify cached data loads |
| 4 | Auth token lifecycle | Auth screens | Login → save → logout → login merge | Real device auth flow |

---

## Rollback Plan

Each Phase must be implemented as a feature-flag toggle:
- `useMockData` (Phase 1-2): true = current behavior, false = remote API
- `enableOfflineCache` (Phase 3)
- `enableAuth` (Phase 4)

Setting all flags to `true` restores the original mock-only behavior. This allows hot-fixing issues in production without completing the full migration.

---

## Effort Summary

| Phase | Tasks | Estimated person-days | Dependencies |
|---|---|---|---|
| 1 | 9 | 5–7 | None |
| 2 | 13 | 10–14 | Phase 1 complete |
| 3 | 9 | 8–12 | Phase 2 complete |
| 4 | 10 | 10–15 | Phase 2 complete (can overlap with Phase 3) |
| **Total** | **41** | **33–48** | — |
