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

        // 3. Upload PDF report to Cloudinary if exists locally but not uploaded
        if (project.reportPdfPath != null && 
            project.reportPdfPath!.isNotEmpty &&
            (project.reportPdfUrl == null || project.reportPdfUrl!.isEmpty)) {
          print('Uploading PDF report for project: ${project.id}');
          final pdfUrl = await CloudinaryService.uploadFile(
            project.reportPdfPath!,
            folder: 'reports/${project.userId}',
          );
          if (pdfUrl != null) {
            project.reportPdfUrl = pdfUrl;
            await ProjectRepository.saveProject(project);
            print('PDF report uploaded: $pdfUrl');
          } else {
            print('Failed to upload PDF for project: ${project.id}');
            projectSyncSuccess = false;
          }
        }

        // 4. Sync project metadata to Cloud
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

