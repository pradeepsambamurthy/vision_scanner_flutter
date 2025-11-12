import 'dart:math';
import 'package:flutter/material.dart';
import '../models/vision_models.dart';
import 'vision_math.dart';

class AcuityResult {
  final double logMAR;
  String get snellen => logMARToSnellen(logMAR);
  const AcuityResult(this.logMAR);
}

class AcuityService {
  AcuityService._();
  static final instance = AcuityService._();

  final _letters = [
    'C',
    'D',
    'H',
    'K',
    'N',
    'O',
    'R',
    'S',
    'V',
    'Z',
  ]; // Sloan set
  final _rng = Random();

  // state
  late StaircaseConfig cfg;
  late CalibrationResult cal;
  late EyeSide side;
  late double _currentLogMAR; // moving target
  int _shownAtLevel = 0;
  int _correctAtLevel = 0;
  int _reversals = 0;
  int _lastDirection = 0; // -1 down (harder), +1 up (easier)

  String _currentLetter = 'C';

  Future<void> start({
    required EyeSide eye,
    required CalibrationResult calibration,
    StaircaseConfig? config,
    double startLogMAR = 0.5, // ~20/63 initial guess
  }) async {
    side = eye;
    cal = calibration;
    cfg = config ?? const StaircaseConfig();
    _currentLogMAR = startLogMAR;
    _shownAtLevel = 0;
    _correctAtLevel = 0;
    _reversals = 0;
    _lastDirection = 0;
    _currentLetter = _pick();
  }

  String _pick() => _letters[_rng.nextInt(_letters.length)];

  /// Returns true when test is finished for this eye
  bool submitAnswer(bool correct) {
    _shownAtLevel++;
    if (correct) _correctAtLevel++;

    final doneThisLevel = _shownAtLevel >= cfg.lettersPerLevel;
    if (!doneThisLevel) {
      _currentLetter = _pick();
      return false;
    }

    // decide direction
    final pass =
        _correctAtLevel >= (cfg.lettersPerLevel * 0.6).ceil(); // >=60% correct
    final dir = pass ? -1 : 1; // -1: go smaller (harder), 1: bigger (easier)
    if (_lastDirection != 0 && dir != _lastDirection) _reversals++;
    _lastDirection = dir;

    _currentLogMAR = (_currentLogMAR + dir * cfg.stepLogMAR).clamp(
      0.0,
      1.2,
    ); // bounds ~20/20 .. 20/320

    _shownAtLevel = 0;
    _correctAtLevel = 0;
    _currentLetter = _pick();

    return _reversals >= cfg.reversalsToStop;
  }

  Widget currentWidget(BuildContext context) {
    final px = optotypePixelHeight(
      distanceCm: cal.targetDistanceCm,
      screenPxPerMm: cal.screenPxPerMm,
      logMAR: _currentLogMAR,
    );
    return SizedBox(
      width: px,
      height: px,
      child: FittedBox(
        child: Text(
          _currentLetter,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  AcuityResult finish() => AcuityResult(_currentLogMAR);
}
