import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../services/yolo_vision_service.dart';

class InspectionScreen extends StatefulWidget {
  final String projectTitle;
  final String location;

  const InspectionScreen({super.key, required this.projectTitle, required this.location});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  
  File? _imageFile;
  List<dynamic> _detections = [];

  @override
  void initState() {
    super.initState();
    // Pre-loads the neural network into phone memory
    YoloVisionService.initializeModel();
  }
  
  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      _runEdgeInference(File(image.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _runEdgeInference(File(image.path));
    }
  }

  Future<void> _runEdgeInference(File file) async {
    setState(() {
      _isAnalyzing = true;
      _imageFile = file;
      _detections = [];
    });

    try {
      // Passes the photo physically to the internal phone processor!
      final results = await YoloVisionService.analyzeImageLocally(file);
      
      setState(() {
        _detections = results;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() { _isAnalyzing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.severityHigh)
      );
    }
  }

  Color _getSeverityColor(String severity) {
    if (severity.contains("High")) return AppColors.severityHigh;
    if (severity.contains("Medium")) return AppColors.severityMedium;
    return AppColors.severityLow;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Location: ${widget.location}", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              const SizedBox(height: 15),
              
              Row(
                children: [
                   Expanded(
                     child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _captureImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Camera", style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Gallery", style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                   ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              if (_isAnalyzing)
                const Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.secondary),
                    SizedBox(height: 15),
                    Text("NPU Processor is scanning image offline...", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                  ],
                ),
                
              if (_imageFile != null && !_isAnalyzing) ...[
                const Text("Offline Analysis Result:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                // --- ROBUST BOUNDING BOX OVERLAY START ---
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        // The raw captured image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.contain,
                            height: 300,
                            width: constraints.maxWidth,
                          ),
                        ),
                        
                        // Transparent canvas for drawing boxes
                        // We use a SizedBox of 300px height to match the image container
                        SizedBox(
                          height: 300,
                          width: constraints.maxWidth,
                          child: CustomPaint(
                            painter: DetectionPainter(
                              detections: _detections,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                ),
                // --- ROBUST BOUNDING BOX OVERLAY END ---

                const SizedBox(height: 20),
                
                const Text("Detected Incidents:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                if (_detections.isEmpty)
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(color: AppColors.severityLow.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                     child: const Text("🟢 Area Clear: No issues detected.", style: TextStyle(color: AppColors.severityLow, fontWeight: FontWeight.bold)),
                   ),
                   
                for (var incident in _detections)
                  Card(
                    color: AppColors.cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(Icons.warning_amber_rounded, color: _getSeverityColor(incident['Severity'])),
                      title: Text(incident['Damage Type'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Size: ${incident['Est. Length (cm)']} | Confidence: ${incident['Confidence']}"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(incident['Severity']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20)
                        ),
                        child: Text(
                          incident['Severity'],
                          style: TextStyle(color: _getSeverityColor(incident['Severity']), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<dynamic> detections;

  DetectionPainter({required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (var detection in detections) {
      final List<dynamic> box = detection['Bounding Box'];
      final String severity = detection['Severity'];
      final String labelText = "${detection['Damage Type']} ${detection['Confidence']}";

      if (severity.contains("High")) {
        paint.color = AppColors.severityHigh;
      } else if (severity.contains("Medium")) {
        paint.color = AppColors.severityMedium;
      } else {
        paint.color = AppColors.severityLow;
      }

      // Calculate Rect
      final rect = Rect.fromLTRB(
        box[0] * size.width,
        box[1] * size.height,
        box[2] * size.width,
        box[3] * size.height,
      );

      // 1. Draw Bounding Box
      canvas.drawRect(rect, paint);

      // 2. Draw Label Background
      final labelBackgroundPaint = Paint()
        ..color = paint.color.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      textPainter.text = TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      canvas.drawRect(
        Rect.fromLTWH(
          rect.left,
          rect.top - textPainter.height - 4,
          textPainter.width + 8,
          textPainter.height + 4,
        ),
        labelBackgroundPaint,
      );

      // 3. Draw Label Text
      textPainter.paint(canvas, Offset(rect.left + 4, rect.top - textPainter.height - 2));
    }
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) => true;
}
