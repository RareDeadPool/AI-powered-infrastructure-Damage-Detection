import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationService {
  /// Fetch current GPS position with error handling and permission requests.
  /// This implements a "Fetch Once" strategy suitable for point-of-interest tagging.
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return null;
    } 

    try {
      // Fetch current position with a timeout to prevent app hang
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Error fetching location: $e');
      return null;
    }
  }
}
