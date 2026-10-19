import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/semantics/offer_semantics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/bank_offer.dart';
import '../../../common/widgets/offer_card.dart';
import '../cubit/nearby_cubit.dart';

/// Map of offers that have confirmed branch coordinates. Every pin is a
/// location the source gave; nothing is approximated or inferred.
class NearbyMap extends StatefulWidget {
  const NearbyMap({super.key, required this.place, required this.offers});

  final NearbyPlace place;
  final List<BankOffer> offers;

  @override
  State<NearbyMap> createState() => _NearbyMapState();
}

class _NearbyMapState extends State<NearbyMap> {
  BankOffer? _selected;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.place.latitude, widget.place.longitude);
    final markers = <Marker>[
      Marker(
        point: center,
        width: 28,
        height: 28,
        child: Semantics(
          label: widget.place.isDevice ? 'Your location' : widget.place.name,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.info,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      ),
      for (final offer in widget.offers)
        for (final loc in OfferSemantics.confirmedBranches(offer))
          Marker(
            point: LatLng(loc.latitude, loc.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => setState(() => _selected = offer),
              child: Semantics(
                button: true,
                label: offer.merchantName,
                child: Icon(
                  Icons.location_on,
                  size: 36,
                  color:
                      identical(offer, _selected)
                          ? AppColors.secondary
                          : AppColors.primary,
                ),
              ),
            ),
          ),
    ];

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12,
            minZoom: 6,
            maxZoom: 18,
            onTap: (_, __) => setState(() => _selected = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.lanka_offers',
              maxZoom: 19,
            ),
            MarkerLayer(markers: markers),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        if (_selected != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: OfferCard(
              offer: _selected!,
              compact: true,
              contextOffers: widget.offers,
              initialIndex: widget.offers.indexOf(_selected!),
            ),
          ),
      ],
    );
  }
}
