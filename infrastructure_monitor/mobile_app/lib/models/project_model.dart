import 'package:hive/hive.dart';

part 'project_model.g.dart';

@HiveType(typeId: 0)
class Project extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  bool isSynced;

  @HiveField(4)
  String userId;

  @HiveField(5)
  String location;

  @HiveField(6)
  String? reportPdfPath;

  @HiveField(7)
  String? reportPdfUrl;

  @HiveField(8)
  int detectionCount;

  @HiveField(9)
  String? isCorrect;

  Project({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isSynced = false,
    required this.userId,
    this.location = '',
    this.reportPdfPath,
    this.reportPdfUrl,
    this.detectionCount = 0,
    this.isCorrect,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced,
      'userId': userId,
      'location': location,
      'reportPdfUrl': reportPdfUrl,
      'detectionCount': detectionCount,
      'isCorrect': isCorrect,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
      isSynced: map['isSynced'] ?? false,
      userId: map['userId'],
      location: map['location'] ?? '',
      reportPdfUrl: map['reportPdfUrl'],
      detectionCount: map['detectionCount'] ?? 0,
      isCorrect: map['isCorrect'],
    );
  }
}
