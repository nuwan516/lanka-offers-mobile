# Lanka Offers — Flutter Consumer Mobile Application

Consumer Android and iOS app for discovering Sri Lankan credit and debit card offers. Flutter 3.44, Dart 3.12, BLoC/Cubit, GetIt, GoRouter, flutter_map (OpenStreetMap).

## What this repository owns, and does not

Owns: the consumer app, its local state (saved offers, card preferences, language), client-side card eligibility matching, and the nearby/map experience.

Does not own: any database access or credentials, scraping, or admin/review/publishing. The app only reads the public API (`https://api.lanka-offers.me`).

## Screens

Four tabs (labels are asserted by `test/widget_test.dart`): **Home**, **Explore**, **Saved**, **Settings**. Search is reached from the search bars.

- **Home**: search entry, nearby shortcut, the ten supported banks with live counts, category shortcuts, highest discounts, ending soon.
- **Explore**: three sections. *Browse* (all offers; scope Online/Island-wide, category, sort), *Nearby* (device location or a city; list or map; radius), *Banks* (all ten banks, honest zero-offer states).
- **Offer detail**: swipe between offers from the list you came from. Shows the discount as the bank states it, validity, eligible cards, transaction limits, the bank's terms, where it applies, and a link to the original bank offer.
- **Search**: debounced, with recent searches and an empty/error state.

## Architecture

```
lib/
├── core/
│   ├── semantics/          # offer_semantics.dart: the single home of discount wording, Sri Lanka
│   │                       #   expiry, terms quoting and area-level location rules
│   ├── constants/banks.dart# the ten canonical banks (names and monograms, no logos)
│   ├── localization/       # en/si/ta strings; redesign_strings.dart for the redesigned screens
│   ├── theme/              # colours, type, ThemeData (teal on warm neutrals; dark mode)
│   └── di/ services/ utils/ extensions/ enums/
├── data/                   # ApiOffersDataSource (paged), repositories
├── domain/                 # entities, repository interfaces, use cases, CardMatchingService
└── presentation/
    ├── common/widgets/     # OfferCard, BankBadge, offer_presentation (localized text), skeletons, state views
    ├── routes/             # GoRouter; tab_navigation.dart lets Home open Explore on a bank/section
    └── screens/            # home, explore (cubits: browse, nearby, banks), search, offer_detail,
                            #   saved, profile, preferences, onboarding
```

State management stays BLoC/Cubit with GetIt; no other state framework is used.

## Offer semantics (do not bypass)

All screens go through `OfferSemantics` and `OfferPresentation`:

- **Discount**: "Up to N%" only when the bank's own title/description says "up to" for that same N. The API has no "up to" flag. Otherwise "N% off". Free text is kept verbatim.
- **Spend limits**: minimum transaction and maximum transaction value (from `raw_offer.transactionRange`) are shown under those exact names. A discount cap is never inferred; a cap or minimum-bill sentence is quoted verbatim from the terms.
- **Expiry**: valid through the whole last day in Sri Lanka time (UTC+05:30); no end date is labelled as such.
- **Location**: online and island-wide offers are never pinned. A location whose address is only a place name (for example `Colombo, Sri Lanka`) is *area-only*: no pin, no distance, listed after confirmed branches. This is a conservative client rule because the API has no precision flag; an additive `location_precision` field would replace it.

## Configuration

The API base URL is a compile-time define:

```bash
flutter run --dart-define=API_URL=https://api.lanka-offers.me   # release builds default to this
flutter run --dart-define=API_URL=http://10.0.2.2:3001          # Android emulator, local API
```

Debug builds default to `http://localhost:3001` (`http://10.0.2.2:3001` on Android) unless `API_URL` is set.

## Commands

| Command | Purpose |
|---|---|
| `flutter analyze` | Static analysis (currently clean) |
| `flutter test` | All unit and widget tests |
| `flutter build web --release` | Web build, useful for visual checks at phone sizes |
| `flutter build apk --debug` | Android debug build (requires the Android SDK) |

## Tests

| Area | Files |
|---|---|
| Discount wording, Sri Lanka expiry, terms quoting | `test/semantics/offer_semantics_test.dart` |
| Area-only vs confirmed branch locations | `test/semantics/area_level_location_test.dart` |
| API response parsing, paging, banks directory, detail terms | `test/data/api_parsing_test.dart` |
| Cards: wording, validity, location, localization and large-text layout | `test/presentation/offer_card_test.dart` |
| Detail: limits, caps, eligibility, expiry, scope, source link, layout | `test/presentation/offer_detail_content_test.dart` |
| Home states, Home to Explore flow, bank filtering | `test/presentation/home_explore_flow_test.dart` |
| Browse filtering/sorting, request ordering | `test/presentation/browse_cubit_test.dart` |
| Location permission denial and manual fallback | `test/presentation/nearby_cubit_test.dart` |
| Search debounce and stale-response protection | `test/presentation/search_bloc_test.dart` |
| Earlier suites | `test/phase6_*`, `phase7_*`, `phase8_*`, `widget_test.dart` |

Tests use fakes from `test/support/fakes.dart`; none touch the network.

## Known limitations

- No bank logos (none are licensed); banks are shown by name and monogram.
- Sinhala and Tamil strings in `redesign_strings.dart` are best effort and need native-speaker review.
- Verified visually on Flutter web at phone widths; not run on an Android or iOS device or emulator here.
- `flutter build apk` needs the Android SDK and was not run.
