import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerIconService {
  static final Map<String, BitmapDescriptor> _icons = {};

  /// Loads all custom marker icons from assets and resizes them for map use
  static Future<void> loadIcons(BuildContext context) async {
    if (_icons.isNotEmpty) return;

    try {
      _icons['pothole'] = await _getResizedIcon('assets/icons/pothole.png', 100);
      _icons['road_crack'] = await _getResizedIcon('assets/icons/road_crack.png', 100);
      _icons['bridge_crack'] = await _getResizedIcon('assets/icons/bridge_crack.png', 100);
      _icons['pipeline_leak'] = await _getResizedIcon('assets/icons/pipeline.png', 100);
      _icons['pipeline'] = _icons['pipeline_leak']!;
      
    } catch (e) {
      debugPrint('Error loading custom markers: $e');
    }
  }

  static Future<BitmapDescriptor> _getResizedIcon(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(), 
      targetWidth: width
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    final byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Get icon for a specific damage type
  static BitmapDescriptor getIcon(String damageType) {
    final type = damageType.toLowerCase().replaceAll(' ', '_');
    return _icons[type] ?? BitmapDescriptor.defaultMarker;
  }
}
