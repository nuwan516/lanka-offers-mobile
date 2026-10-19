import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/semantics/offer_semantics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../../domain/entities/validity_period.dart';

/// Localized, semantics-correct text for the parts of an offer that screens
/// must word identically. All rules live in [OfferSemantics].
class OfferPresentation {
  OfferPresentation._();

  /// "Up to 30% off" only when the bank says so, otherwise "30% off". Free-text
  /// discounts and instalment plans are shown verbatim. Null when the offer
  /// states no benefit at all (callers decide whether to show a placeholder).
  static String? benefit(AppLocalizations l10n, BankOffer offer) {
    final d = offer.discount;
    if (d != null) {
      final percent = OfferSemantics.percentLabel(d);
      if (percent != null) {
        return l10n.format(d.isUpTo ? 'discountUpTo' : 'discountFixed', {
          'value': percent,
        });
      }
      if (d.description.isNotEmpty) return d.description;
    }
    final plans = offer.installmentPlans;
    if (plans != null && plans.isNotEmpty) return plans.first.description;
    return null;
  }

  static String formatDate(DateTime date, Locale locale) => DateFormat.yMMMd(
    locale.languageCode,
  ).format(OfferSemantics.colomboDate(date));

  /// Expiry wording and its tone, from the Sri Lanka calendar day.
  static ValidityLabel validity(
    AppLocalizations l10n,
    ValidityPeriod validity, {
    DateTime? now,
  }) {
    if (validity.hasNoConfiguredExpiry) {
      return ValidityLabel(l10n.text('noExpiryDate'), ValidityTone.neutral);
    }
    if (OfferSemantics.isExpired(validity, now: now)) {
      return ValidityLabel(l10n.text('offerExpired'), ValidityTone.expired);
    }
    final days = OfferSemantics.daysLeft(validity, now: now)!;
    if (days == 0) {
      return ValidityLabel(l10n.text('offerLastDay'), ValidityTone.soon);
    }
    final date = l10n.format('validUntilDate', {
      'date': formatDate(validity.validUntil, l10n.locale),
    });
    if (days <= 7) {
      return ValidityLabel(
        '$date · ${l10n.format('offerDaysLeft', {'days': days})}',
        ValidityTone.soon,
      );
    }
    return ValidityLabel(date, ValidityTone.neutral);
  }
}

enum ValidityTone { neutral, soon, expired }

class ValidityLabel {
  final String text;
  final ValidityTone tone;

  const ValidityLabel(this.text, this.tone);

  Color color(bool isDark) => switch (tone) {
    ValidityTone.expired => isDark ? const Color(0xFFF2B8B5) : AppColors.error,
    ValidityTone.soon => isDark ? const Color(0xFFF5C27A) : AppColors.warning,
    ValidityTone.neutral =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
  };
}

final RegExp _trailingCountry = RegExp(
  r',?\s*sri lanka\s*$',
  caseSensitive: false,
);

/// Short location wording for cards. Never implies a pin the data does not
/// support: online and island-wide are named as such, an area-only location is
/// labelled as an area, and a branch is named only when the source gave an
/// address.
String? offerLocationLabel(AppLocalizations l10n, BankOffer offer) {
  switch (offer.locationScope) {
    case 'ONLINE':
      return l10n.text('scopeOnline');
    case 'NATIONWIDE':
      return l10n.text('scopeNationwide');
    case 'UNRESOLVED':
      return null;
  }

  final confirmed = OfferSemantics.confirmedBranches(offer);
  if (offer.locations.isNotEmpty && confirmed.isEmpty) {
    final first = offer.locations.first;
    final area =
        (first.address.isNotEmpty ? first.address : first.name)
            .replaceFirst(_trailingCountry, '')
            .trim();
    return l10n.format('locationAreaOnly', {'area': area});
  }

  final first = confirmed.isNotEmpty ? confirmed.first : null;
  final place =
      first == null
          ? null
          : (first.city.isNotEmpty ? first.city : first.district);
  final text =
      (place != null && place.isNotEmpty)
          ? place
          : offer.merchantLocation?.split(RegExp(r'[,;\n|]')).first.trim();
  if (text == null || text.isEmpty) {
    return offer.locationScope == 'SELECTED_OUTLETS'
        ? l10n.text('detailScopeSelected')
        : null;
  }
  return confirmed.length > 1 ? '$text +${confirmed.length - 1}' : text;
}
