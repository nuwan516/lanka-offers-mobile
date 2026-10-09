import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/phase_two_survey_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/entities/validity_period.dart';
import '../../../domain/repositories/offer_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../common/widgets/bank_badge.dart';

class OfferDetailScreen extends StatefulWidget {
  const OfferDetailScreen({
    super.key,
    required this.offerId,
    this.contextOffers,
    this.initialIndex,
  });

  final String offerId;
  final List<BankOffer>? contextOffers;
  final int? initialIndex;

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late List<BankOffer> _offers;
  bool _isLoadingSingle = false;
  final Set<String> _savedOfferIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.contextOffers != null && widget.contextOffers!.isNotEmpty) {
      _offers = List<BankOffer>.from(widget.contextOffers!);
      final idx = widget.initialIndex ??
          _offers.indexWhere((o) => o.uniqueId == widget.offerId);
      _currentIndex = idx >= 0 ? idx : 0;
      _pageController = PageController(initialPage: _currentIndex);
      _checkSavedStatus(_offers[_currentIndex].uniqueId);
      _recordView();
    } else {
      _offers = [];
      _currentIndex = 0;
      _pageController = PageController();
      _loadSingleOffer();
    }
  }

  @override
  void didUpdateWidget(OfferDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offerId != widget.offerId ||
        oldWidget.contextOffers != widget.contextOffers) {
      if (widget.contextOffers != null && widget.contextOffers!.isNotEmpty) {
        _offers = List<BankOffer>.from(widget.contextOffers!);
        final idx = widget.initialIndex ??
            _offers.indexWhere((o) => o.uniqueId == widget.offerId);
        _currentIndex = idx >= 0 ? idx : 0;
        _pageController.dispose();
        _pageController = PageController(initialPage: _currentIndex);
        _checkSavedStatus(_offers[_currentIndex].uniqueId);
      } else {
        _offers = [];
        _currentIndex = 0;
        _loadSingleOffer();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _recordView() async {
    try {
      await getIt<PhaseTwoSurveyService>().recordOfferViewed();
    } catch (_) {}
  }

  Future<void> _checkSavedStatus(String id) async {
    try {
      final saved = await getIt<UserRepository>().isOfferSaved(id);
      if (mounted) {
        setState(() {
          if (saved) {
            _savedOfferIds.add(id);
          } else {
            _savedOfferIds.remove(id);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSingleOffer() async {
    setState(() => _isLoadingSingle = true);
    await _recordView();
    try {
      final saved = await getIt<UserRepository>().isOfferSaved(widget.offerId);
      final value = await getIt<OfferRepository>().getOfferById(widget.offerId);
      if (mounted) {
        setState(() {
          _isLoadingSingle = false;
          if (saved) _savedOfferIds.add(widget.offerId);
          if (value is BankOffer) {
            _offers = [value];
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSingle = false);
    }
  }

  Future<void> _toggleSaved(BankOffer offer) async {
    final isSaved = _savedOfferIds.contains(offer.uniqueId);
    if (isSaved) {
      await getIt<UserRepository>().unsaveOffer(offer.uniqueId);
      setState(() => _savedOfferIds.remove(offer.uniqueId));
    } else {
      await getIt<UserRepository>().saveOffer(offer.uniqueId);
      setState(() => _savedOfferIds.add(offer.uniqueId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoadingSingle) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.offerDetails)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_offers.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.offerDetails)),
        body: Center(child: Text(l10n.text('noOffers'))),
      );
    }

    final hasMultiple = _offers.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.offerDetails, style: const TextStyle(fontSize: 18)),
            if (hasMultiple)
              Text(
                'Offer ${_currentIndex + 1} of ${_offers.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.share,
            onPressed: () {
              final cur = _offers[_currentIndex];
              Share.share('${cur.merchantName}: ${cur.title}');
            },
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: PageView.builder(
        key: const ValueKey('offer_detail_page_view'),
        controller: _pageController,
        itemCount: _offers.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          _checkSavedStatus(_offers[index].uniqueId);
        },
        itemBuilder: (context, index) {
          final offer = _offers[index];
          final isSaved = _savedOfferIds.contains(offer.uniqueId);
          return _OfferDetailContent(
            offer: offer,
            isSaved: isSaved,
            onToggleSaved: () => _toggleSaved(offer),
          );
        },
      ),
    );
  }
}

class _OfferDetailContent extends StatelessWidget {
  const _OfferDetailContent({
    required this.offer,
    required this.isSaved,
    required this.onToggleSaved,
  });

  final BankOffer offer;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  static final _currencyFormat = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expired = offer.validity.validUntil.isBefore(DateTime.now());
    final image = offer.featuredImage ??
        (offer.images.isNotEmpty ? offer.images.first : null);

    final physicalLocations = offer.locations.where(_validCoordinates).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Hero Image
        SizedBox(
          height: 220,
          child: image == null || image.isEmpty
              ? const _DetailPlaceholder()
              : CachedNetworkImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const _DetailPlaceholder(),
                ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // High-Energy Deal Banner (Temu-Inspired)
              Builder(
                builder: (context) {
                  final daysLeft = offer.validity.validUntil.difference(DateTime.now()).inDays;
                  final isEndingSoon = !expired &&
                      !offer.validity.hasNoConfiguredExpiry &&
                      daysLeft >= 0 &&
                      daysLeft <= 7;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroRedGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.redGlowShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: AppColors.flashYellow,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer.getDisplayValue(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'VERIFIED BANK DISCOUNT',
                                style: TextStyle(
                                  color: AppColors.secondarySoft,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (expired)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.text('expired').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        else if (isEndingSoon)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.yellowFlashGradient,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: AppColors.yellowGlowShadow,
                            ),
                            child: Text(
                              '${daysLeft == 0 ? "ENDS TODAY" : "$daysLeft DAYS LEFT"} 🔥',
                              style: const TextStyle(
                                color: Color(0xFF8B1010),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              // Merchant & Offer Title
              Text(
                offer.merchantName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              if (offer.bankName.isNotEmpty)
                BankBadge(bankName: offer.bankName),
              const SizedBox(height: 6),
              Text(
                offer.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),

              const Divider(height: 28),

              // Bank & Card Eligibility Section
              _SectionHeading(title: 'Bank & Card Eligibility'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.account_balance,
                      label: l10n.bank,
                      value: offer.bankName,
                    ),
                    const Divider(height: 16),
                    _InfoRow(
                      icon: Icons.credit_card,
                      label: l10n.text('eligibleCards'),
                      value: offer.applicableCards.isNotEmpty
                          ? offer.applicableCards.map(_friendly).join(', ')
                          : (offer.cardEligibility?.displaySummary ?? 'All Cardholders'),
                    ),
                    if (offer.cardEligibility != null && offer.cardEligibility!.hasExclusions) ...[
                      const Divider(height: 16),
                      _InfoRow(
                        icon: Icons.block,
                        label: 'Excluded Cards',
                        value: offer.cardEligibility!.excludedCards.join(', '),
                        valueColor: Colors.red.shade700,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Validity & Spend Limits
              _SectionHeading(title: 'Offer Validity & Terms'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.validUntil,
                      value: _formatValidity(offer.validity),
                    ),
                    if (offer.validity.daysApplicable != null) ...[
                      const Divider(height: 16),
                      _InfoRow(
                        icon: Icons.today,
                        label: 'Applicable Days',
                        value: offer.validity.daysApplicable!,
                      ),
                    ],
                    if (offer.validity.timeRestrictions != null) ...[
                      const Divider(height: 16),
                      _InfoRow(
                        icon: Icons.schedule,
                        label: 'Applicable Times',
                        value: offer.validity.timeRestrictions!,
                      ),
                    ],
                    if (offer.minTransaction != null || offer.maxTransaction != null) ...[
                      const Divider(height: 16),
                      _InfoRow(
                        icon: Icons.payments_outlined,
                        label: 'Transaction Spend Limit',
                        value: _formatSpendLimit(offer.minTransaction, offer.maxTransaction),
                      ),
                    ],
                    const Divider(height: 16),
                    _InfoRow(
                      icon: Icons.category_outlined,
                      label: l10n.category,
                      value: offer.category,
                    ),
                  ],
                ),
              ),

              // Description
              if (offer.description.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionHeading(title: 'Details'),
                const SizedBox(height: 8),
                Text(
                  offer.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ],

              // Installment Plans
              if (offer.installmentPlans?.isNotEmpty ?? false) ...[
                const SizedBox(height: 20),
                _SectionHeading(title: 'Installment Plans'),
                const SizedBox(height: 8),
                for (final plan in offer.installmentPlans!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(plan.description)),
                      ],
                    ),
                  ),
              ],

              // Key Conditions
              if (offer.restrictions != null &&
                  offer.restrictions!.keyRestrictions.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionHeading(title: l10n.termsAndConditions),
                const SizedBox(height: 8),
                if (offer.restrictions!.bookingRequired != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Booking required: ${offer.restrictions!.bookingRequired! ? 'Yes' : 'No'}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                for (final item in offer.restrictions!.keyRestrictions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
              ],

              // Location Applicability
              const SizedBox(height: 24),
              _SectionHeading(title: 'Where You Can Use It'),
              const SizedBox(height: 8),
              if (offer.locationScope != null)
                _LocationScopeBadge(scope: offer.locationScope!),

              // Embedded OpenStreetMap for confirmed physical locations
              if (physicalLocations.isNotEmpty &&
                  offer.locationScope != 'ONLINE' &&
                  offer.locationScope != 'NATIONWIDE') ...[
                const SizedBox(height: 12),
                _OfferLocationMap(
                  locations: physicalLocations,
                  merchantName: offer.merchantName,
                ),
                const SizedBox(height: 12),
                Text(
                  'Confirmed Branches (${physicalLocations.length})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                for (final location in physicalLocations)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (location.address.isNotEmpty)
                                Text(
                                  location.address,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.getDirections,
                          icon: const Icon(Icons.directions_outlined),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () => _openDirections(location),
                        ),
                      ],
                    ),
                  ),
              ],

              // Contact & Official Source
              if (offer.contact != null) ...[
                const SizedBox(height: 20),
                _SectionHeading(title: l10n.contactInfo),
                const SizedBox(height: 8),
                if (offer.contact!.phone?.isNotEmpty ?? false)
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: l10n.phone,
                    value: offer.contact!.phone!.join(', '),
                  ),
                if (offer.contact!.website != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.open_in_new),
                    title: Text(l10n.text('offerInformation')),
                    subtitle: Text(
                      offer.contact!.website!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => launchUrl(
                      Uri.parse(offer.contact!.website!),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
              ],

              const SizedBox(height: 24),

              // Action Buttons Row (Save + Claim/Redeem)
              Row(
                children: [
                  // Save Button
                  InkWell(
                    onTap: onToggleSaved,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSaved
                            ? AppColors.primary
                            : (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.surfaceVariant),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSaved
                              ? AppColors.secondary
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkBorder
                                  : AppColors.border),
                          width: isSaved ? 1.5 : 1,
                        ),
                        boxShadow: isSaved ? AppColors.redGlowShadow : null,
                      ),
                      child: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: isSaved ? AppColors.flashYellow : Theme.of(context).colorScheme.onSurface,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Primary CTA Button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppColors.redGlowShadow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            if (offer.contact?.website != null) {
                              launchUrl(
                                Uri.parse(offer.contact!.website!),
                                mode: LaunchMode.externalApplication,
                              );
                            } else if (physicalLocations.isNotEmpty) {
                              _openDirections(physicalLocations.first);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Offer active at ${offer.merchantName} with ${offer.bankName} cards!'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.bolt_rounded,
                                  color: AppColors.flashYellow,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  offer.contact?.website != null
                                      ? 'VISIT WEBSITE'
                                      : (physicalLocations.isNotEmpty ? 'GET DIRECTIONS' : 'HOW TO CLAIM'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static bool _validCoordinates(Location location) =>
      location.latitude >= -90 &&
      location.latitude <= 90 &&
      location.longitude >= -180 &&
      location.longitude <= 180 &&
      !(location.latitude == 0 && location.longitude == 0);

  static Future<void> _openDirections(Location location) => launchUrl(
        Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}',
        ),
        mode: LaunchMode.externalApplication,
      );

  static String _friendly(String value) =>
      value.replaceAll('_', ' ').toUpperCase();

  static String _formatValidity(ValidityPeriod validity) {
    if (validity.validUntil.isAtSameMomentAs(ValidityPeriod.noExpirySentinel)) {
      return 'No expiry date set by bank';
    }
    final formatter = DateFormat('d MMM yyyy');
    if (!validity.validFrom.isAtSameMomentAs(ValidityPeriod.unknownStartSentinel) &&
        validity.validFrom.isBefore(validity.validUntil)) {
      return '${formatter.format(validity.validFrom)} – ${formatter.format(validity.validUntil)}';
    }
    return 'Valid until ${formatter.format(validity.validUntil)}';
  }

  static String _formatSpendLimit(double? min, double? max) {
    if (min != null && max != null) {
      return 'LKR ${_currencyFormat.format(min)} – LKR ${_currencyFormat.format(max)}';
    } else if (min != null) {
      return 'Min: LKR ${_currencyFormat.format(min)}';
    } else if (max != null) {
      return 'Max: LKR ${_currencyFormat.format(max)}';
    }
    return 'None';
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailPlaceholder extends StatelessWidget {
  const _DetailPlaceholder();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFFFF1F2), const Color(0xFFFEE2E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.primaryLight : AppColors.primary)
                .withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.local_offer_rounded,
            size: 40,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _LocationScopeBadge extends StatelessWidget {
  final String scope;
  const _LocationScopeBadge({required this.scope});

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    Color color;

    switch (scope) {
      case 'ONLINE':
        label = 'Online Promotion • Valid on website and mobile app';
        icon = Icons.language;
        color = Colors.teal;
        break;
      case 'NATIONWIDE':
        label = 'Islandwide • Valid across all merchant outlets islandwide';
        icon = Icons.public;
        color = Colors.indigo;
        break;
      case 'SELECTED_OUTLETS':
        label = 'Selected Outlets • Check terms or contact merchant for participating branches';
        icon = Icons.storefront_outlined;
        color = Colors.amber.shade900;
        break;
      case 'DISTRICT_REGION':
        label = 'Regional Offer • Valid in specific district/region';
        icon = Icons.map_outlined;
        color = Colors.blue;
        break;
      case 'EXPLICIT_BRANCH':
      case 'MULTIPLE_BRANCHES':
        label = 'Branch Specific • Valid at listed physical branches';
        icon = Icons.location_on_outlined;
        color = Colors.green.shade800;
        break;
      default:
        label = 'Branch applicability not specified by bank';
        icon = Icons.info_outline;
        color = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferLocationMap extends StatelessWidget {
  const _OfferLocationMap({
    required this.locations,
    required this.merchantName,
  });

  final List<Location> locations;
  final String merchantName;

  @override
  Widget build(BuildContext context) {
    final first = locations.first;
    final initialCenter = LatLng(first.latitude, first.longitude);

    final markers = locations.map((loc) {
      return Marker(
        point: LatLng(loc.latitude, loc.longitude),
        width: 36,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.place,
            size: 20,
            color: Colors.white,
          ),
        ),
      );
    }).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 13,
            minZoom: 5,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.lanka_offers',
              maxZoom: 19,
              errorTileCallback: (tile, error, stackTrace) {},
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}
