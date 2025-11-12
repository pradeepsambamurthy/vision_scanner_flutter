import 'dart:math';

/// px for an optotype line at a given distance so that the stroke width ≈ 1 arc-min
/// and overall letter height ≈ 5 arc-min (Snellen/ETDRS)
double optotypePixelHeight({
  required double distanceCm,
  required double screenPxPerMm,
  required double logMAR, // 0.0=20/20, 0.3≈20/40, 1.0≈20/200
}) {
  // at 20/20, 5 arc-min total height
  final arcMin = 5 * pow(10, logMAR); // scales per logMAR
  final radians = (arcMin / 60.0) * (pi / 180);
  final mm = 2 * distanceCm * 10 * tan(radians / 2);
  return mm * screenPxPerMm;
}

String logMARToSnellen(double logmar) {
  final denom = (20 * pow(10, logmar)).round();
  return '20/$denom';
}
