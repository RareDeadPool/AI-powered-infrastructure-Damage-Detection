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

  Project({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isSynced = false,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced,
      'userId': userId,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
      isSynced: map['isSynced'] ?? false,
      userId: map['userId'],
    );
  }
}
