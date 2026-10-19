import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../domain/entities/event.dart';
import '../../../../domain/entities/location.dart';

class EventsMapViewScreen extends StatefulWidget {
  final List<Event> events;
  final double? userLatitude;
  final double? userLongitude;

  const EventsMapViewScreen({
    required this.events,
    this.userLatitude,
    this.userLongitude,
    super.key,
  });

  @override
  State<EventsMapViewScreen> createState() => _EventsMapViewScreenState();
}

class _EventsMapViewScreenState extends State<EventsMapViewScreen> {
  final MapController _mapController = MapController();
  Event? _selectedEvent;
  Location? _selectedLocation;
  List<LatLng>? _routePoints;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });
  }

  void _fitBounds() {
    if (widget.events.isEmpty) return;

    final points = <LatLng>[];

    final userLat = widget.userLatitude ?? AppConstants.defaultLatitude;
    final userLon = widget.userLongitude ?? AppConstants.defaultLongitude;
    points.add(LatLng(userLat, userLon));

    for (final event in widget.events) {
      for (final location in event.locations) {
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
    if (widget.events.isEmpty) {
      return LatLng(
        widget.userLatitude ?? AppConstants.defaultLatitude,
        widget.userLongitude ?? AppConstants.defaultLongitude,
      );
    }

    double totalLat = widget.userLatitude ?? AppConstants.defaultLatitude;
    double totalLon = widget.userLongitude ?? AppConstants.defaultLongitude;
    int count = 1;

    for (final event in widget.events) {
      for (final location in event.locations) {
        totalLat += location.latitude;
        totalLon += location.longitude;
        count++;
      }
    }

    return LatLng(totalLat / count, totalLon / count);
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
            route.add(
              LatLng(coord[1], coord[0]),
            ); // Note: GeoJSON is [lon, lat]
          }

          setState(() {
            _routePoints = route;
          });
        }
      }
    } catch (e) {
      // If routing fails, just show the event details
      debugPrint('Route calculation failed: $e');
    }
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
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
      ),
    );

    // Add event location markers
    for (final event in widget.events) {
      if (event.locations.isEmpty) continue;

      for (final location in event.locations) {
        markers.add(
          Marker(
            point: LatLng(location.latitude, location.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedEvent = event;
                  _selectedLocation = location;
                  _routePoints = null;
                });
                _showRoute(location);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.eventColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.event, color: Colors.white, size: 20),
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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.eventsMap)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _getCenter(),
              initialZoom: 12,
              minZoom: 5,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.lanka_offers',
                maxZoom: 19,
              ),
              if (_routePoints != null && _routePoints!.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints!,
                      strokeWidth: 4,
                      color: AppColors.eventColor,
                    ),
                  ],
                ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          if (_selectedEvent != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.elevatedShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedEvent!.title,
                      style: AppTextStyles.h4,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(_selectedEvent!.organizer, style: AppTextStyles.body2),
                    const SizedBox(height: 4),
                    Text(
                      _selectedEvent!.venue.name,
                      style: AppTextStyles.caption,
                    ),
                    if (_selectedLocation != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _selectedLocation!.address,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_selectedLocation != null) {
                                _openInMaps(_selectedLocation!);
                              }
                            },
                            icon: const Icon(Icons.directions, size: 18),
                            label: Text(
                              AppLocalizations.of(context)!.getDirections,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.eventColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context, _selectedEvent);
                            },
                            child: Text(
                              AppLocalizations.of(context)!.viewDetails,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedEvent = null;
                              _selectedLocation = null;
                              _routePoints = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open maps: $e')));
    }
  }
}
