import '../models/project_model.dart';
import '../models/detection_model.dart';
import '../services/database_service.dart';

class ProjectRepository {
  // Project CRUD
  static Future<void> saveProject(Project project) async {
    project.updatedAt = DateTime.now();
    await DatabaseService.projectsBox.put(project.id, project);
  }

  static Future<void> deleteProject(String projectId) async {
    final project = getProjectById(projectId);
    if (project != null) {
      project.isDeleted = true;
      project.isSynced = false;
      await saveProject(project);

      // Also soft-delete associated detections
      final detections = getDetectionsForProject(projectId, includeDeleted: true);
      for (var detection in detections) {
        await deleteDetection(detection.id);
      }
    }
  }

  static List<Project> getAllProjects({bool includeDeleted = false}) {
    return DatabaseService.projectsBox.values
        .where((p) => includeDeleted || !p.isDeleted)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Project? getProjectById(String projectId) {
    return DatabaseService.projectsBox.get(projectId);
  }
  
  static List<Project> getProjectsForUser(String userId, {bool includeDeleted = false}) {
    return DatabaseService.projectsBox.values
        .where((p) => p.userId == userId && (includeDeleted || !p.isDeleted))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<Project> getUnsyncedProjects() {
    return DatabaseService.projectsBox.values.where((p) => !p.isSynced).toList();
  }

  // Detection CRUD
  static Future<void> saveDetection(Detection detection) async {
    detection.updatedAt = DateTime.now();
    await DatabaseService.detectionsBox.put(detection.id, detection);
  }

  static Future<void> deleteDetection(String detectionId) async {
    final detection = DatabaseService.detectionsBox.get(detectionId);
    if (detection != null) {
      detection.isDeleted = true;
      detection.isSynced = false;
      await saveDetection(detection);
    }
  }

  static List<Detection> getDetectionsForProject(String projectId, {bool includeDeleted = false}) {
    return DatabaseService.detectionsBox.values
        .where((d) => d.projectId == projectId && (includeDeleted || !d.isDeleted))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static List<Detection> getAllDetections({bool includeDeleted = false}) {
    return DatabaseService.detectionsBox.values
        .where((d) => includeDeleted || !d.isDeleted)
        .toList();
  }
}
