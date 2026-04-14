import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/recognition.dart';
import 'package:flutter/material.dart';

class DetectorService {
  late Interpreter _interpreter;
  static const String _modelPath = 'assets/models/final_model.tflite';

  final List<String> _labels = [
    'pothole',
    'road_crack',
    'bridge_crack',
    'pipeline_leak',
    'corrosion'
  ];

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      _isInitialized = true;
      print('DetectorService initialized successfully');
    } catch (e) {
      print('Error initializing TFLite interpreter: $e');
    }
  }

  Future<List<Recognition>> predict(File imageFile) async {
    if (!_isInitialized) await init();

    // 1. Load and Preprocess Image
    final imageData = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return [];

    // FIX: Bake orientation (Camera images are often rotated in metadata)
    originalImage = img.bakeOrientation(originalImage);

    // --- LETTERBOX RESIZE START ---
    // Maintain aspect ratio instead of squashing
    double scale = min(640 / originalImage.width, 640 / originalImage.height);
    int newW = (originalImage.width * scale).toInt();
    int newH = (originalImage.height * scale).toInt();
    
    img.Image resized = img.copyResize(originalImage, width: newW, height: newH);
    
    // Create a black 640x640 canvas
    img.Image finalImage = img.Image(width: 640, height: 640);
    
    // Center the resized image on the canvas
    int offsetX = (640 - newW) ~/ 2;
    int offsetY = (640 - newH) ~/ 2;
    img.compositeImage(finalImage, resized, dstX: offsetX, dstY: offsetY);

    // Convert to Float32List
    var input = _imageToByteListFloat32(finalImage);
    // --- LETTERBOX RESIZE END ---

    // 2. Prepare Output Tensor [1, 9, 8400]
    // 9 = 4 (box) + 5 (classes)
    var output = List.filled(1 * 9 * 8400, 0.0).reshape([1, 9, 8400]);

    // 3. Run Inference
    _interpreter.run(input, output);

    // 4. Post-process
    List<Recognition> rawResults = _parseResults(output, originalImage.width, originalImage.height, offsetX, offsetY, newW, newH);
    
    // Cap at 50 most confident detections to prevent UI crashes on complex cracks
    if (rawResults.length > 50) {
      rawResults.sort((a, b) => b.score.compareTo(a.score));
      rawResults = rawResults.sublist(0, 50);
    }

    return rawResults;
  }

  dynamic _imageToByteListFloat32(img.Image image) {
    var convertedBytes = List.generate(
      1,
      (i) => List.generate(
        640,
        (j) => List.generate(
          640,
          (k) => List.filled(3, 0.0),
        ),
      ),
    );

    for (var i = 0; i < 640; i++) {
        for (var j = 0; j < 640; j++) {
            var pixel = image.getPixel(j, i);
            // Reverting to standard RGB [Red, Green, Blue] for YOLOv8 consistency
            convertedBytes[0][i][j][0] = pixel.r / 255.0; // R
            convertedBytes[0][i][j][1] = pixel.g / 255.0; // G
            convertedBytes[0][i][j][2] = pixel.b / 255.0; // B
        }
    }
    return convertedBytes;
  }

  List<Recognition> _parseResults(List<dynamic> output, int imgW, int imgH, int offsetX, int offsetY, int newW, int newH) {
    final List<Recognition> recognitions = [];
    final List<dynamic> data = output[0]; // [9, 8400]

    for (int i = 0; i < 8400; i++) {
      double maxScore = 0.0;
      int classId = -1;
      
      for (int c = 4; c < 9; c++) {
        double score = data[c][i];
        if (score > maxScore) {
          maxScore = score;
          classId = c - 4;
        }
      }

      // TEMPORARY: Lowered to 0.10 to catch low-confidence camera detections
      if (maxScore > 0.10) {
        double cx = data[0][i];
        double cy = data[1][i];
        double w = data[2][i];
        double h = data[3][i];

        // 1. Convert normalized (0-1) to 640px space
        // 2. Subtract offsets (remove letterbox padding)
        // 3. Divide by new dimensions to get original normalized coordinates
        double x1 = ((cx - w / 2) * 640 - offsetX) / newW;
        double y1 = ((cy - h / 2) * 640 - offsetY) / newH;
        double x2 = ((cx + w / 2) * 640 - offsetX) / newW;
        double y2 = ((cy + h / 2) * 640 - offsetY) / newH;

        // Safety Clamping
        x1 = x1.clamp(0.0, 1.0);
        y1 = y1.clamp(0.0, 1.0);
        x2 = x2.clamp(0.0, 1.0);
        y2 = y2.clamp(0.0, 1.0);

        // Aspect ratio corrected area calculation
        double areaPct = (w * h) * (640 * 640) / (newW * newH) * 100;

        // Apply class name mapping (merge cracks if needed)
        String label = _labels[classId];
        if (label == 'road_crack' || label == 'bridge_crack') {
          label = 'crack';
        }

        recognitions.add(Recognition(
          classId,
          label,
          maxScore,
          Rect.fromLTRB(x1, y1, x2, y2),
          areaPct,
        ));
      }
    }

    // 5. Apply Non-Maximum Suppression (NMS)
    return _nms(recognitions);
  }

  List<Recognition> _nms(List<Recognition> recognitions) {
    if (recognitions.isEmpty) return [];

    // Sort by score descending
    recognitions.sort((a, b) => b.score.compareTo(a.score));

    final List<Recognition> selected = [];
    final List<bool> active = List.filled(recognitions.length, true);

    for (int i = 0; i < recognitions.length; i++) {
      if (active[i]) {
        selected.add(recognitions[i]);
        for (int j = i + 1; j < recognitions.length; j++) {
          if (active[j]) {
            double iou = _calculateIoU(recognitions[i].location, recognitions[j].location);
            if (iou > 0.45) {
              active[j] = false;
            }
          }
        }
      }
    }
    return selected;
  }

  double _calculateIoU(Rect a, Rect b) {
    double intersectionArea = Rect.fromLTRB(
      max(a.left, b.left),
      max(a.top, b.top),
      min(a.right, b.right),
      min(a.bottom, b.bottom),
    ).width * max(0, Rect.fromLTRB(
      max(a.left, b.left),
      max(a.top, b.top),
      min(a.right, b.right),
      min(a.bottom, b.bottom),
    ).height);

    if (intersectionArea <= 0) return 0;

    double unionArea = (a.width * a.height) + (b.width * b.height) - intersectionArea;
    return intersectionArea / unionArea;
  }
}
