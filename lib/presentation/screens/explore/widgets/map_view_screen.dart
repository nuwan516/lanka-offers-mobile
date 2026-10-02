import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../domain/entities/location.dart';
import '../../../../domain/entities/shop_offer.dart';
import '../../../../domain/entities/bank_offer.dart';
import '../../../../domain/entities/promotion.dart';
import '../../../../domain/entities/event.dart';

class MapViewScreen extends StatefulWidget {
  final List<dynamic> offers;
  final double? userLatitude;
  final double? userLongitude;

  const MapViewScreen({
    required this.offers,
    this.userLatitude,
    this.userLongitude,
    super.key,
  });

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final MapController _mapController = MapController();
  dynamic _selectedOffer;
  Location? _selectedLocation;
  List<LatLng>? _routePoints;
  double _rangeKm = AppConstants.defaultRadiusKm;
  List<dynamic> _filteredOffers = [];

  @override
  void initState() {
    super.initState();
    _filterOffersByRange();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });
  }

  void _filterOffersByRange() {
    // Only physical offers with confirmed valid coordinates can appear on the map.
    // Explicitly exclude ONLINE, NATIONWIDE, UNRESOLVED, and non-geocoded scopes.
    final physicalOffers = widget.offers.where((offer) {
      if (offer is BankOffer) {
        if (offer.locationScope == 'ONLINE' ||
            offer.locationScope == 'NATIONWIDE' ||
            offer.locationScope == 'UNRESOLVED' ||
            offer.locationScope == 'SELECTED_OUTLETS') {
          return false;
        }
      }
      return offer.locations.any(
        (loc) =>
            loc.latitude >= -90 &&
            loc.latitude <= 90 &&
            loc.longitude >= -180 &&
            loc.longitude <= 180 &&
            !(loc.latitude == 0 && loc.longitude == 0),
      );
    }).toList();

    if (widget.userLatitude == null || widget.userLongitude == null) {
      _filteredOffers = physicalOffers;
      return;
    }

    final userLat = widget.userLatitude!;
    final userLon = widget.userLongitude!;

    _filteredOffers =
        physicalOffers.where((offer) {
          // Check if any confirmed physical location of the offer is within range
          for (final location in offer.locations) {
            if (location.latitude == 0 && location.longitude == 0) continue;
            final distance =
                Geolocator.distanceBetween(
                  userLat,
                  userLon,
                  location.latitude,
                  location.longitude,
                ) /
                1000; // Convert to km

            if (distance <= _rangeKm) {
              return true; // At least one location is within range
            }
          }
          return false;
        }).toList();
  }

  void _updateRange(double newRange) {
    setState(() {
      _rangeKm = newRange;
      _filterOffersByRange();
      _fitBounds();
    });
  }

  void _fitBounds() {
    if (_filteredOffers.isEmpty) {
      // If no offers in range, center on user location
      final userLat = widget.userLatitude ?? AppConstants.defaultLatitude;
      final userLon = widget.userLongitude ?? AppConstants.defaultLongitude;
      _mapController.move(LatLng(userLat, userLon), 12.0);
      return;
    }

    final points = <LatLng>[];

    final userLat = widget.userLatitude ?? AppConstants.defaultLatitude;
    final userLon = widget.userLongitude ?? AppConstants.defaultLongitude;
    points.add(LatLng(userLat, userLon));

    for (final offer in _filteredOffers) {
      for (final location in offer.locations) {
        points.add(LatLng(location.latitude, location.longitude));
      }
    }

    if (points.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  LatLng _getCenter() {
    if (_filteredOffers.isEmpty) {
      return LatLng(
        widget.userLatitude ?? AppConstants.defaultLatitude,
        widget.userLongitude ?? AppConstants.defaultLongitude,
      );
    }

    double totalLat = widget.userLatitude ?? AppConstants.defaultLatitude;
    double totalLon = widget.userLongitude ?? AppConstants.defaultLongitude;
    int count = 1;

    for (final offer in _filteredOffers) {
      for (final location in offer.locations) {
        totalLat += location.latitude;
        totalLon += location.longitude;
        count++;
      }
    }

    return LatLng(totalLat / count, totalLon / count);
  }

  List<CircleMarker<String>> _buildRangeCircle() {
    if (widget.userLatitude == null || widget.userLongitude == null) {
      return [];
    }

    return [
      CircleMarker<String>(
        point: LatLng(widget.userLatitude!, widget.userLongitude!),
        radius: _rangeKm * 1000, // Convert km to meters
        useRadiusInMeter: true,
        color: AppColors.primary.withOpacity(0.1),
        borderColor: AppColors.primary.withOpacity(0.3),
        borderStrokeWidth: 2,
      ),
    ];
  }

  Future<void> _showRoute(Location destination) async {
    final userLat = widget.userLatitude ?? AppConstants.defaultLatitude;
    final userLon = widget.userLongitude ?? AppConstants.defaultLongitude;

    try {
      // Use OSRM routing service for OpenStreetMap
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$userLon,$userLat;${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry']['coordinates'];
          final route = <LatLng>[];

          for (final coord in geometry) {
            // Handle both int and double types from API
            final lat =
                (coord[1] is int) ? coord[1].toDouble() : coord[1] as double;
            final lon =
                (coord[0] is int) ? coord[0].toDouble() : coord[0] as double;
            route.add(LatLng(lat, lon)); // Note: GeoJSON is [lon, lat]
          }

          if (mounted) {
            setState(() {
              _routePoints = route;
            });

            // Fit map to show route
            if (route.isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  try {
                    final points = [
                      LatLng(userLat, userLon),
                      LatLng(destination.latitude, destination.longitude),
                    ];
                    // Add route points to bounds for better view
                    for (final point in route) {
                      points.add(point);
                    }

                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(points),
                        padding: const EdgeInsets.all(80),
                      ),
                    );
                  } catch (e) {
                    debugPrint('Error fitting camera: $e');
                  }
                }
              });
            }
          }
        } else {
          debugPrint('Route calculation failed: ${data['code']}');
        }
      } else {
        debugPrint('Route API error: ${response.statusCode}');
      }
    } catch (e) {
      // If routing fails, just show the offer details
      debugPrint('Route calculation failed: $e');
    }
  }

  Map<String, dynamic> _getMarkerData(dynamic offer) {
    if (offer is BankOffer) {
      return {
        'icon': Icons.account_balance,
        'color': const Color(0xFF1E88E5), // Blue for bank
      };
    } else if (offer is ShopOffer) {
      return {
        'icon': Icons.store,
        'color': const Color(0xFF43A047), // Green for shop
      };
    } else if (offer is Promotion) {
      return {
        'icon': Icons.local_offer,
        'color': const Color(0xFFE91E63), // Pink for promotion
      };
    } else if (offer is Event) {
      return {
        'icon': Icons.event,
        'color': const Color(0xFF9C27B0), // Purple for event
      };
    }
    // Default
    return {'icon': Icons.place, 'color': AppColors.primary};
  }

  String _getDiscountDisplayValue(dynamic offer) {
    if (offer is BankOffer) {
      return offer.getDisplayValue();
    } else if (offer is ShopOffer) {
      return offer.getDisplayValue();
    } else if (offer is Promotion) {
      return offer.getDisplayValue();
    } else if (offer is Event) {
      return offer.getDisplayValue();
    }
    return '';
  }

  bool _hasPercentageDiscount(dynamic offer) {
    if (offer is ShopOffer) {
      return offer.discount.type == 'percentage';
    } else if (offer is BankOffer) {
      return offer.discount != null && offer.discount!.type == 'percentage';
    } else if (offer is Promotion) {
      return offer.deal.type == 'discount';
    }
    return false;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    final userLat = widget.userLatitude ?? AppConstants.defaultLatitude;
    final userLon = widget.userLongitude ?? AppConstants.defaultLongitude;

    // Add user location marker
    markers.add(
      Marker(
        point: LatLng(userLat, userLon),
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        ),
      ),
    );

    // Add offer location markers (only for filtered offers)
    for (final offer in _filteredOffers) {
      if (offer.locations.isEmpty) continue;

      for (final location in offer.locations) {
        if (location.latitude == 0 && location.longitude == 0) continue;
        if (location.latitude < -90 || location.latitude > 90 || location.longitude < -180 || location.longitude > 180) continue;

        // Check if this specific location is within range
        if (widget.userLatitude != null && widget.userLongitude != null) {
          final distance =
              Geolocator.distanceBetween(
                widget.userLatitude!,
                widget.userLongitude!,
                location.latitude,
                location.longitude,
              ) /
              1000; // Convert to km

          if (distance > _rangeKm) {
            continue; // Skip locations outside range
          }
        }

        final markerData = _getMarkerData(offer);
        markers.add(
          Marker(
            point: LatLng(location.latitude, location.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedOffer = offer;
                  _selectedLocation = location;
                  _routePoints = null;
                });
                _showRoute(location);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: markerData['color'] as Color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: (markerData['color'] as Color).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  markerData['icon'] as IconData,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.mapView),
        actions: [
          // Range selector button
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filter by range',
            onPressed: () => _showRangeSelector(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _getCenter(),
              initialZoom: 12,
              minZoom: 5,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (tapPosition, point) {
                // Clear selection when tapping on map
                if (_selectedOffer != null) {
                  setState(() {
                    _selectedOffer = null;
                    _selectedLocation = null;
                    _routePoints = null;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.lanka_offers',
                maxZoom: 19,
              ),
              // Range circle overlay
              if (widget.userLatitude != null && widget.userLongitude != null)
                CircleLayer<String>(circles: _buildRangeCircle()),
              if (_routePoints != null && _routePoints!.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints!,
                      strokeWidth: 4,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          if (_selectedOffer != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(20),
                shadowColor: Colors.black.withOpacity(0.2),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Offer Image and Close Button
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: Image.network(
                              _selectedOffer.featuredImage ??
                                  _selectedOffer.images.firstOrNull ??
                                  '',
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    height: 180,
                                    color: AppColors.surfaceVariant,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 48,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                            ),
                          ),
                          // Gradient overlay
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Close button
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedOffer = null;
                                    _selectedLocation = null;
                                    _routePoints = null;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ),
                          ),
                          // Discount badge
                          if (_hasPercentageDiscount(_selectedOffer))
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _getDiscountDisplayValue(_selectedOffer),
                                  style: AppTextStyles.captionMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title and Provider
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedOffer.title,
                                        style: AppTextStyles.h3,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.store_outlined,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              _selectedOffer.providerName,
                                              style: AppTextStyles.body2
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Location Details
                            if (_selectedLocation != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedLocation!.name,
                                            style: AppTextStyles.body2Medium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _selectedLocation!.address,
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      if (_selectedLocation != null) {
                                        _openInMaps(_selectedLocation!);
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.directions,
                                      size: 18,
                                    ),
                                    label: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.getDirections,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      side: BorderSide(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                 Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      final bankOffers =
                                          widget.offers.whereType<BankOffer>().toList();
                                      final bIndex = bankOffers.indexOf(_selectedOffer);
                                      context.push(
                                        '/offer/${_selectedOffer.uniqueId}',
                                        extra: {
                                          'offers':
                                              bankOffers.isNotEmpty ? bankOffers : null,
                                          'initialIndex': bIndex >= 0 ? bIndex : 0,
                                        },
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                    ),
                                    label: Text(
                                      AppLocalizations.of(context)!.viewDetails,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
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
                  ),
                ),
              ),
            ),
          // Range info card
          if (widget.userLatitude != null && widget.userLongitude != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_searching,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Showing offers within ${_rangeKm.toStringAsFixed(_rangeKm < 1 ? 1 : 0)} km (${_filteredOffers.length} found)',
                      style: AppTextStyles.captionMedium,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showRangeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter by Distance', style: AppTextStyles.h2),
                const SizedBox(height: 8),
                Text(
                  'Show offers within selected range',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                // Quick range buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildRangeButton('1 km', 1.0, context),
                    _buildRangeButton('5 km', 5.0, context),
                    _buildRangeButton('10 km', 10.0, context),
                    _buildRangeButton('25 km', 25.0, context),
                    _buildRangeButton('50 km', 50.0, context),
                  ],
                ),
                const SizedBox(height: 24),
                // Slider for custom range
                Text(
                  'Custom Range: ${_rangeKm.toStringAsFixed(1)} km',
                  style: AppTextStyles.body2Medium,
                ),
                const SizedBox(height: 12),
                Slider(
                  value: _rangeKm,
                  min: 1.0,
                  max: AppConstants.maxRadiusKm,
                  divisions: 49,
                  label: '${_rangeKm.toStringAsFixed(1)} km',
                  onChanged: (value) {
                    setState(() {
                      _rangeKm = value;
                      _filterOffersByRange();
                    });
                  },
                  onChangeEnd: (value) {
                    _updateRange(value);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildRangeButton(String label, double range, BuildContext context) {
    final isSelected = (_rangeKm - range).abs() < 0.1;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _updateRange(range);
          Navigator.pop(context);
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Future<void> _openInMaps(Location location) async {
    final url = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${location.latitude}&mlon=${location.longitude}&zoom=15',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open maps: $e')));
    }
  }
}
