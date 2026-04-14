import 'dart:io';
import 'detector_service.dart';

class YoloVisionService {
  static final DetectorService _detector = DetectorService();

  static Future<void> initializeModel() async {
    await _detector.init();
    print("Edge AI Brain Initialized Offline with TFLite");
  }

  static Future<List<Map<String, dynamic>>> analyzeImageLocally(File imageFile) async {
    final recognitions = await _detector.predict(imageFile);
    
    return recognitions.map((r) => r.toJson()).toList();
  }
}
