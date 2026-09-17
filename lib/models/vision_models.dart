// lib/models/vision_models.dart

import 'dart:math' as math;

enum TestMode { distance, near, both }

enum Optotype { sloan, tumblingE, landoltC }

enum EyeSide { right, left, both }

enum VisionCorrection { none, distanceGlasses, readingGlasses, contactLenses }

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

  // ================================================================
  // STANDARD DISPLAY LABELS
  // ================================================================

  /// Returns the standard Snellen-style denominator for the
  /// logMAR levels used by PeekVision.
  ///
  /// This avoids browser-report labels such as 20/399 or 20/252.
  int get denominator {
    if (_isLevel(1.3)) return 400;
    if (_isLevel(1.2)) return 320;
    if (_isLevel(1.1)) return 250;
    if (_isLevel(1.0)) return 200;
    if (_isLevel(0.9)) return 160;
    if (_isLevel(0.8)) return 125;
    if (_isLevel(0.7)) return 100;
    if (_isLevel(0.6)) return 80;
    if (_isLevel(0.5)) return 63;
    if (_isLevel(0.4)) return 50;
    if (_isLevel(0.3)) return 40;
    if (_isLevel(0.2)) return 32;
    if (_isLevel(0.1)) return 25;
    if (_isLevel(0.0)) return 20;
    if (_isLevel(-0.1)) return 16;
    if (_isLevel(-0.2)) return 13;
    if (_isLevel(-0.3)) return 10;
    if (_isLevel(-0.4)) return 8;
    if (_isLevel(-0.5)) return 6;
    if (_isLevel(-0.6)) return 5;
    if (_isLevel(-0.7)) return 4;

    // Fallback if a future test introduces another logMAR value.
    return (20 * math.pow(10, logMAR)).round();
  }

  bool _isLevel(double value) {
    return (logMAR - value).abs() < 0.01;
  }

  /// Standardized Snellen-style screening label.
  String get snellen {
    return '20/$denominator';
  }

  // ================================================================
  // EYE LABEL
  // ================================================================

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

  // ================================================================
  // TEST DISTANCE
  // ================================================================

  String get testDistanceLabel {
    // Near vision stays at approximately 40 cm.
    if (testDistanceCm >= 35 && testDistanceCm <= 45) {
      return 'Approximately 40 cm / 16 in';
    }

    // For distances of 1 meter or more, show meters and feet.
    if (testDistanceCm >= 100) {
      final meters = testDistanceCm / 100.0;
      final feet = testDistanceCm / 30.48;

      return '${meters.toStringAsFixed(1)} m / '
          '${feet.toStringAsFixed(1)} ft';
    }

    // For shorter calibrated distance tests, show cm and inches.
    final inches = testDistanceCm / 2.54;

    return '${testDistanceCm.toStringAsFixed(0)} cm / '
        '${inches.toStringAsFixed(1)} in';
  }
  // ================================================================
  // SCREENING LEVEL
  // ================================================================

  String get screeningLevel {
    if (belowRange) {
      return 'Below measurable screening range';
    }

    return snellen;
  }

  // ================================================================
  // SIMPLE INTERPRETATION
  // ================================================================

  /// Simple description of the result.
  ///
  /// Detailed clinic-style interpretation is handled by
  /// report_screen.dart.
  String get plainLanguageResult {
    if (belowRange) {
      return 'Vision was below the range measured by this screening.';
    }

    if (denominator >= 320) {
      return 'Severe reduction compared with normal 20/20 visual acuity.';
    }

    if (denominator >= 200) {
      return 'Significant reduction compared with normal 20/20 visual acuity.';
    }

    if (denominator >= 125) {
      return 'Marked reduction compared with normal 20/20 visual acuity.';
    }

    if (denominator >= 80) {
      return 'Moderate reduction compared with normal 20/20 visual acuity.';
    }

    if (denominator >= 50) {
      return 'Reduced visual acuity compared with normal 20/20 vision.';
    }

    if (denominator >= 30) {
      return 'Mild reduction compared with normal 20/20 visual acuity.';
    }

    if (denominator == 25) {
      return 'Slightly below normal 20/20 visual acuity.';
    }

    if (denominator == 20) {
      return 'At normal 20/20 visual acuity.';
    }

    if (denominator >= 13) {
      return 'Better than normal 20/20 visual acuity during this screening.';
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
