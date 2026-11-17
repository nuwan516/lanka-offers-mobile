import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/semantics/offer_semantics.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/pressable.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../../domain/repositories/user_repository.dart';
import 'bank_badge.dart';
import 'offer_image.dart';
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
    HapticFeedback.selectionClick();
    final repository = getIt<UserRepository>();
    _saved
        ? await repository.unsaveOffer(widget.offer.uniqueId)
        : await repository.saveOffer(widget.offer.uniqueId);
    if (mounted) setState(() => _saved = !_saved);
  }

  void _open() {
    HapticFeedback.lightImpact();
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
    final palette = context.palette;
    final offer = widget.offer;
    final benefit = OfferPresentation.benefit(l10n, offer);
    final validity = OfferPresentation.validity(l10n, offer.validity);
    final expired = OfferSemantics.isExpired(offer.validity);
    final location = offerLocationLabel(l10n, offer);
    final merchant =
        offer.merchantName.isNotEmpty ? offer.merchantName : offer.title;
    final imageUrl = offer.featuredImage ?? offer.images.firstOrNull;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final pad = widget.compact ? 12.0 : 16.0;

    final cardTypes =
        offer.applicableCards.where((c) {
          final l = c.toLowerCase();
          return l.contains('credit') || l.contains('debit');
        }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: widget.compact ? 8 : 12),
      child: Semantics(
        button: true,
        label: [
          merchant,
          offer.title,
          if (benefit != null) benefit,
          validity.text,
        ].join(', '),
        child: Opacity(
          opacity: expired ? 0.72 : 1,
          child: Pressable(
            onTap: _open,
            haptic: false,
            child: Material(
              color: palette.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.lg),
                side: BorderSide(color: palette.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImage)
                    OfferImage(
                      imageUrl: imageUrl,
                      semanticLabel: '$merchant promotion image',
                    ),
                  Padding(
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
                                        bankName:
                                            offer.bankCode ?? offer.bankName,
                                      )
                                      : const SizedBox.shrink(),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              tooltip:
                                  _saved ? l10n.offerUnsaved : l10n.saveOffer,
                              onPressed: _toggleSaved,
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: Icon(
                                  _saved
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  key: ValueKey(_saved),
                                  color:
                                      _saved ? palette.negative : palette.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          merchant,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offer.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.muted,
                            height: 1.35,
                          ),
                        ),
                        if (benefit != null) ...[
                          const SizedBox(height: 10),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: palette.benefitBg,
                              borderRadius: BorderRadius.circular(Radii.md),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                benefit,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: palette.benefitFg,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: AppTextStyles.tabularFeatures,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (offer.distanceKm != null &&
                                OfferSemantics.hasConfirmedBranch(offer))
                              _meta(
                                Icons.near_me_outlined,
                                _distance(offer.distanceKm!),
                                palette.muted,
                                bold: true,
                              )
                            else if (location != null)
                              _meta(
                                offer.locationScope == 'ONLINE'
                                    ? Icons.language
                                    : Icons.place_outlined,
                                location,
                                palette.muted,
                              ),
                            if (cardTypes.isNotEmpty)
                              _meta(
                                Icons.credit_card_outlined,
                                cardTypes.join(' · '),
                                palette.muted,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          validity.text,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight:
                                validity.tone == ValidityTone.neutral
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                            color: validity.color(
                              theme.brightness == Brightness.dark,
                            ),
                          ),
                        ),
                      ],
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
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
