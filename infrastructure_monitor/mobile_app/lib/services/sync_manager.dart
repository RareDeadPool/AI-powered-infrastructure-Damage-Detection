import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/project_model.dart';
import '../models/detection_model.dart';
import '../repositories/project_repository.dart';
import 'firebase_service.dart';

class SyncManager {
  static bool _isSyncing = false;

  /// Checks if internet is available
  static Future<bool> hasInternet() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  /// Synchronize all unsynced data to Firebase
  static Future<void> syncData() async {
    if (_isSyncing) return; // Prevent concurrent sync processes

    final isOnline = await hasInternet();
    if (!isOnline) {
      print('Sync skipped: No internet connection');
      return;
    }

    _isSyncing = true;
    print('Starting synchronization process...');

    try {
      // 1. Get unsynced projects
      final unsyncedProjects = ProjectRepository.getUnsyncedProjects();
      
      for (Project project in unsyncedProjects) {
        bool projectSyncSuccess = true;
        
        print('Syncing project: ${project.id}');

        // 2. Get detections for this project
        final detections = ProjectRepository.getDetectionsForProject(project.id);
        
        for (Detection detection in detections) {
          // If image not uploaded yet, upload it first
          if (detection.imageUrl == null || detection.imageUrl!.isEmpty) {
            final downloadUrl = await FirebaseService.uploadImage(detection.id, detection.imagePath);
            
            if (downloadUrl != null) {
              detection.imageUrl = downloadUrl;
              // update local db with URL first
              await ProjectRepository.saveDetection(detection);
            } else {
              print('Failed to upload image for detection: ${detection.id}');
              projectSyncSuccess = false;
              continue; // If image fails, skip syncing this detection to cloud
            }
          }

          // Force push detection to Cloud (create/update)
          final detectionSaved = await FirebaseService.saveDetectionToCloud(detection);
          if (!detectionSaved) {
            projectSyncSuccess = false;
          }
        }

        // 3. Sync project metadata to Cloud
        if (projectSyncSuccess) {
          final projectSaved = await FirebaseService.saveProjectToCloud(project);
          if (projectSaved) {
            // Mark project as synced in Hive
            project.isSynced = true;
            await ProjectRepository.saveProject(project);
            print('Project ${project.id} synced successfully!');
          }
        } else {
          print('Project ${project.id} partially synced, will retry later.');
        }
      }
      
    } catch (e) {
      print('Critical Error during sync: $e');
    } finally {
      _isSyncing = false;
      print('Synchronization process finished.');
    }
  }
}
