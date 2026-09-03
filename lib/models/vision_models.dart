// lib/models/vision_models.dart

import 'dart:math' as math;

enum TestMode {
  distance,
  near,
  both,
}

enum Optotype {
  sloan,
  tumblingE,
  landoltC,
}

enum EyeSide {
  right,
  left,
  both,
}

enum VisionCorrection {
  none,
  distanceGlasses,
  readingGlasses,
  contactLenses,
}

extension VisionCorrectionLabel on VisionCorrection {
  String get label {
    switch (this) {
      case VisionCorrection.none:
        return 'None';

      case VisionCorrection.distanceGlasses:
        return 'Wearing usual distance glasses';

      case VisionCorrection.readingGlasses:
        return 'Wearing reading glasses';

      case VisionCorrection.contactLenses:
        return 'Wearing contact lenses';
    }
  }
}

class CalibrationResult {
  final double screenPxPerMm;

  /// Typical target:
  /// 300 cm for distance
  /// 40 cm for near
  final double targetDistanceCm;

  /// 0–255 proxy
  final double ambientLuma;

  const CalibrationResult({
    required this.screenPxPerMm,
    required this.targetDistanceCm,
    required this.ambientLuma,
  });
}

class ComplianceFlags {
  final bool goodLighting;
  final bool distanceLocked;
  final bool rightEyeCovered;
  final bool leftEyeCovered;

  const ComplianceFlags({
    required this.goodLighting,
    required this.distanceLocked,
    required this.rightEyeCovered,
    required this.leftEyeCovered,
  });
}

class StaircaseConfig {
  final double stepLogMAR;
  final int lettersPerLevel;
  final int reversalsToStop;

  const StaircaseConfig({
    this.stepLogMAR = 0.1,
    this.lettersPerLevel = 5,
    this.reversalsToStop = 2,
  });
}

/// Result for one eye or both eyes together.
///
/// Stores:
/// - screening level in logMAR
/// - which eye was tested
/// - whether the result was below the measurable range
/// - correction used during the test
/// - test distance
///
/// PeekVision results are preliminary browser-based screening
/// results and are not a clinical diagnosis or prescription.
class AcuityResult {
  final double logMAR;

  final EyeSide eye;

  final bool belowRange;

  final VisionCorrection correction;

  final double testDistanceCm;

  const AcuityResult(
    this.logMAR, {
    this.eye = EyeSide.right,
    this.belowRange = false,
    this.correction = VisionCorrection.none,
    this.testDistanceCm = 300,
  });

  /// Snellen denominator.
  ///
  /// Examples:
  /// logMAR 0.0  -> 20
  /// logMAR 0.3  -> about 40
  /// logMAR -0.3 -> about 10
  int get denominator {
    return (20 * math.pow(10, logMAR)).round();
  }

  /// Approximate Snellen screening level.
  String get snellen {
    return '20/$denominator';
  }

  String get eyeLabel {
    switch (eye) {
      case EyeSide.right:
        return 'Right Eye (OD)';

      case EyeSide.left:
        return 'Left Eye (OS)';

      case EyeSide.both:
        return 'Both Eyes (OU)';
    }
  }

  String get testDistanceLabel {
    if (testDistanceCm >= 250) {
      return 'Approximately 10 ft / 3 m';
    }

    if (testDistanceCm >= 35 &&
        testDistanceCm <= 45) {
      return 'Approximately 40 cm / 16 in';
    }

    return '${testDistanceCm.toStringAsFixed(0)} cm';
  }

  String get screeningLevel {
    if (belowRange) {
      return 'Below measurable screening range';
    }

    return snellen;
  }

  /// Simple description of the result.
  ///
  /// Detailed clinic-style interpretation is handled by
  /// report_screen.dart.
  String get plainLanguageResult {
    if (belowRange) {
      return 'Vision was below the range measured by this screening.';
    }

    if (denominator >= 125) {
      return 'Significant reduction compared with the standard 20/20 reference.';
    }

    if (denominator >= 80) {
      return 'Marked reduction compared with the standard 20/20 reference.';
    }

    if (denominator >= 50) {
      return 'Moderate reduction compared with the standard 20/20 reference.';
    }

    if (denominator >= 30) {
      return 'Mild reduction compared with the standard 20/20 reference.';
    }

    if (denominator == 25) {
      return 'Slightly below the standard 20/20 reference.';
    }

    if (denominator == 20) {
      return 'At the standard 20/20 reference level.';
    }

    if (denominator >= 13) {
      return 'Better than the standard 20/20 screening level.';
    }

    if (denominator >= 8) {
      return 'Very small letters were readable during this browser screening.';
    }

    return 'Extremely small letters were readable during this browser screening.';
  }

  @override
  String toString() {
    return screeningLevel;
  }
}