# Lanka Offers — Domain/Backend Field Mapping

**Generated**: 2026-07-17

---

## Overview

This document maps the backend normalized offer records (from the scraper/validation pipeline) to the current Flutter domain entities. It identifies compatibility gaps, required conversions, and missing fields.

---

## Field Mapping Table

### Core offer fields

| Backend normalized field | Current Flutter field | Compatible | Conversion needed | Missing |
|---|---|---|---|---|
| `source_url` | — | No | — | **Yes** — not in any entity |
| `source_type` (e.g., bank_website, shop_website, social, manual) | — | No | — | **Yes** — not in any entity |
| `source_retrieval_time` (ISO 8601) | — | No | — | **Yes** — not in any entity |
| `bank` | `BankOffer.bankName` | Yes | String match | — |
| `card_type` (VISA, MASTERCARD, AMEX) | `BankOffer.applicableCards` | Partial | Currently `List<String>`, needs enum normalization | — |
| `merchant` | `BankOffer.merchantName` / `ShopOffer.shopName` | Yes | String match | — |
| `category` (normalized from enum) | `BaseOffer.category` | Partial | Currently free-text; needs enum mapping | — |
| `subcategories` (normalized list) | `BaseOffer.subcategories` | Yes | String match | — |
| `title` | `BaseOffer.title` | Yes | — | — |
| `description` | `BaseOffer.description` | Yes | — | — |
| `discount_or_benefit` (structured: type, value) | `Discount` / `Deal` | Partial | `Discount.value` is `dynamic`; needs strict typing | — |
| `eligibility` (free-text terms) | `Restrictions.keyRestrictions` | Partial | Free-text in both; needs structured format | — |
| `locations[]` | `BaseOffer.locations` (embedded) | Partial | No `Location.id`; embedded vs. referenced | — |
| `start_date` (ISO 8601) | `ValidityPeriod.validFrom` | Yes | — | — |
| `expiry_date` (ISO 8601) | `ValidityPeriod.validUntil` | Yes | — | — |
| `terms` (structured key-value) | `Restrictions` | Partial | Currently weakly typed | — |
| `validation_status` (validated, pending, rejected) | `QualityScore` | Partial | `QualityScore` combines confidence + grade; validation status is separate | **Yes** — not directly represented |
| `confidence_score` (0.0–1.0) | `QualityScore.confidenceScore` | Yes | — | — |
| `duplicate_status` (unique, probable_duplicate, confirmed_duplicate) | — | No | — | **Yes** — not in any entity |
| `provenance` (scraper ID, source-specific metadata) | — | No | — | **Yes** — not in any entity |
| `raw_evidence_reference` (screenshot URL, source page HTML) | — | No | — | **Yes** — not in any entity |
| `record_status` (new, changed, unchanged, expired, duplicate, validation-failed) | — | No | — | **Yes** — not in any entity |
| `created_at` (ISO 8601) | — | No | — | **Yes** — no audit timestamps |
| `updated_at` (ISO 8601) | — | No | — | **Yes** — no audit timestamps |

### BankOffer-specific fields

| Backend normalized field | Current Flutter field | Compatible | Conversion needed | Missing |
|---|---|---|---|---|
| `installment_options[]` | `BankOffer.installmentPlans` | Yes | — | — |
| `min_transaction_amount` | `BankOffer.minTransaction` | Yes | Raw `double` → typed Money | — |
| `applicable_cards[]` (normalized enum) | `BankOffer.applicableCards` | Partial | String → enum normalization | — |

### ShopOffer-specific fields

| Backend normalized field | Current Flutter field | Compatible | Conversion needed | Missing |
|---|---|---|---|---|
| `shop_type` (retail, restaurant, service, etc.) | `ShopOffer.shopType` | Partial | Currently `ShopType` enum from core; could be shared | — |
| `promo_code` | `ShopOffer.promoCode` | Yes | — | — |
| `min_purchase_amount` | `ShopOffer.minPurchaseAmount` | Yes | Raw `double` → typed Money | — |
| `hours_of_operation` | `ShopOffer.hoursOfOperation` | Partial | Free-text string; backend could use structured format | — |
| `verified` | `ShopOffer.verified` | Yes | — | — |
| `verification_date` | `ShopOffer.verificationDate` | Yes | — | — |

### Promotion-specific fields

| Backend normalized field | Current Flutter field | Compatible | Conversion needed | Missing |
|---|---|---|---|---|
| `promotion_type` (flash_sale, limited_time, seasonal) | `Promotion.promotionType` | Partial | Free-text → normalized enum | — |
| `urgency_level` (urgent, high, normal) | `Promotion.urgencyLevel` | Partial | Free-text → normalized enum | — |
| `deal` (original_price, sale_price, discount %) | `Promotion.deal` | Yes | — | — |
| `stock_status` | `Promotion.stockStatus` | Partial | Free-text → normalized enum | — |
| `units_available` | `Promotion.unitsAvailable` | Yes | — | — |
| `units_sold` | `Promotion.unitsSold` | Yes | — | — |
| `flash_duration_hours` | `Promotion.flashDurationHours` | Yes | — | — |
| `countdown_enabled` | `Promotion.countdownEnabled` | Yes | — | — |

### Event-specific fields

| Backend normalized field | Current Flutter field | Compatible | Conversion needed | Missing |
|---|---|---|---|---|
| `event_type` (concert, festival, workshop, etc.) | `Event.eventType` | Partial | Needs alignment on enum values | — |
| `organizer` | `Event.organizer` | Yes | — | — |
| `venue` | `Event.venue` | Yes | — | — |
| `event_start` / `event_end` (ISO 8601) | `EventDateTime.start` / `EventDateTime.end` | Yes | — | — |
| `doors_open` | `EventDateTime.doorsOpen` | Partial | Free-text; could be structured time | — |
| `ticketing` (price range, availability, URL) | `Event.ticketing` | Yes | — | — |
| `amenities` (parking, wheelchair, food, wifi) | `Event.amenities` | Yes | — | — |
| `age_restriction` | `Event.ageRestriction` | Partial | Free-text → normalized enum | — |
| `family_friendly` | `Event.familyFriendly` | Yes | — | — |

### User-specific fields (not in normalized offer pipeline)

| Backend / UI field | Current Flutter field | Compatible | Conversion needed | Missing |
|---|---|---|---|---|
| `saved_offer_ids[]` | `UserRepositoryImpl` (SharedPrefs) | No | Needs backend sync | — |
| `recent_searches[]` | `UserRepositoryImpl` (SharedPrefs) | No | Needs backend sync | — |
| `recently_viewed[]` | `UserRepositoryImpl` (SharedPrefs) | No | Needs backend sync | — |
| `user_preferences` (categories, districts, radius, cards) | `UserPreferences` | Partial | Stored as broken `toString()`; needs JSON | — |
| `language_preference` | `LanguageService` (SharedPrefs) | Partial | Could be synced to backend | — |

---

## Fields for User Display vs. Administration/Audit

### Displayed to users (in current UI)

| Field | Where shown | Entity |
|---|---|---|
| `title`, `description` | Every card, detail | `BaseOffer` |
| `category` | Card, filter, chips | `BaseOffer` |
| `discount` | Card badge, detail | `Discount` / `Deal` |
| `bank_name` | Card badge, detail | `BankOffer` |
| `merchant_name` / `shop_name` | Card, detail | `BankOffer` / `ShopOffer` |
| `locations` | Detail, map | `BaseOffer.locations` |
| `validity` (date range, days left) | Card, detail | `ValidityPeriod` |
| `images` | Card, carousel, detail | `BaseOffer.images` |
| `contact` | Detail | `ContactInfo` |
| `restrictions` | Detail (Terms) | `Restrictions` |
| `applicable_cards` | Detail | `BankOffer.applicableCards` |
| `installment_plans` | Detail | `InstallmentPlan` |
| `promo_code` | Detail | `ShopOffer.promoCode` |
| `event_type`, `venue`, `event_date_time`, `ticketing` | Event card, detail | `Event` |
| `amenities` | Event detail | `Amenities` |
| `age_restriction`, `family_friendly` | Event detail | `Event` |
| `distance` | Nearby card | Calculated from `Location` |

### Administration / Audit only (not currently shown)

| Field | Purpose | Suggested placement |
|---|---|---|
| `source_url` | Traceability for content team | Not shown in app |
| `source_type` | Debugging scraper issues | Admin panel only |
| `source_retrieval_time` | Debugging freshness | Admin panel only |
| `validation_status` | QA workflow | Admin panel; could show badge if pending/rejected |
| `duplicate_status` | Deduplication pipeline | Admin panel only |
| `provenance` | Audit trail | Admin panel only |
| `raw_evidence_reference` | Manual review reference | Admin panel |
| `record_status` | Pipeline state machine | Admin panel |
| `created_at` / `updated_at` | Debugging, API contract | API response but not displayed |
| `confidence_score` | Currently shown as `QualityScore` | Currently in UI; could move to admin-only |

---

## Recommended Backend-Centric Entity Diagram

```
Normalized offer record (backend pipeline)
  ├── source metadata (admin only)
  ├── core fields (→ BaseOffer)
  ├── bank-specific (→ BankOffer)
  ├── shop-specific (→ ShopOffer)
  ├── promotion-specific (→ Promotion)
  └── event-specific (→ Event)

User profile (backend)
  ├── saved offers (IDs)
  ├── recently viewed (IDs)
  ├── recent searches (strings)
  ├── preferences
  └── language preference
```
