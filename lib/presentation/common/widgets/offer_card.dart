import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../../domain/entities/validity_period.dart';
import '../../../domain/repositories/user_repository.dart';

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
    // Offers with no configured expiry must never be shown as "Expiring Soon"
    // regardless of what the sentinel date happens to compute to.
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
    // For known structural types, prefer description if the datasource already
    // populated it correctly (e.g. "20% off", "Up to 20%") rather than
    // synthesizing "${value}% off" which would produce "20.0% off" for doubles.
    if (type.contains('percentage')) {
      return discount.description.isNotEmpty ? discount.description : '${_fmtNum(discount.value)}% off';
    }
    if (type.contains('amount') || type.contains('fixed')) {
      return discount.description.isNotEmpty ? discount.description : 'LKR ${_fmtNum(discount.value)} off';
    }
    if (type.contains('cashback')) {
      return discount.description.isNotEmpty ? discount.description : '${_fmtNum(discount.value)}% cashback';
    }
    // 'text' type and everything else: description is the canonical wording.
    return discount.description.isNotEmpty ? discount.description : type;
  }

  static String _fmtNum(dynamic v) {
    if (v is double && v == v.truncate()) return v.toInt().toString();
    return v?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offer = widget.offer;
    final image =
        offer.featuredImage ??
        (offer.images.isNotEmpty ? offer.images.first : null);
    final expired = offer.validity.validUntil.isBefore(DateTime.now());
    return Semantics(
      button: true,
      label: '${offer.merchantName}, ${offer.title}, ${_benefit(l10n)}',
      child: Card(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: widget.compact ? 88 : 132,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (image != null && image.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const _OfferPlaceholder(),
                        placeholder: (_, __) => const _OfferPlaceholder(),
                      )
                    else
                      const _OfferPlaceholder(),
                    Positioned(
                      left: 12,
                      bottom: 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            _benefit(l10n),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: IconButton.filledTonal(
                        tooltip: _saved ? l10n.offerUnsaved : l10n.saveOffer,
                        onPressed: _toggleSaved,
                        icon: Icon(
                          _saved ? Icons.bookmark : Icons.bookmark_outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.merchantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (expired || _expiringSoon)
                          Chip(
                            label: Text(
                              expired
                                  ? l10n.text('expired')
                                  : l10n.text('expiringSoon'),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.account_balance, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            offer.bankName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.applicableCards.isNotEmpty
                          ? offer.applicableCards.map(_friendly).join(' • ')
                          : (offer.cardEligibility?.displaySummary ?? 'All Cards'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (offer.cardEligibility != null && offer.cardEligibility!.hasExclusions)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Excludes: ${offer.cardEligibility!.excludedCards.join(', ')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${offer.category} • ${_expiryText(offer.validity.validUntil)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        if (_locationTag(context, offer.locationScope, offer.locations) != null) ...[
                          const SizedBox(width: 6),
                          _locationTag(context, offer.locationScope, offer.locations)!,
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _locationTag(BuildContext context, String? scope, List<dynamic> locs) {
    if (scope == 'ONLINE') {
      return _scopeChip(Icons.language, 'Online', Colors.teal);
    }
    if (scope == 'NATIONWIDE') {
      return _scopeChip(Icons.public, 'Islandwide', Colors.indigo);
    }
    if (locs.isNotEmpty) {
      final validLocs = locs.where((l) => l.latitude != 0 && l.longitude != 0).toList();
      if (validLocs.isNotEmpty) {
        return _scopeChip(
          Icons.location_on_outlined,
          validLocs.length == 1
              ? (validLocs.first.name.isNotEmpty ? validLocs.first.name : '1 branch')
              : '${validLocs.length} branches',
          Colors.green.shade800,
        );
      }
    }
    if (scope == 'SELECTED_OUTLETS') {
      return _scopeChip(Icons.storefront_outlined, 'Selected outlets', Colors.orange.shade900);
    }
    return null;
  }

  Widget _scopeChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _friendly(String value) => value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
      .join(' ');

  String _expiryText(DateTime date) {
    if (date.isAtSameMomentAs(ValidityPeriod.noExpirySentinel)) return 'Ongoing';
    final days = date.difference(DateTime.now()).inDays;
    final formattedDate = '${date.day} ${_monthName(date.month)} ${date.year}';
    if (days < 0) return 'Expired';
    if (days == 0) return 'Expires today';
    if (days <= 7) return 'Expires in $days days ($formattedDate)';
    return 'Valid until $formattedDate';
  }

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }
}

class _OfferPlaceholder extends StatelessWidget {
  const _OfferPlaceholder();
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Center(
      child: Icon(
        Icons.account_balance,
        size: 40,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
