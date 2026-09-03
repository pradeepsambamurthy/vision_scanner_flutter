import 'dart:ui' as ui;

import '../models/vision_models.dart';

class CalibrationService {
  CalibrationService._();

  static final CalibrationService instance =
      CalibrationService._();

  /// Standard ISO/IEC 7810 ID-1 card width.
  static const double referenceCardWidthMm = 85.60;

  /// Builds a calibration result from a user-adjusted
  /// on-screen reference card width.
  CalibrationResult fromReferenceCard({
    required double cardWidthPx,
    required TestMode mode,
  }) {
    final pxPerMm =
        cardWidthPx / referenceCardWidthMm;

    final targetDistanceCm =
        mode == TestMode.near
            ? 40.0
            : 300.0;

    return CalibrationResult(
      screenPxPerMm: pxPerMm,
      targetDistanceCm: targetDistanceCm,
      ambientLuma: 200,
    );
  }

  /// Temporary fallback only when physical calibration
  /// has not been completed.
  ///
  /// Results produced with this fallback should be labeled
  /// as uncalibrated browser-screening results.
  Future<CalibrationResult> quickDefaults({
    required TestMode mode,
  }) async {
    const fallbackPxPerMm = 3.0;

    final targetDistanceCm =
        mode == TestMode.near
            ? 40.0
            : 300.0;

    return CalibrationResult(
      screenPxPerMm: fallbackPxPerMm,
      targetDistanceCm: targetDistanceCm,
      ambientLuma: 200,
    );
  }

  double lumaFromImage(ui.Image frame) {
    // Placeholder until ambient-light estimation is implemented.
    return 200;
  }
}