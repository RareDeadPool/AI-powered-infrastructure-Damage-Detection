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
              
              ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _captureImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text("Scan Damage via Camera", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
                
                // Displays the raw local image securely
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    fit: BoxFit.contain,
                    height: 300,
                  ),
                ),
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
