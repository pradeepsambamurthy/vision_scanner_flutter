import 'dart:math';

/// Calculates the required physical optotype height in pixels.
///
/// A standard 20/20 optotype subtends approximately 5 arc-minutes
/// vertically at the test distance.
///
/// logMAR examples:
///  1.0  ≈ 20/200
///  0.3  ≈ 20/40
///  0.0  = 20/20
/// -0.1  ≈ 20/16
/// -0.3  ≈ 20/10
/// -0.7  ≈ 20/4
double optotypePixelHeight({
  required double distanceCm,
  required double screenPxPerMm,
  required double logMAR,
}) {
  // Total angular height of the optotype.
  final arcMinutes =
      5.0 * pow(10, logMAR);

  // Convert arc-minutes to radians.
  final radians =
      (arcMinutes / 60.0) *
      (pi / 180.0);

  // Convert test distance from cm to mm.
  final distanceMm =
      distanceCm * 10.0;

  // Physical height of the optotype in millimeters.
  final heightMm =
      2.0 *
      distanceMm *
      tan(radians / 2.0);

  // Convert physical millimeters to calibrated screen pixels.
  return heightMm * screenPxPerMm;
}

/// Converts logMAR to an approximate Snellen screening level.
String logMARToSnellen(
  double logMAR,
) {
  final denominator =
      (20 * pow(10, logMAR)).round();

  return '20/$denominator';
}

/// Returns the Snellen denominator only.
int logMARToSnellenDenominator(
  double logMAR,
) {
  return (20 * pow(10, logMAR)).round();
}

/// Checks whether an optotype has enough physical screen pixels
/// to be displayed meaningfully.
///
/// Very small optotypes may become only a few pixels high,
/// especially during near testing. Those levels should not be
/// presented as valid screening measurements.
///
/// 5 pixels is a conservative absolute minimum.
/// A future version could use an even stricter threshold.
bool canRenderOptotype({
  required double distanceCm,
  required double screenPxPerMm,
  required double logMAR,
  double minimumPixelHeight = 5.0,
}) {
  final height = optotypePixelHeight(
    distanceCm: distanceCm,
    screenPxPerMm: screenPxPerMm,
    logMAR: logMAR,
  );

  return height >= minimumPixelHeight;
}