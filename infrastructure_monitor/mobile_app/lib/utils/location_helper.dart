import 'package:flutter/material.dart';

class LocationHelper {
  /// Converts decimal degrees to a cardinal coordinate string (e.g., "18.9750° N, 72.8258° E")
  static String formatToCardinal(double latitude, double longitude) {
    String latDirection = latitude >= 0 ? 'N' : 'S';
    String lonDirection = longitude >= 0 ? 'E' : 'W';

    // Using absolute values to display with cardinal indicators
    double absLat = latitude.abs();
    double absLon = longitude.abs();

    return '${absLat.toStringAsFixed(6)}° $latDirection, ${absLon.toStringAsFixed(6)}° $lonDirection';
  }

  /// Formats for "East-West coordinate system" as requested for projects
  static String formatToProjectCoordinates(double latitude, double longitude) {
    String eastingSuffix = longitude >= 0 ? 'E' : 'W';
    String northingSuffix = latitude >= 0 ? 'N' : 'S';
    
    return 'Easting: ${longitude.abs().toStringAsFixed(6)} $eastingSuffix, Northing: ${latitude.abs().toStringAsFixed(6)} $northingSuffix';
  }

  /// Detailed Cardinal formatting including North, East, West, South explicitly
  static Map<String, String> getCardinalComponents(double latitude, double longitude) {
    return {
      'latitude': latitude >= 0 ? '${latitude.abs().toStringAsFixed(6)}° North' : '${latitude.abs().toStringAsFixed(6)}° South',
      'longitude': longitude >= 0 ? '${longitude.abs().toStringAsFixed(6)}° East' : '${longitude.abs().toStringAsFixed(6)}° West',
    };
  }
}
