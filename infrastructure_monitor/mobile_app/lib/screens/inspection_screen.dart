import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';
import '../utils/location_helper.dart';
import '../services/detector_service.dart';
import '../services/report_service.dart';
import '../models/recognition.dart';

class InspectionScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;
  final String location;
  final File? initialImage;

  const InspectionScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
    required this.location,
    this.initialImage,
  });

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  final DetectorService _detectorService = DetectorService();
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;

  List<Recognition> _detections = [];
  List<Recognition> _savedDetections = [];
  String? _capturedImagePath;
  bool _isLive = true;
  
  // Geo-tagging data for the capture
  double? _captureLat;
  double? _captureLng;

  DateTime? _lastInferenceTime;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _detectorService.init();

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController!.initialize();

      // Start Image Stream for Live Inference
      _cameraController!.startImageStream((CameraImage image) {
        if (_isLive && !_isAnalyzing) {
          final now = DateTime.now();
          if (_lastInferenceTime == null ||
              now.difference(_lastInferenceTime!).inMilliseconds > 80) {
            _lastInferenceTime = now;
            _runLiveInference(image);
          }
        }
      });

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Camera Error: $e");
    }
  }

  Future<void> _runLiveInference(CameraImage image) async {
    _isAnalyzing = true;
    final results = await _detectorService.predictCameraFrame(image);
    _isAnalyzing = false;

    if (mounted && _isLive) {
      setState(() {
        _detections = results;
      });
    }
  }

  Future<void> _captureDetection() async {
    if (_cameraController == null) return;
    try {
      // 1. Fetch Geo-coordinates precisely for this click
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            timeLimit: const Duration(seconds: 3));
      } catch (e) {
        debugPrint("Location capture failed: $e");
      }

      // 2. Take a picture before pausing preview
      final image = await _cameraController!.takePicture();
      await _cameraController!.pausePreview();
      
      setState(() {
        _isLive = false;
        _capturedImagePath = image.path;
        _savedDetections = List.from(_detections);
        _captureLat = position?.latitude;
        _captureLng = position?.longitude;
      });

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(position != null 
            ? "Damage Captured at ${LocationHelper.formatToCardinal(position.latitude, position.longitude)}"
            : "Damage Detection Captured!"),
          backgroundColor: AppColors.secondary,
          duration: const Duration(seconds: 2),
        )
      );
    } catch (e) {
      print("Error pausing preview: $e");
    }
  }

  Future<void> _resumeLive() async {
    if (_cameraController == null) return;
    try {
      await _cameraController!.resumePreview();
      setState(() {
        _isLive = true;
        _detections = [];
        _captureLat = null;
        _captureLng = null;
      });
    } catch (e) {
      print("Error resuming preview: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Color _getSeverityColor(String severity) {
    if (severity.contains("High")) return AppColors.severityHigh;
    if (severity.contains("Medium")) return AppColors.severityMedium;
    return AppColors.severityLow;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.projectTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final previewSize = constraints.maxWidth - 40;
          return Column(
            children: [
              // 1. Professional Square Viewport
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  width: previewSize,
                  height: previewSize,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        if (_isCameraInitialized)
                          OverflowBox(
                            alignment: Alignment.center,
                            child: AspectRatio(
                              aspectRatio: 1 / _cameraController!.value.aspectRatio,
                              child: CameraPreview(_cameraController!),
                            ),
                          )
                        else
                          const Center(child: CircularProgressIndicator(color: AppColors.primary)),

                        // Real-time Bounding Boxes
                        Positioned.fill(
                          child: CustomPaint(
                            painter: DetectionPainter(
                              recognitions: _isLive ? _detections : _savedDetections,
                            ),
                          ),
                        ),

                        // Mode Tag
                        Positioned(
                          top: 15,
                          right: 15,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _isLive ? Colors.red.withOpacity(0.9) : AppColors.secondary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _isLive ? "LIVE SCANNING" : "FREEZE FRAME",
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        
                        // GPS Badge
                        if (!_isLive && _captureLat != null)
                          Positioned(
                            bottom: 15,
                            left: 15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.gps_fixed, color: Colors.white, size: 12),
                                  const SizedBox(width: 6),
                                  Text(
                                    LocationHelper.formatToCardinal(_captureLat!, _captureLng!),
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isCameraInitialized ? (_isLive ? _captureDetection : _resumeLive) : null,
                        icon: Icon(_isLive ? Icons.camera : Icons.refresh, size: 22),
                        label: Text(_isLive ? "CAPTURE INCIDENT" : "RESUME SCAN"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLive ? AppColors.primary : AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    if (!_isLive) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_capturedImagePath != null && _savedDetections.isNotEmpty) {
                              ReportService.generateAndShareReport(
                                projectTitle: widget.projectTitle,
                                location: widget.location,
                                detections: _savedDetections,
                                imagePath: _capturedImagePath!,
                                lat: _captureLat,
                                lng: _captureLng,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("No detections to report!"))
                              );
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 22),
                          label: const Text("GENERATE REPORT"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 3. Results Section
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isLive ? "REAL-TIME DETECTION" : "CAPTURE LOG",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                          ),
                          if (_isLive)
                            const Icon(Icons.circle, color: Colors.red, size: 8),
                        ],
                      ),
                      const Divider(height: 20),
                      Expanded(
                        child: (_isLive ? _detections : _savedDetections).isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search, size: 40, color: Colors.grey.shade300),
                                    const SizedBox(height: 10),
                                    Text("Waiting for damage...", style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: (_isLive ? _detections : _savedDetections).length,
                                itemBuilder: (context, index) {
                                  final rec = (_isLive ? _detections : _savedDetections)[index];
                                  return Card(
                                    elevation: 0,
                                    color: AppColors.cardColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: BorderSide(color: Colors.grey.shade100),
                                    ),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                      leading: CircleAvatar(
                                        backgroundColor: _getSeverityColor(rec.score > 0.7 ? "High" : "Low").withOpacity(0.1),
                                        child: Icon(Icons.warning, color: _getSeverityColor(rec.score > 0.7 ? "High" : "Low"), size: 20),
                                      ),
                                      title: Text(rec.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text("Confidence: ${(rec.score * 100).toStringAsFixed(1)}%"),
                                      trailing: Text(
                                        rec.score > 0.7 ? "CRITICAL" : "MONITOR",
                                        style: TextStyle(
                                          color: _getSeverityColor(rec.score > 0.7 ? "High" : "Low"),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<Recognition> recognitions;

  DetectionPainter({required this.recognitions});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var rec in recognitions) {
      final rect = Rect.fromLTRB(
        rec.location.left * size.width,
        rec.location.top * size.height,
        rec.location.right * size.width,
        rec.location.bottom * size.height,
      );

      // Color mapping
      paint.color = rec.score > 0.7
          ? AppColors.severityHigh
          : (rec.score > 0.4 ? AppColors.severityMedium : AppColors.secondary);

      // 1. Draw Bounding Box with subtle rounded corners
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);

      // 2. Draw Label Background
      final labelText = "${rec.label.toUpperCase()} ${(rec.score * 100).toStringAsFixed(1)}%";
      textPainter.text = TextSpan(
        text: labelText,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      );
      textPainter.layout();

      final bgRect = Rect.fromLTWH(
        rect.left,
        rect.top - textPainter.height - 6,
        textPainter.width + 10,
        textPainter.height + 6,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
        Paint()..color = paint.color,
      );

      // 3. Draw Label Text
      textPainter.paint(canvas, Offset(rect.left + 5, rect.top - textPainter.height - 3));
    }
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) => true;
}
