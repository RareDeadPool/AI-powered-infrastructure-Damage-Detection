import 'package:hive/hive.dart';

part 'detection_model.g.dart';

@HiveType(typeId: 1)
class Detection extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String projectId;

  @HiveField(2)
  String imagePath;

  @HiveField(3)
  String? imageUrl;

  @HiveField(4)
  String damageType;

  @HiveField(5)
  String severity;

  @HiveField(6)
  double confidence;

  @HiveField(7)
  double? latitude;

  @HiveField(8)
  double? longitude;

  @HiveField(9)
  DateTime timestamp;

  @HiveField(10)
  bool isDeleted;

  @HiveField(11)
  DateTime updatedAt;

  @HiveField(12)
  bool isSynced;

  Detection({
    required this.id,
    required this.projectId,
    required this.imagePath,
    this.imageUrl,
    required this.damageType,
    required this.severity,
    required this.confidence,
    this.latitude,
    this.longitude,
    required this.timestamp,
    this.isDeleted = false,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : updatedAt = updatedAt ?? timestamp;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'damageType': damageType,
      'severity': severity,
      'confidence': confidence,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'isDeleted': isDeleted,
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory Detection.fromMap(Map<String, dynamic> map) {
    return Detection(
      id: map['id'],
      projectId: map['projectId'],
      imagePath: map['imagePath'],
      imageUrl: map['imageUrl'],
      damageType: map['damageType'],
      severity: map['severity'],
      confidence: map['confidence']?.toDouble() ?? 0.0,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      isDeleted: map['isDeleted'] ?? false,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.parse(map['timestamp']),
      isSynced: map['isSynced'] ?? false,
    );
  }
}
