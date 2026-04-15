import 'package:hive_flutter/hive_flutter.dart';
import '../models/project_model.dart';
import '../models/detection_model.dart';

class DatabaseService {
  static const String projectsBoxName = 'projectsBox';
  static const String detectionsBoxName = 'detectionsBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProjectAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DetectionAdapter());
    }

    // Open boxes
    await Hive.openBox<Project>(projectsBoxName);
    await Hive.openBox<Detection>(detectionsBoxName);
  }

  static Box<Project> get projectsBox => Hive.box<Project>(projectsBoxName);
  static Box<Detection> get detectionsBox => Hive.box<Detection>(detectionsBoxName);
}
