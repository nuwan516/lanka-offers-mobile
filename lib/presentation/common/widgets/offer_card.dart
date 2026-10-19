import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/semantics/offer_semantics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../../domain/repositories/user_repository.dart';
import 'bank_badge.dart';
import 'offer_presentation.dart';

/// One offer in a list. Tapping opens the detail pager over [contextOffers].
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

  void _open() {
    final offers = widget.contextOffers;
    context.push(
      '/offer/${widget.offer.uniqueId}',
      extra: {
        'offers': offers ?? [widget.offer],
        'initialIndex':
            widget.initialIndex ??
            (offers != null ? offers.indexOf(widget.offer) : 0),
      },
    );
  }

  static String _distance(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final offer = widget.offer;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final benefit = OfferPresentation.benefit(l10n, offer);
    final validity = OfferPresentation.validity(l10n, offer.validity);
    final expired = OfferSemantics.isExpired(offer.validity);
    final location = offerLocationLabel(l10n, offer);
    final merchant =
        offer.merchantName.isNotEmpty ? offer.merchantName : offer.title;
    final pad = widget.compact ? 12.0 : 16.0;

    final cardTypes =
        offer.applicableCards.where((c) {
          final l = c.toLowerCase();
          return l.contains('credit') || l.contains('debit');
        }).toList();

    return Semantics(
      button: true,
      label: [
        merchant,
        offer.title,
        if (benefit != null) benefit,
        validity.text,
      ].join(', '),
      child: Opacity(
        opacity: expired ? 0.7 : 1,
        child: Card(
          margin: EdgeInsets.only(bottom: widget.compact ? 8 : 12),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: InkWell(
            onTap: _open,
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child:
                            offer.bankName.isNotEmpty
                                ? BankBadge(
                                  bankName: offer.bankCode ?? offer.bankName,
                                )
                                : const SizedBox.shrink(),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        tooltip: _saved ? l10n.offerUnsaved : l10n.saveOffer,
                        onPressed: _toggleSaved,
                        icon: Icon(
                          _saved ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: _saved ? AppColors.error : secondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    merchant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      color: secondary,
                    ),
                  ),
                  if (benefit != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      benefit,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (offer.distanceKm != null &&
                          OfferSemantics.hasConfirmedBranch(offer))
                        _meta(
                          Icons.near_me_outlined,
                          _distance(offer.distanceKm!),
                          secondary,
                          bold: true,
                        )
                      else if (location != null)
                        _meta(
                          offer.locationScope == 'ONLINE'
                              ? Icons.language
                              : Icons.place_outlined,
                          location,
                          secondary,
                        ),
                      if (cardTypes.isNotEmpty)
                        _meta(
                          Icons.credit_card_outlined,
                          cardTypes.join(' · '),
                          secondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    validity.text,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          validity.tone == ValidityTone.neutral
                              ? FontWeight.w400
                              : FontWeight.w600,
                      color: validity.color(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text, Color color, {bool bold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: color,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
