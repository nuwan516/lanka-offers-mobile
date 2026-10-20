import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/semantics/offer_semantics.dart';
import '../../../core/services/phase_two_survey_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/bank_offer.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/repositories/offer_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../common/widgets/bank_badge.dart';
import '../../common/widgets/offer_presentation.dart';
import '../../common/widgets/state_views.dart';

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
  bool _singleFailed = false;
  final Set<String> _savedOfferIds = {};

  /// List endpoints return summaries; terms and transaction limits only exist
  /// on the detail endpoint, so the visible page loads it on demand.
  final Map<String, BankOffer> _full = {};
  final Set<String> _fetching = {};

  @override
  void initState() {
    super.initState();
    _setUp();
  }

  void _setUp() {
    final context = widget.contextOffers;
    if (context != null && context.isNotEmpty) {
      _offers = List<BankOffer>.from(context);
      final idx =
          widget.initialIndex ??
          _offers.indexWhere((o) => o.uniqueId == widget.offerId);
      _currentIndex = idx >= 0 ? idx : 0;
      _pageController = PageController(initialPage: _currentIndex);
      _checkSavedStatus(_offers[_currentIndex].uniqueId);
      _ensureFull(_offers[_currentIndex]);
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
      _pageController.dispose();
      _setUp();
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
          saved ? _savedOfferIds.add(id) : _savedOfferIds.remove(id);
        });
      }
    } catch (_) {}
  }

  Future<void> _ensureFull(BankOffer offer) async {
    final id = offer.uniqueId;
    if (_full.containsKey(id) || !_fetching.add(id)) return;
    try {
      final value = await getIt<OfferRepository>().getOfferById(id);
      if (mounted && value is BankOffer) setState(() => _full[id] = value);
    } catch (_) {
      // The summary stays on screen; the section that needs the detail simply
      // shows what the summary has.
    } finally {
      _fetching.remove(id);
    }
  }

  Future<void> _loadSingleOffer() async {
    setState(() {
      _isLoadingSingle = true;
      _singleFailed = false;
    });
    await _recordView();
    try {
      final saved = await getIt<UserRepository>().isOfferSaved(widget.offerId);
      final value = await getIt<OfferRepository>().getOfferById(widget.offerId);
      if (!mounted) return;
      setState(() {
        _isLoadingSingle = false;
        if (saved) _savedOfferIds.add(widget.offerId);
        if (value is BankOffer) {
          _offers = [value];
          _full[value.uniqueId] = value;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingSingle = false;
          _singleFailed = true;
        });
      }
    }
  }

  Future<void> _toggleSaved(BankOffer offer) async {
    final repo = getIt<UserRepository>();
    if (_savedOfferIds.contains(offer.uniqueId)) {
      await repo.unsaveOffer(offer.uniqueId);
      if (mounted) setState(() => _savedOfferIds.remove(offer.uniqueId));
    } else {
      await repo.saveOffer(offer.uniqueId);
      if (mounted) setState(() => _savedOfferIds.add(offer.uniqueId));
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
        body:
            _singleFailed
                ? LoadFailedView(onRetry: _loadSingleOffer)
                : StateMessage(
                  icon: Icons.search_off_rounded,
                  title: l10n.text('noOffers'),
                ),
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
                l10n.format('offerPosition', {
                  'current': _currentIndex + 1,
                  'total': _offers.length,
                }),
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
          _ensureFull(_offers[index]);
        },
        itemBuilder: (context, index) {
          final summary = _offers[index];
          final offer = _full[summary.uniqueId] ?? summary;
          return OfferDetailContent(
            offer: offer,
            isSaved: _savedOfferIds.contains(offer.uniqueId),
            onToggleSaved: () => _toggleSaved(offer),
          );
        },
      ),
    );
  }
}

/// The body of one offer. Every figure shown comes from the source data: the
/// discount keeps the bank's wording, spend limits keep their exact meaning,
/// and anything the source did not state is shown as not specified.
class OfferDetailContent extends StatelessWidget {
  const OfferDetailContent({
    super.key,
    required this.offer,
    required this.isSaved,
    required this.onToggleSaved,
    this.now,
  });

  final BankOffer offer;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  /// Overridable for tests.
  final DateTime? now;

  static final _currency = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final expired = OfferSemantics.isExpired(offer.validity, now: now);
    final validity = OfferPresentation.validity(l10n, offer.validity, now: now);
    final benefit = OfferPresentation.benefit(l10n, offer);
    final branches =
        OfferSemantics.confirmedBranches(
          offer,
        ).where(_validCoordinates).toList();
    final pinnable = branches.isNotEmpty && OfferSemantics.canShowOnMap(offer);
    final areaOnly =
        offer.locations.isNotEmpty &&
        OfferSemantics.confirmedBranches(offer).isEmpty &&
        offer.locationScope != 'ONLINE' &&
        offer.locationScope != 'NATIONWIDE';
    final terms = offer.generalTerms;
    final statedLimits = [
      ...OfferSemantics.minSpendStatements(terms),
      ...OfferSemantics.capStatements(terms),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
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
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BankBadge(bankName: offer.bankCode ?? offer.bankName),
                ],
              ),
            ),
            IconButton(
              tooltip: isSaved ? l10n.offerUnsaved : l10n.saveOffer,
              onPressed: onToggleSaved,
              icon: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? AppColors.error : secondary,
              ),
            ),
          ],
        ),
        if (expired) ...[
          const SizedBox(height: 12),
          _Notice(
            icon: Icons.event_busy_outlined,
            text: l10n.text('offerExpiredNotice'),
            color: AppColors.error,
          ),
        ],
        if (benefit != null) ...[
          const SizedBox(height: 16),
          Text(
            benefit,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.text('detailDiscountNote'),
            style: TextStyle(color: secondary, fontSize: 12.5, height: 1.4),
          ),
        ],
        const SizedBox(height: 12),
        Text(offer.title, style: TextStyle(color: secondary, height: 1.4)),

        _Section(
          title: l10n.validUntil,
          child: Text(
            validity.text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: validity.color(isDark),
            ),
          ),
        ),

        _Section(
          title: l10n.text('detailEligibility'),
          child: _eligibility(l10n, secondary),
        ),

        if (offer.minTransaction != null ||
            offer.maxTransaction != null ||
            statedLimits.isNotEmpty)
          _Section(
            title: l10n.text('detailTerms'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (offer.minTransaction != null)
                  _Fact(
                    l10n.text('detailMinTransaction'),
                    'LKR ${_currency.format(offer.minTransaction)}',
                  ),
                if (offer.maxTransaction != null)
                  _Fact(
                    l10n.text('detailMaxTransaction'),
                    'LKR ${_currency.format(offer.maxTransaction)}',
                  ),
                if (statedLimits.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.text('detailFromTerms'),
                    style: TextStyle(color: secondary, fontSize: 12.5),
                  ),
                  for (final line in statedLimits) _Bullet('“$line”'),
                ],
              ],
            ),
          ),

        _Section(
          title: l10n.text('detailWhereApplies'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _scopeLabel(l10n),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (offer.merchantLocation != null &&
                  offer.locationScope != 'ONLINE' &&
                  offer.locationScope != 'NATIONWIDE') ...[
                const SizedBox(height: 4),
                Text(
                  offer.merchantLocation!,
                  style: TextStyle(color: secondary, height: 1.4),
                ),
              ],
              if (areaOnly) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.text('detailAreaOnly'),
                  style: TextStyle(color: secondary, height: 1.4),
                ),
              ],
              if (pinnable) ...[
                const SizedBox(height: 12),
                _OfferLocationMap(
                  locations: branches,
                  merchantName: offer.merchantName,
                ),
                for (final loc in offer.locations
                    .where(_validCoordinates)
                    .take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(
                      loc.name.isNotEmpty ? loc.name : offer.merchantName,
                    ),
                    subtitle: loc.address.isNotEmpty ? Text(loc.address) : null,
                    trailing: IconButton(
                      tooltip: l10n.getDirections,
                      icon: const Icon(Icons.directions_outlined),
                      onPressed: () => _openDirections(loc),
                    ),
                  ),
              ],
            ],
          ),
        ),

        if (terms.isNotEmpty || (offer.terms?.isNotEmpty ?? false))
          _Section(
            title: l10n.termsAndConditions,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final t in terms) _Bullet(t),
                if (offer.terms != null && offer.terms!.isNotEmpty)
                  Text(offer.terms!, style: const TextStyle(height: 1.45)),
              ],
            ),
          ),

        if (_safeUrl(offer.sourceUrl) != null) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed:
                () => launchUrl(
                  _safeUrl(offer.sourceUrl)!,
                  mode: LaunchMode.externalApplication,
                ),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(l10n.text('detailViewSource')),
          ),
        ],
      ],
    );
  }

  Widget _eligibility(AppLocalizations l10n, Color secondary) {
    final e = offer.cardEligibility;
    final chips =
        <String>{
          if (e != null) ...e.includedCards,
          if (e != null) ...e.cardTypes,
          if (e != null) ...e.networks,
          if (e == null || e.isEmpty) ...offer.applicableCards,
        }.toList();

    if (chips.isEmpty && (e == null || e.restrictions.isEmpty)) {
      return Text(
        l10n.text('detailEligibilityUnknown'),
        style: TextStyle(color: secondary, height: 1.4),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chips.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final c in chips) Chip(label: Text(c))],
          ),
        if (e != null && e.excludedCards.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final c in e.excludedCards) _Bullet('✕ $c'),
        ],
        if (e != null) ...[for (final r in e.restrictions) _Bullet(r)],
      ],
    );
  }

  String _scopeLabel(AppLocalizations l10n) => switch (offer.locationScope) {
    'ONLINE' => l10n.text('detailScopeOnline'),
    'NATIONWIDE' => l10n.text('detailScopeNationwide'),
    'SELECTED_OUTLETS' => l10n.text('detailScopeSelected'),
    'EXPLICIT_BRANCH' || 'MULTIPLE_BRANCHES' =>
      OfferSemantics.confirmedBranches(offer).isNotEmpty
          ? l10n.text('detailScopeBranch')
          : l10n.text('detailScopeUnresolved'),
    _ => l10n.text('detailScopeUnresolved'),
  };

  static Uri? _safeUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return null;
    }
    return uri;
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
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFeatures: AppTextStyles.tabularFeatures,
          ),
        ),
      ],
    ),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  '),
        Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(color: color, height: 1.35)),
        ),
      ],
    ),
  );
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
    final markers = [
      for (final loc in locations)
        Marker(
          point: LatLng(loc.latitude, loc.longitude),
          width: 36,
          height: 36,
          child: Semantics(
            label: merchantName,
            child: Icon(
              Icons.location_on,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 180,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(first.latitude, first.longitude),
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
              userAgentPackageName: 'com.lankalk.offers',
              maxZoom: 19,
              errorTileCallback: (tile, error, stackTrace) {},
            ),
            MarkerLayer(markers: markers),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
