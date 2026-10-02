import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../domain/entities/location.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class MapView extends StatefulWidget {
  final List<Location> locations;
  final double? userLatitude;
  final double? userLongitude;
  final Function(Location)? onLocationTap;

  const MapView({
    required this.locations,
    this.userLatitude,
    this.userLongitude,
    this.onLocationTap,
    super.key,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    if (widget.locations.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 8),
              Text('No locations available', style: AppTextStyles.body2),
            ],
          ),
        ),
      );
    }

    final center = _getCenter();

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12,
            minZoom: 5,
            maxZoom: 18,
            onTap: (tapPosition, point) {
              // Handle map tap if needed
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.lanka_offers',
              maxZoom: 19,
            ),
            MarkerLayer(markers: _buildMarkers()),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Add user location marker if available
    if (widget.userLatitude != null && widget.userLongitude != null) {
      markers.add(
        Marker(
          point: LatLng(widget.userLatitude!, widget.userLongitude!),
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
    }

    // Add offer location markers
    for (int i = 0; i < widget.locations.length; i++) {
      final location = widget.locations[i];
      markers.add(
        Marker(
          point: LatLng(location.latitude, location.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              if (widget.onLocationTap != null) {
                widget.onLocationTap!(location);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.place, color: Colors.white, size: 20),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  LatLng _getCenter() {
    if (widget.locations.isEmpty) {
      return const LatLng(6.9271, 79.8612); // Default to Colombo
    }

    double totalLat = 0;
    double totalLon = 0;

    for (final location in widget.locations) {
      totalLat += location.latitude;
      totalLon += location.longitude;
    }

    return LatLng(
      totalLat / widget.locations.length,
      totalLon / widget.locations.length,
    );
  }
}
