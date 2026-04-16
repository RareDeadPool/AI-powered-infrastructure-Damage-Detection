import 'dart:math';
import 'package:flutter/material.dart';
import '../models/recognition.dart';

/// A single detection being tracked across multiple frames.
class _TrackedBox {
  /// Unique ID for this tracked box (used as the widget key).
  final String id;

  /// The most recent detection data for this box.
  Recognition detection;

  /// Consecutive frames this box was detected.
  int hitCount;

  /// Consecutive frames this box was NOT detected (since last hit).
  int missCount;

  /// Whether this box is currently visible to the user.
  bool isVisible;

  _TrackedBox({
    required this.id,
    required this.detection,
    this.hitCount = 1,
    this.missCount = 0,
    this.isVisible = false,
  });
}

/// Temporal Smoothing Engine for live object detection.
///
/// Eliminates bounding box flicker by requiring a detection to be
/// confirmed across multiple consecutive frames before it appears,
/// and persisting it for several frames after it disappears.
class DetectionTracker {
  // --- Tuning Constants ---

  /// Frames a detection must be seen consecutively before it shows up.
  static const int _appearThreshold = 3;

  /// Frames a detection must be absent consecutively before it is removed.
  static const int _disappearThreshold = 5;

  /// Minimum IoU to consider two bounding boxes the "same" detection.
  static const double _iouMatchThreshold = 0.25;

  // --- State ---
  final List<_TrackedBox> _tracked = [];
  int _nextId = 0;

  /// Process a new batch of raw detections from a single inference frame.
  /// Returns the current list of stabilized, visible [Recognition] objects.
  List<Recognition> update(List<Recognition> newDetections) {
    // Step 1: Match new detections to existing tracked boxes via IoU.
    final List<bool> newMatched = List.filled(newDetections.length, false);

    for (final tracked in _tracked) {
      int bestMatchIdx = -1;
      double bestIoU = _iouMatchThreshold;

      for (int i = 0; i < newDetections.length; i++) {
        if (newMatched[i]) continue;
        if (newDetections[i].label != tracked.detection.label) continue;

        final iou = _iou(tracked.detection.location, newDetections[i].location);
        if (iou > bestIoU) {
          bestIoU = iou;
          bestMatchIdx = i;
        }
      }

      if (bestMatchIdx != -1) {
        // Matched: update, increment hit, reset miss.
        tracked.detection = newDetections[bestMatchIdx];
        tracked.hitCount++;
        tracked.missCount = 0;
        newMatched[bestMatchIdx] = true;

        // Promote to visible once threshold is met.
        if (tracked.hitCount >= _appearThreshold) {
          tracked.isVisible = true;
        }
      } else {
        // Not matched this frame: increment miss count.
        tracked.missCount++;
        tracked.hitCount = 0;
      }
    }

    // Step 2: Remove boxes that have been absent too long.
    _tracked.removeWhere((t) => t.missCount >= _disappearThreshold);

    // Step 3: Register unmatched new detections as new candidates.
    for (int i = 0; i < newDetections.length; i++) {
      if (!newMatched[i]) {
        _tracked.add(_TrackedBox(
          id: 'det_${_nextId++}',
          detection: newDetections[i],
        ));
      }
    }

    // Step 4: Return only boxes that are confirmed visible.
    return _tracked
        .where((t) => t.isVisible)
        .map((t) => t.detection)
        .toList();
  }

  /// Clears all tracked state (e.g., when resuming live scan).
  void reset() {
    _tracked.clear();
    _nextId = 0;
  }

  /// Intersection over Union of two normalized [Rect] objects.
  static double _iou(Rect a, Rect b) {
    final double interLeft   = max(a.left,   b.left);
    final double interTop    = max(a.top,    b.top);
    final double interRight  = min(a.right,  b.right);
    final double interBottom = min(a.bottom, b.bottom);

    final double interW = max(0.0, interRight  - interLeft);
    final double interH = max(0.0, interBottom - interTop);
    final double interArea = interW * interH;

    if (interArea <= 0) return 0.0;

    final double unionArea =
        (a.width * a.height) + (b.width * b.height) - interArea;

    return unionArea <= 0 ? 0.0 : interArea / unionArea;
  }
}
