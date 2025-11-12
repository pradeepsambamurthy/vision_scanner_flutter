// lib/models/vision_models.dart
import 'dart:math' as math;

enum TestMode { distance, near, both }

enum Optotype { sloan, tumblingE, landoltC }

enum EyeSide { right, left }

class CalibrationResult {
  final double screenPxPerMm; // FR-2.1
  final double targetDistanceCm; // 300 (distance) or 40 (near) per FR-2/FR-3
  final double ambientLuma; // FR-2.3 (0..255 proxy)
  CalibrationResult({
    required this.screenPxPerMm,
    required this.targetDistanceCm,
    required this.ambientLuma,
  });
}

class ComplianceFlags {
  final bool goodLighting;
  final bool distanceLocked;
  final bool rightEyeCovered; // FR-12 / FR-14
  final bool leftEyeCovered;
  ComplianceFlags({
    required this.goodLighting,
    required this.distanceLocked,
    required this.rightEyeCovered,
    required this.leftEyeCovered,
  });
}

class StaircaseConfig {
  final double stepLogMAR; // 0.1 = ETDRS (FR-8)
  final int lettersPerLevel; // 5 typical (FR-9)
  final int reversalsToStop; // 2–3 (FR-8)
  const StaircaseConfig({
    this.stepLogMAR = 0.1,
    this.lettersPerLevel = 5,
    this.reversalsToStop = 2,
  });
}

/// Result for one eye: stores acuity in logMAR and exposes Snellen text.
/// Example: logMAR 0.0 → 20/20, 0.3 → 20/40, 0.5 → 20/63, etc.
class AcuityResult {
  final double logMAR;
  const AcuityResult(this.logMAR);

  /// Approximate Snellen (US) fraction.
  String get snellen {
    final denom = (20 * math.pow(10, logMAR)).round();
    return '20/$denom';
  }

  @override
  String toString() => '$snellen (logMAR ${logMAR.toStringAsFixed(2)})';
}
