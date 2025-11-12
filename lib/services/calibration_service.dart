import 'dart:ui' as ui;
import '../models/vision_models.dart';

class CalibrationService {
  CalibrationService._();
  static final instance = CalibrationService._();

  // Quick-and-safe defaults if user skips precise calibration
  Future<CalibrationResult> quickDefaults({required TestMode mode}) async {
    // Fallback PPI ~ 3.0 px/mm for many phones; replace with device DB later
    const pxPerMm = 3.0;
    final target = mode == TestMode.near ? 40.0 : 300.0;
    // ambient luma proxy unavailable here → return 200 as "OK"
    return CalibrationResult(
      screenPxPerMm: pxPerMm,
      targetDistanceCm: target,
      ambientLuma: 200,
    );
  }

  double lumaFromImage(ui.Image frame) {
    // placeholder: compute average Y from sample pixels if you grab preview frames
    return 200;
  }
}
