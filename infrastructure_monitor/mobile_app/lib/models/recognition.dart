import 'package:flutter/material.dart';

class Recognition {
  final int id;
  final String label;
  final double score;
  final Rect location;
  final double areaPct;

  // FIX: Converted to named parameters for compatibility with calls in InspectionScreen
  Recognition({
    required this.id,
    required this.label,
    required this.score,
    required this.location,
    required this.areaPct,
  });

  String get severity {
    if (areaPct >= 8.0) return "🔴 High";
    if (areaPct >= 2.0) return "🟠 Medium";
    return "🟢 Low";
  }

  Map<String, dynamic> toJson() {
    return {
      "Damage Type": label.replaceAll('_', ' ').toUpperCase(),
      "Confidence": "${(score * 100).toStringAsFixed(1)}%",
      "Est. Length (cm)": "${areaPct.toStringAsFixed(1)}% Area",
      "Severity": severity,
      "Bounding Box": [location.left, location.top, location.right, location.bottom]
    };
  }

  @override
  String toString() {
    return 'Recognition(label: $label, score: ${score.toStringAsFixed(2)}, location: $location)';
  }
}