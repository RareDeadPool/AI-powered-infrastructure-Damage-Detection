import '../models/project_model.dart';
import '../models/detection_model.dart';
import '../services/database_service.dart';

class ProjectRepository {
  // Project CRUD
  static Future<void> saveProject(Project project) async {
    await DatabaseService.projectsBox.put(project.id, project);
  }

  static Future<void> deleteProject(String projectId) async {
    await DatabaseService.projectsBox.delete(projectId);
    // Also delete associated detections
    final detections = getDetectionsForProject(projectId);
    for (var detection in detections) {
      await DatabaseService.detectionsBox.delete(detection.id);
    }
  }

  static List<Project> getAllProjects() {
    return DatabaseService.projectsBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Project? getProjectById(String projectId) {
    return DatabaseService.projectsBox.get(projectId);
  }
  
  static List<Project> getProjectsForUser(String userId) {
    return DatabaseService.projectsBox.values.where((p) => p.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<Project> getUnsyncedProjects() {
    return DatabaseService.projectsBox.values.where((p) => !p.isSynced).toList();
  }

  // Detection CRUD
  static Future<void> saveDetection(Detection detection) async {
    await DatabaseService.detectionsBox.put(detection.id, detection);
  }

  static Future<void> deleteDetection(String detectionId) async {
    await DatabaseService.detectionsBox.delete(detectionId);
  }

  static List<Detection> getDetectionsForProject(String projectId) {
    return DatabaseService.detectionsBox.values
        .where((d) => d.projectId == projectId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
