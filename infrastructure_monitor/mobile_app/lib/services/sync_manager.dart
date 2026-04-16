import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/project_model.dart';
import '../models/detection_model.dart';
import '../repositories/project_repository.dart';
import 'firebase_service.dart';
import 'cloudinary_service.dart';

class SyncManager {
  static bool _isSyncing = false;

  /// Checks if internet is available
  static Future<bool> hasInternet() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.isEmpty) return false;
    // For simplicity, check if ANY of the active connections provide internet
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  /// Synchronize all unsynced data to Firebase (Handles Creates, Updates, and Deletes)
  static Future<void> syncData() async {
    if (_isSyncing) return;

    final isOnline = await hasInternet();
    if (!isOnline) {
      print('Sync skipped: No internet connection');
      return;
    }

    _isSyncing = true;
    print('Starting synchronization process...');

    try {
      // 1. Get ALL unsynced projects (includes those marked as isDeleted)
      final unsyncedProjects = ProjectRepository.getUnsyncedProjects();
      
      for (Project project in unsyncedProjects) {
        print('Processing project sync: ${project.id} (Deleted: ${project.isDeleted})');

        if (project.isDeleted) {
          // --- DELETE FLOW ---
          // 1. Delete associated detections in cloud first
          final detections = ProjectRepository.getDetectionsForProject(project.id, includeDeleted: true);
          bool allDetectionsDeleted = true;
          
          for (var detection in detections) {
             final cloudDeleted = await FirebaseService.deleteDetectionFromCloud(detection.id);
             if (cloudDeleted) {
               // Hard delete from Hive once cloud is clear
               await detection.delete();
             } else {
               allDetectionsDeleted = false;
             }
          }

          // 2. Delete project in cloud
          if (allDetectionsDeleted) {
            final projectCloudDeleted = await FirebaseService.deleteProjectFromCloud(project.id);
            if (projectCloudDeleted) {
              // Finally, hard delete project from Hive
              print('Project ${project.id} deleted from cloud, removing from local Hive.');
              await project.delete(); 
              continue; // Move to next project
            }
          }
          print('Project ${project.id} deletion sync failed, will retry.');
        } else {
          // --- CREATE / UPDATE FLOW ---
          bool projectSyncSuccess = true;

          // 1. Sync active detections
          final detections = ProjectRepository.getDetectionsForProject(project.id, includeDeleted: true);
          
          for (Detection detection in detections) {
            if (detection.isDeleted) {
              // Sync individual detection deletion if not part of a project delete
              if (await FirebaseService.deleteDetectionFromCloud(detection.id)) {
                await detection.delete();
              } else {
                projectSyncSuccess = false;
              }
              continue;
            }

            if (detection.isSynced) continue;

            // Upload image to Cloudinary if needed
            if (detection.imageUrl == null || detection.imageUrl!.isEmpty) {
              final folder = 'detections/${project.userId}/${project.id}';
              final downloadUrl = await FirebaseService.uploadImage(folder, detection.imagePath);
              
              if (downloadUrl != null) {
                detection.imageUrl = downloadUrl;
                await ProjectRepository.saveDetection(detection);
              } else {
                projectSyncSuccess = false;
                continue;
              }
            }

            // Push to Firestore
            if (await FirebaseService.saveDetectionToCloud(detection)) {
              detection.isSynced = true;
              await ProjectRepository.saveDetection(detection);
            } else {
              projectSyncSuccess = false;
            }
          }

          // 2. Sync Project Metadata & PDF
          if (projectSyncSuccess) {
            // Upload PDF if pending
            if (project.reportPdfPath != null && 
                project.reportPdfPath!.isNotEmpty &&
                (project.reportPdfUrl == null || project.reportPdfUrl!.isEmpty)) {
              
              final pdfUrl = await CloudinaryService.uploadFile(
                project.reportPdfPath!,
                folder: 'reports/${project.userId}',
              );
              if (pdfUrl != null) {
                project.reportPdfUrl = pdfUrl;
                await ProjectRepository.saveProject(project);
              } else {
                projectSyncSuccess = false;
              }
            }

            // Push project to Firestore
            if (projectSyncSuccess && await FirebaseService.saveProjectToCloud(project)) {
              project.isSynced = true;
              await ProjectRepository.saveProject(project);
              print('Project ${project.id} sync complete.');
            }
          }
        }
      }
    } catch (e) {
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
      print('Synchronization process finished.');
    }
  }

  /// Pull all data from Firebase for the given user and save to Hive
  static Future<void> pullData(String userId) async {
    final isOnline = await hasInternet();
    if (!isOnline) {
      print('Pull skipped: No internet connection');
      return;
    }

    print('Starting data pull from Firebase for user: $userId');
    try {
      // 1. Fetch user projects from cloud
      final cloudProjects = await FirebaseService.fetchUserProjects(userId);
      
      for (final project in cloudProjects) {
        // Save project locally. This will overwrite if it exists, or create if it doesn't.
        // It keeps the local Hive database in sync with the cloud.
        await ProjectRepository.saveProject(project);
        print('Pulled project: ${project.id}');

        // 2. Fetch detections for this project from cloud
        final cloudDetections = await FirebaseService.fetchProjectDetections(project.id);
        for (final detection in cloudDetections) {
          // Save detection locally
          await ProjectRepository.saveDetection(detection);
        }
      }
      print('Data pull completed successfully.');
    } catch (e) {
      print('Error during data pull: $e');
    }
  }
}

