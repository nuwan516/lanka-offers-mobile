# Phase 1 bank-offers UI implementation

## Scope

The production navigation and reachable routes now focus on bank-card offers only. Shop,
promotion, event, ticketing, authentication, and account UI remain in source for future
work but are not exposed by the Phase 1 navigation or router.

## Screens changed

- Main navigation: Home, Explore, Saved, Settings (exactly four destinations).
- Onboarding: three bank-offer pages, optional location, no identity request.
- Home: bank-only header/search, preference prompt, featured/expiring/all offers,
  explicit location-off state, and eligible Phase 2 survey.
- Explore: bank-only list, supported category/district filters, filter count, refresh,
  empty/error/loading states.
- Search: debounced bank-only search, recent searches, clear, empty and retry states.
- Saved: local bank offers, swipe-to-unsave, orphan cleanup, device-storage notice.
- Settings: preferences, language, local-data clearing, support/legal/about; no account UI.
- Offer details: bank benefit, merchant/bank/cards, validity, restrictions, locations,
  directions, contact/source fallback, save and share; expired offers are marked.
- Bank/card preferences: values derived from available bank offers, multi-select banks,
  credit/debit and available network chips.

## Widgets changed or added

- `OfferCard` is typed to `BankOffer`, includes image fallback, friendly benefits,
  eligibility, expiry badges, overflow protection, semantics, and local save state.
- `BankCardPreferencesScreen` was added.
- Consistent existing error/loading widgets are used by reachable screens.

## Routes removed or hidden

- `/events` was removed.
- Event bottom navigation and mixed offer-type Home tabs were removed.
- `/preferences` was added.
- Event/shop/promotion implementation files remain unmodified in purpose and unreachable.

## Local persistence

- `preferences`: structured JSON containing selected banks, card types, networks,
  categories, districts, radius, saved cards, and notification preference.
- `phase_two_survey_state`: JSON survey shown/dismissed/opt-out/response/timestamp/version.
- `app_open_days`: distinct local calendar days.
- `viewed_offer_count`: local offer-detail view count.
- Existing `saved_offers`, `recent_searches`, language, and onboarding keys remain.

Legacy non-JSON preference values are ignored safely and replaced by defaults on the
next save.

## Survey trigger logic

The anonymous survey is eligible after three distinct open days, eight viewed offers,
or two saved offers. It is not shown during onboarding. Submission, dismissal, and
permanent opt-out are persisted locally. No identity information is collected. This
checkout has no feedback/analytics endpoint, so submission intentionally stops at the
local persistence boundary.

## Manual verification

- Debug navigation and offer rendering were verified through widget tests.
- Android build/launch verification is recorded in the Phase 1 test report.
- No screenshots were captured in this pass.

## Known limitations

- Contrary to the task premise, this checkout has no DTO, remote data source,
  API pagination model, batch saved-offer endpoint, bank catalogue endpoint, or API
  filter request model. `OfferRepositoryImpl` is still backed by `MockOffersData`.
- Consequently, remote pagination, next-page loading, server-supported advanced filters,
  API-refreshed saved IDs, and official verification timestamps cannot be implemented
  without changing the absent backend integration. No fake UI-only versions were added.
- The current entity does not expose an explicit official-source URL or last-verified
  timestamp. The contact website is used when available; otherwise the action is hidden.
- Category/district settings are visibly marked as awaiting an API update.
- Existing unreachable event/map code retains pre-existing analyzer information-level
  diagnostics.

