import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import '../models/project_model.dart';
import '../models/detection_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload an image to Firebase Storage and get the download URL
  static Future<String?> uploadImage(String detectionId, String filePath) async {
    try {
      File file = File(filePath);
      if (!await file.exists()) {
        print('File does not exist: $filePath');
        return null;
      }
      
      final fileName = p.basename(filePath);
      final storageRef = _storage.ref().child('detections/$detectionId/$fileName');
      
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
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
