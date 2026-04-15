import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloudinary_service.dart';
import '../models/project_model.dart';
import '../models/detection_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Upload an image to Cloudinary (replacing Firebase Storage)
  static Future<String?> uploadImage(String folder, String filePath) async {
    return await CloudinaryService.uploadImage(filePath, folder: folder);
  }

  // Save Project to Firestore
  static Future<bool> saveProjectToCloud(Project project) async {
    try {
      await _firestore.collection('projects').doc(project.id).set(project.toMap());
      return true;
    } catch (e) {
      print('Error saving project to cloud: $e');
      return false;
    }
  }

  // Save Detection to Firestore
  static Future<bool> saveDetectionToCloud(Detection detection) async {
    try {
      await _firestore.collection('detections').doc(detection.id).set(detection.toMap());
      return true;
    } catch (e) {
      print('Error saving detection to cloud: $e');
      return false;
    }
  }
}
