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
  });

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
    );
  }
}
