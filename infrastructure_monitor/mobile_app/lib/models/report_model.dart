import 'dart:convert';

class Report {
  final String id;
  final double latitude;
  final double longitude;
  final String damageType;
  final String severity;

  Report({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.damageType,
    required this.severity,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      damageType: json['damage_type']?.toString().toLowerCase() ?? 'unknown',
      severity: json['severity']?.toString().toLowerCase() ?? 'low',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'damage_type': damageType,
      'severity': severity,
    };
  }
}
