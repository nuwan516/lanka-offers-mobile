import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../../domain/entities/validity_period.dart';
import '../../../domain/repositories/user_repository.dart';
import 'bank_badge.dart';

class OfferCard extends StatefulWidget {
  const OfferCard({
    super.key,
    required this.offer,
    this.compact = false,
    this.contextOffers,
    this.initialIndex,
  });

  final BankOffer offer;
  final bool compact;
  final List<BankOffer>? contextOffers;
  final int? initialIndex;

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    getIt<UserRepository>().isOfferSaved(widget.offer.uniqueId).then((value) {
      if (mounted) setState(() => _saved = value);
    });
  }

  Future<void> _toggleSaved() async {
    final repository = getIt<UserRepository>();
    _saved
        ? await repository.unsaveOffer(widget.offer.uniqueId)
        : await repository.saveOffer(widget.offer.uniqueId);
    if (mounted) setState(() => _saved = !_saved);
  }

  bool get _expiringSoon {
    if (widget.offer.validity.hasNoConfiguredExpiry) return false;
    final days =
        widget.offer.validity.validUntil.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 7;
  }

  String _benefit(AppLocalizations l10n) {
    final discount = widget.offer.discount;
    if (discount == null) {
      final plans = widget.offer.installmentPlans;
      return plans != null && plans.isNotEmpty
          ? plans.first.description
          : l10n.text('specialOffer');
    }
    final type = discount.type.toLowerCase().replaceAll('_', ' ');
    if (type.contains('percentage')) {
      return discount.description.isNotEmpty
          ? discount.description
          : '${_fmtNum(discount.value)}% off';
    }
    if (type.contains('amount') || type.contains('fixed')) {
      return discount.description.isNotEmpty
          ? discount.description
          : 'LKR ${_fmtNum(discount.value)} off';
    }
    if (type.contains('cashback')) {
      return discount.description.isNotEmpty
          ? discount.description
          : '${_fmtNum(discount.value)}% cashback';
    }
    return discount.description.isNotEmpty ? discount.description : type;
  }

  static String _fmtNum(dynamic v) {
    if (v is double && v == v.truncate()) return v.toInt().toString();
    return v?.toString() ?? '';
  }

  String _formatExpiryDate(DateTime dt) {
    return DateFormat('MMM d, yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offer = widget.offer;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expired = offer.validity.validUntil.isBefore(DateTime.now());
    final benefitText = _benefit(l10n);
    final hasImage = offer.featuredImage != null &&
        offer.featuredImage!.trim().isNotEmpty &&
        offer.featuredImage!.startsWith('http');

    return Semantics(
      button: true,
      label: '${offer.merchantName}, ${offer.title}, $benefitText',
      child: Card(
        margin: EdgeInsets.only(bottom: widget.compact ? 8 : 14),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            context.push(
              '/offer/${offer.uniqueId}',
              extra: {
                'offers': widget.contextOffers ?? [offer],
                'initialIndex': widget.initialIndex ??
                    (widget.contextOffers != null
                        ? widget.contextOffers!.indexOf(offer)
                        : 0),
              },
            );
          },
          child: Padding(
            padding: EdgeInsets.all(widget.compact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Merchant Name + Bank Badge + Bookmark Heart Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.merchantName.isNotEmpty
                                ? offer.merchantName
                                : offer.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.h4.copyWith(
                              fontSize: widget.compact ? 14 : 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          if (offer.bankName.isNotEmpty)
                            BankBadge(
                              bankName: offer.bankName,
                              compact: true,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Optional small thumbnail if real image exists
                    if (hasImage && !widget.compact) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: offer.featuredImage!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                          placeholder: (_, __) => Container(
                            width: 48,
                            height: 48,
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.surfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    // Bookmark heart button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _toggleSaved,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            _saved ? Icons.favorite : Icons.favorite_border,
                            color: _saved
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.textTertiary),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Hero Benefit Callout: Big bold Temu-style discount callout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE51D1D), Color(0xFFFF3333)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE51D1D).withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFFFE600)),
                          const SizedBox(width: 3),
                          Text(
                            benefitText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_expiringSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD600), Color(0xFFFFAB00)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 11,
                              color: Color(0xFF8B0000),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              l10n.endingSoon.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                color: Color(0xFF8B0000),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Offer Title / Subtitle
                Text(
                  offer.title,
                  maxLines: widget.compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body2.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : const Color(0xFF222222),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    fontSize: widget.compact ? 12 : 13.5,
                  ),
                ),

                // Spend limits row (if present)
                if (offer.minTransaction != null || offer.maxTransaction != null) ...[
                  const SizedBox(height: 8),
                  _buildSpendLimitPill(isDark, offer.minTransaction, offer.maxTransaction),
                ],

                const SizedBox(height: 12),

                // Footer Badges Row: Distance, Category, Location Scope, Valid Until
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Distance badge
                    if (offer.distanceKm != null)
                      _buildBadge(
                        context,
                        icon: Icons.near_me,
                        label: _formatDistance(offer.distanceKm!),
                        isPrimaryTint: true,
                        isDark: isDark,
                      ),

                    // Category badge
                    if (offer.category.isNotEmpty)
                      _buildBadge(
                        context,
                        icon: _categoryIcon(offer.category),
                        label: offer.category,
                        isDark: isDark,
                      ),

                    // Location scope badge
                    if (offer.locationScope != null && offer.locationScope!.isNotEmpty)
                      _buildLocationScopeBadge(context, offer.locationScope!, isDark),

                    // Expiry date badge
                    if (!offer.validity.hasNoConfiguredExpiry && !expired)
                      _buildBadge(
                        context,
                        icon: Icons.calendar_today_outlined,
                        label: _formatExpiryDate(offer.validity.validUntil),
                        isDark: isDark,
                      ),
                  ],
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpendLimitPill(bool isDark, double? minTx, double? maxTx) {
    String label = '';
    if (minTx != null && maxTx != null) {
      label = 'Spend Rs. ${_fmtNum(minTx)} – ${_fmtNum(maxTx)}';
    } else if (minTx != null) {
      label = 'Min spend: Rs. ${_fmtNum(minTx)}';
    } else if (maxTx != null) {
      label = 'Max spend: Rs. ${_fmtNum(maxTx)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262830) : const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF3E3A20) : const Color(0xFFFFE082),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.credit_card_outlined,
            size: 11,
            color: isDark ? const Color(0xFFFFD600) : const Color(0xFFB45309),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFFFD600) : const Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double d) {
    if (d < 1.0) return '${(d * 1000).round()} m';
    return '${d.toStringAsFixed(1)} km';
  }

  Widget _buildBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isPrimaryTint = false,
    required bool isDark,
  }) {
    final bg = isPrimaryTint
        ? (isDark
            ? AppColors.primary.withValues(alpha: 0.15)
            : const Color(0xFFFFF0F0))
        : (isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F6));
    final fg = isPrimaryTint
        ? (isDark ? AppColors.primaryLight : AppColors.primary)
        : (isDark ? AppColors.darkTextSecondary : const Color(0xFF4B5563));
    final border = isPrimaryTint
        ? (isDark
            ? AppColors.primary.withValues(alpha: 0.3)
            : const Color(0xFFFFCDD2))
        : (isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB));

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationScopeBadge(
      BuildContext context, String scope, bool isDark) {
    IconData icon;
    String label;
    if (scope == 'ONLINE') {
      icon = Icons.language;
      label = 'Online';
    } else if (scope == 'NATIONWIDE') {
      icon = Icons.public;
      label = 'Islandwide';
    } else if (scope == 'EXPLICIT_BRANCH') {
      icon = Icons.location_on_outlined;
      label = widget.offer.merchantLocation ?? 'In Store';
    } else if (scope == 'SELECTED_OUTLETS') {
      icon = Icons.storefront_outlined;
      label = 'Selected Outlets';
    } else {
      icon = Icons.storefront_outlined;
      label = widget.offer.merchantLocation ?? scope.replaceAll('_', ' ');
    }

    return _buildBadge(context, icon: icon, label: label, isDark: isDark);
  }

  static IconData _categoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('dining') || c.contains('food') || c.contains('restaurant')) {
      return Icons.restaurant_rounded;
    }
    if (c.contains('supermarket') || c.contains('grocery')) {
      return Icons.local_grocery_store_rounded;
    }
    if (c.contains('hotel') || c.contains('travel') || c.contains('resort')) {
      return Icons.hotel_rounded;
    }
    if (c.contains('fashion') || c.contains('clothing') || c.contains('apparel')) {
      return Icons.checkroom_rounded;
    }
    if (c.contains('fuel') || c.contains('auto')) {
      return Icons.local_gas_station_rounded;
    }
    if (c.contains('health') || c.contains('pharma') || c.contains('hospital')) {
      return Icons.local_hospital_rounded;
    }
    if (c.contains('tech') || c.contains('electron')) {
      return Icons.devices_rounded;
    }
    return Icons.local_offer_rounded;
  }
}
