import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/vision_models.dart';

class ComplianceService {
  ComplianceService._();
  static final instance = ComplianceService._();

  final _options = FaceDetectorOptions(
    enableTracking: false,
    enableContours: true,
    enableClassification: true,
    performanceMode: FaceDetectorMode.fast,
  );
  FaceDetector? _detector;

  Future<void> init() async {
    _detector ??= FaceDetector(options: _options);
  }

  Future<ComplianceFlags?> analyzeFrame(
    File image,
    EyeSide testingSide, {
    required double targetDistanceCm,
  }) async {
    await init();
    final input = InputImage.fromFile(image);
    final faces = await _detector!.processImage(input);
    if (faces.isEmpty) return null;
    final f = faces.first;

    // crude occlusion heuristic: if eye contour points are low-contrast / missing → "covered"
    final rightEye = f.contours[FaceContourType.rightEye];
    final leftEye = f.contours[FaceContourType.leftEye];
    final rightCovered = rightEye?.points.isEmpty ?? true;
    final leftCovered = leftEye?.points.isEmpty ?? true;

    final goodLight =
        true; // plug luma proxy from calibration if you capture frames
    final distanceLocked =
        true; // later: compare face size vs baseline to detect drift

    return ComplianceFlags(
      goodLighting: goodLight,
      distanceLocked: distanceLocked,
      rightEyeCovered: rightCovered,
      leftEyeCovered: leftCovered,
    );
  }
}
