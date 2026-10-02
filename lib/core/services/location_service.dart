import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position from GPS
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permission
      LocationPermission permission = await checkPermission();

      // If denied, request permission
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      // If permanently denied, return null
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy
                .medium, // Changed from high to medium for better reliability
        timeLimit: const Duration(seconds: 20),
      );

      return position;
    } catch (e) {
      // Return null on any error
      return null;
    }
  }

  /// Convert coordinates to address using geocoding
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Build address string
        List<String> addressParts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        return addressParts.isNotEmpty ? addressParts.join(', ') : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get a simplified location name (city/district)
  Future<String?> getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Prefer locality (city), then administrative area (district), then country
        if (place.locality != null && place.locality!.isNotEmpty) {
          return place.locality;
        } else if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          return place.administrativeArea;
        } else if (place.country != null && place.country!.isNotEmpty) {
          return place.country;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if permission is permanently denied
  Future<bool> isPermissionPermanentlyDenied() async {
    final permission = await checkPermission();
    return permission == LocationPermission.deniedForever;
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await permission_handler.openAppSettings();
  }
}
