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

  // Fetch all projects for a specific user from Firestore
  static Future<List<Project>> fetchUserProjects(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('projects')
          .where('userId', isEqualTo: userId)
          .get();
      
      return snapshot.docs.map((doc) => Project.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching projects from cloud: $e');
      return [];
    }
  }

  // Fetch all detections for a specific project from Firestore
  static Future<List<Detection>> fetchProjectDetections(String projectId) async {
    try {
      final snapshot = await _firestore
          .collection('detections')
          .where('projectId', isEqualTo: projectId)
          .get();
      
      return snapshot.docs.map((doc) => Detection.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching detections from cloud: $e');
      return [];
    }
  }

  // Delete Project from Firestore
  static Future<bool> deleteProjectFromCloud(String projectId) async {
    try {
      await _firestore.collection('projects').doc(projectId).delete();
      return true;
    } catch (e) {
      print('Error deleting project from cloud: $e');
      return false;
    }
  }

  // Delete Detection from Firestore
  static Future<bool> deleteDetectionFromCloud(String detectionId) async {
    try {
      await _firestore.collection('detections').doc(detectionId).delete();
      return true;
    } catch (e) {
      print('Error deleting detection from cloud: $e');
      return false;
    }
  }
}

