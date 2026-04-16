import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/detection_model.dart';
import '../repositories/project_repository.dart';
import '../services/database_service.dart';
import '../services/marker_icon_service.dart';

class AnalysisMapScreen extends StatefulWidget {
  const AnalysisMapScreen({super.key});

  @override
  State<AnalysisMapScreen> createState() => _AnalysisMapScreenState();
}

class _AnalysisMapScreenState extends State<AnalysisMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _iconsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    try {
      await MarkerIconService.loadIcons(context);
      if (mounted) {
        setState(() {
          _iconsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Error loading icons: $e");
    }
  }

  void _updateMarkers(List<Detection> detections) {
    final Set<Marker> newMarkers = {};
    
    for (var d in detections) {
      if (d.latitude == null || d.longitude == null || 
          (d.latitude == 0.0 && d.longitude == 0.0)) continue;

      newMarkers.add(
        Marker(
          markerId: MarkerId(d.id),
          position: LatLng(d.latitude!, d.longitude!),
          icon: MarkerIconService.getIcon(d.damageType),
          infoWindow: InfoWindow(
            title: d.damageType.toUpperCase().replaceAll('_', ' '),
            snippet: 'Severity: ${d.severity.toUpperCase()}',
          ),
        ),
      );
    }
    _markers = newMarkers;
  }

  @override
  Widget build(BuildContext context) {
    if (!_iconsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: DatabaseService.detectionsBox.listenable(),
        builder: (context, Box<Detection> box, _) {
          final detections = ProjectRepository.getAllDetections();
          _updateMarkers(detections);

          return Stack(
            children: [
              _buildMap(detections),
              _buildLegend(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(List<Detection> detections) {
    LatLng initialPos = const LatLng(18.5204, 73.8567); // Default
    
    // If we have detections, center on the most recent one
    if (detections.isNotEmpty) {
      for (var d in detections) {
        if (d.latitude != null && d.longitude != null && d.latitude != 0) {
          initialPos = LatLng(d.latitude!, d.longitude!);
          break;
        }
      }
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPos,
        zoom: 14,
      ),
      onMapCreated: (controller) => _mapController = controller,
      markers: _markers,
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildLegend() {
    return Positioned(
      bottom: 120, 
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ANOMALY LEGEND",
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF38020),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _legendItem('Pothole', const Color(0xFFF38020)),
                  _legendItem('Road Crack', const Color(0xFF2D5096)),
                  _legendItem('Bridge Crack', const Color(0xFF4ED39A)),
                  _legendItem('Pipeline', const Color(0xFF558AFA)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1D2B40),
            ),
          ),
        ],
      ),
    );
  }
}
