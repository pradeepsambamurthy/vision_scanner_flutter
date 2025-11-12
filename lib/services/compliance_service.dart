// lib/services/compliance_service_stub.dart
// Safe no-op compliance checker for web/desktop builds.
// This avoids pulling in ML Kit or dart:io so your Chrome build stays happy.

import '../models/vision_models.dart';

// Provide a dummy File type so the method signature matches the mobile version
// without importing dart:io (which isn't available on web).
typedef File = Object;

class ComplianceService {
  ComplianceService._();
  static final ComplianceService instance = ComplianceService._();

  /// No-op on web/desktop.
  Future<void> init() async {}

  /// Returns a permissive, always-OK result so the UI flow continues smoothly
  /// when running on platforms where we don't do camera/ML checks.
  Future<ComplianceFlags?> analyzeFrame(
    File image,
    EyeSide testingSide, {
    required double targetDistanceCm,
  }) async {
    return ComplianceFlags(
      goodLighting: true,
      distanceLocked: true,
      rightEyeCovered: false,
      leftEyeCovered: false,
    );
  }
}
