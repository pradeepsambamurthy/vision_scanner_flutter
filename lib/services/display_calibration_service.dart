import 'dart:math' as math;

class DisplayCalibrationService {
  DisplayCalibrationService._();

  static final DisplayCalibrationService instance =
      DisplayCalibrationService._();

  // CSS/browser fallback only.
  // Real calibration should replace this.
  static const double _fallbackPixelsPerMm = 96.0 / 25.4;

  double? _pixelsPerMm;

  bool get isCalibrated => _pixelsPerMm != null;

  double get pixelsPerMm => _pixelsPerMm ?? _fallbackPixelsPerMm;

  void calibrate({
    required double logicalPixels,
    required double physicalMillimeters,
  }) {
    if (logicalPixels <= 0 || physicalMillimeters <= 0) {
      return;
    }

    _pixelsPerMm = logicalPixels / physicalMillimeters;
  }

  void clearCalibration() {
    _pixelsPerMm = null;
  }

  /// Overall optotype height.
  ///
  /// A Snellen optotype subtends approximately 5 arcminutes
  /// at the threshold acuity.
  double optotypeHeightMm({
    required double logMar,
    required double distanceCm,
  }) {
    final acuityScale = math.pow(10.0, logMar).toDouble();

    final angleDegrees = (5.0 / 60.0) * acuityScale;

    final angleRadians = angleDegrees * math.pi / 180.0;

    final distanceMm = distanceCm * 10.0;

    return distanceMm * math.tan(angleRadians);
  }

  double optotypeHeightPx({
    required double logMar,
    required double distanceCm,
  }) {
    final physicalHeightPx =
        optotypeHeightMm(logMar: logMar, distanceCm: distanceCm) * pixelsPerMm;

    // Flutter fontSize is not the same as visible capital-letter height.
    // This compensates so the rendered optotype is closer to the
    // intended physical height.
    const fontCompensation = 1.35;

    return physicalHeightPx * fontCompensation;
  }

  /// Calculates the longest distance at which a complete
  /// multi-letter row can fit on the calibrated screen.
  double maximumDistanceForLineCm({
    required double availableWidthPx,
    required double largestLogMar,
    int lettersPerLine = 5,
    double spacingFraction = 0.25,
    double maximumDistanceCm = 300,
  }) {
    if (availableWidthPx <= 0) {
      return maximumDistanceCm;
    }

    final availableWidthMm = availableWidthPx / pixelsPerMm;

    final rowFactor = lettersPerLine + ((lettersPerLine - 1) * spacingFraction);

    final maximumLetterHeightMm = availableWidthMm / rowFactor;

    final acuityScale = math.pow(10.0, largestLogMar).toDouble();

    final angleDegrees = (5.0 / 60.0) * acuityScale;

    final angleRadians = angleDegrees * math.pi / 180.0;

    final distanceMm = maximumLetterHeightMm / math.tan(angleRadians);

    final distanceCm = distanceMm / 10.0;

    return distanceCm.clamp(25.0, maximumDistanceCm).toDouble();
  }
}
