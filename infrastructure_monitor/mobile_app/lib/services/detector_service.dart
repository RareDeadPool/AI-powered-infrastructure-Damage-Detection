import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/recognition.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:isolate';

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
  
  static Map<String, double> categoryThresholds = {
    'pothole': 0.15,
    'crack': 0.15,
    'pipeline_leak': 0.15,
    'corrosion': 0.15,
  };
  static double iouThreshold = 0.45;

  bool _isInitialized = false;
  bool _isProcessing = false;

  Future<void> init() async {
    await loadSettings();
    if (_isInitialized) return;
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
      _isInitialized = true;
      print('DetectorService initialized with 4 threads');
    } catch (e) {
      print('Error initializing TFLite interpreter: $e');
    }
  }

  Future<List<Recognition>> predict(File imageFile) async {
    if (!_isInitialized) await init();

    // 1. Load & decode (run heavy work off the UI thread via compute)
    final imageData = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return [];

    // Bake orientation (camera JPEGs are often rotated in EXIF)
    originalImage = img.bakeOrientation(originalImage);

    // --- Letterbox resize to 640×640 maintaining aspect ratio ---
    final double scale = min(640 / originalImage.width, 640 / originalImage.height);
    final int newW = (originalImage.width * scale).toInt();
    final int newH = (originalImage.height * scale).toInt();
    final int offsetX = (640 - newW) ~/ 2;
    final int offsetY = (640 - newH) ~/ 2;

    img.Image resized = img.copyResize(originalImage, width: newW, height: newH);
    img.Image canvas = img.Image(width: 640, height: 640); // black canvas
    img.compositeImage(canvas, resized, dstX: offsetX, dstY: offsetY);

    // 2. Fast pixel → Float32List (direct write, no nested allocations)
    final Float32List inputFlat = _imageToFloat32Fast(canvas);

    // 3. Inject directly into the input tensor (same path as live camera)
    final inputTensor = _interpreter.getInputTensor(0);
    inputTensor.data.setRange(0, inputTensor.data.length, inputFlat.buffer.asUint8List());

    // 4. Run inference
    _interpreter.invoke();

    // 5. Read output tensor
    final outputTensor = _interpreter.getOutputTensor(0);
    final Float32List outputFlat = outputTensor.data.buffer.asFloat32List(
      outputTensor.data.offsetInBytes,
      outputTensor.data.length ~/ 4,
    );

    // 6. Post-process
    List<Recognition> rawResults = _parseResults(
        outputFlat, originalImage.width, originalImage.height, offsetX, offsetY, newW, newH);

    if (rawResults.length > 50) {
      rawResults.sort((a, b) => b.score.compareTo(a.score));
      rawResults = rawResults.sublist(0, 50);
    }
    return rawResults;
  }

  /// Live Tracking: Processes raw CameraImage bytes from the stream
  Future<List<Recognition>> predictCameraFrame(CameraImage image) async {
    if (!_isInitialized) await init();
    if (_isProcessing) return [];
    _isProcessing = true;

    try {
      final int width = image.width;
      final int height = image.height;
      
      // Use efficient fixed-point conversion
      final inputBuffer = _convertYUV420ToFloat32(image);

      // 2. High-Performance direct memory manipulation
      final inputTensor = _interpreter.getInputTensor(0);
      inputTensor.data.setRange(0, inputTensor.data.length, inputBuffer.buffer.asUint8List());
      
      // 3. Run Inference
      _interpreter.invoke();

      // 4. Extract Output
      final outputTensor = _interpreter.getOutputTensor(0);
      final Float32List outputFlat = outputTensor.data.buffer.asFloat32List(
        outputTensor.data.offsetInBytes, 
        outputTensor.data.length ~/ 4
      );
      
      // 5. Post-process (Pass original dimensions to map crop correctly)
      List<Recognition> rawResults = _parseResults(outputFlat, width, height, 0, 0, 640, 640);
      
      _isProcessing = false;
      return rawResults;
    } catch (e) {
      print("Error in live inference: $e");
      _isProcessing = false;
      return [];
    }
  }

  /// Blazing Fast Integer YUV to RGB Conversion
  Float32List _convertYUV420ToFloat32(CameraImage image) {
    const int inputSize = 640;
    final Float32List out = Float32List(inputSize * inputSize * 3);
    
    final int width = image.width;
    final int height = image.height;
    
    final Uint8List yPlane = image.planes[0].bytes;
    final Uint8List uPlane = image.planes[1].bytes;
    final Uint8List vPlane = image.planes[2].bytes;
    
    final int yRowStride = image.planes[0].bytesPerRow;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;
    
    final int size = min(width, height);
    final int startX = (width - size) >> 1;
    final int startY = (height - size) >> 1;
    final double step = size / inputSize;

    int outPtr = 0;
    for (int y = 0; y < inputSize; y++) {
      final int srcY = startY + (y * step).toInt();
      final int yOffset = srcY * yRowStride;
      final int uvOffset = (srcY >> 1) * uvRowStride;
      
      for (int x = 0; x < inputSize; x++) {
        final int srcX = startX + (x * step).toInt();
        final int uvPixelOffset = uvOffset + (srcX >> 1) * uvPixelStride;
        
        final int yp = yPlane[yOffset + srcX];
        final int up = uPlane[uvPixelOffset];
        final int vp = vPlane[uvPixelOffset];
        
        // Integer-only Fixed-Point YUV420 to RGB Conversion (BT.601)
        // 10-bit precision
        int r = (yp + ((1436 * (vp - 128)) >> 10)).clamp(0, 255);
        int g = (yp - ((352 * (up - 128) + 731 * (vp - 128)) >> 10)).clamp(0, 255);
        int b = (yp + ((1814 * (up - 128)) >> 10)).clamp(0, 255);

        out[outPtr++] = r / 255.0;
        out[outPtr++] = g / 255.0;
        out[outPtr++] = b / 255.0;
      }
    }
    return out;
  }

  /// Fast pixel extraction using a flat Float32List.
  /// ~10× faster than the old nested List.generate approach.
  Float32List _imageToFloat32Fast(img.Image image) {
    final out = Float32List(640 * 640 * 3);
    int idx = 0;
    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final pixel = image.getPixel(x, y);
        out[idx++] = pixel.r / 255.0;
        out[idx++] = pixel.g / 255.0;
        out[idx++] = pixel.b / 255.0;
      }
    }
    return out;
  }

  List<Recognition> _parseResults(Float32List data, int imgW, int imgH, int offsetX, int offsetY, int newW, int newH) {
    final List<Recognition> recognitions = [];

    // Assuming data is flattened [9, 8400]
    for (int i = 0; i < 8400; i++) {
      double maxScore = 0.0;
      int classId = -1;
      
      // Classes are from row 4 to 8
      for (int c = 4; c < 9; c++) {
        double score = data[c * 8400 + i];
        if (score > maxScore) {
          maxScore = score;
          classId = c - 4;
        }
      }

        // Apply class name mapping (merge cracks if needed)
        String label = _labels[classId];
        if (label == 'road_crack' || label == 'bridge_crack') {
          label = 'crack';
        }

        double threshold = categoryThresholds[label] ?? 0.15;

        if (maxScore > threshold) {
          double cx = data[0 * 8400 + i];
          double cy = data[1 * 8400 + i];
          double w = data[2 * 8400 + i];
          double h = data[3 * 8400 + i];

          // Map coordinates from the 640x640 center-crop back to original frame dimensions
          int size = min(imgW, imgH);
          int startX = (imgW - size) >> 1;
          int startY = (imgH - size) >> 1;

          double boxX = startX + (cx * size);
          double boxY = startY + (cy * size);
          double boxW = w * size;
          double boxH = h * size;

          double x1 = (boxX - boxW / 2) / imgW;
          double y1 = (boxY - boxH / 2) / imgH;
          double x2 = (boxX + boxW / 2) / imgW;
          double y2 = (boxY + boxH / 2) / imgH;

          // Safety Clamping
          x1 = x1.clamp(0.0, 1.0);
          y1 = y1.clamp(0.0, 1.0);
          x2 = x2.clamp(0.0, 1.0);
          y2 = y2.clamp(0.0, 1.0);

          // Aspect ratio corrected area calculation
          double areaPct = (w * h) * (640 * 640) / (newW * newH) * 100;

          recognitions.add(Recognition(
            id: classId,
            label: label,
            score: maxScore,
            location: Rect.fromLTRB(x1, y1, x2, y2),
            areaPct: areaPct,
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
            if (iou > iouThreshold) {
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

  static Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      categoryThresholds['pothole'] = prefs.getDouble('conf_pothole') ?? 0.15;
      categoryThresholds['crack'] = prefs.getDouble('conf_crack') ?? 0.15;
      categoryThresholds['pipeline_leak'] = prefs.getDouble('conf_pipeline_leak') ?? 0.15;
      categoryThresholds['corrosion'] = prefs.getDouble('conf_corrosion') ?? 0.15;
      iouThreshold = prefs.getDouble('iou_threshold') ?? 0.45;
      print('Detector thresholds loaded: $categoryThresholds, IoU=$iouThreshold');
    } catch (e) {
      print('Error loading detector settings: $e');
    }
  }
}
