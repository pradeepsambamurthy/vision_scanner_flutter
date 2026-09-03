import 'dart:math';

import 'package:flutter/material.dart';

import '../models/vision_models.dart' as vm;
import 'vision_math.dart';

class AcuityService {
  AcuityService._();

  static final AcuityService instance = AcuityService._();

  static const List<String> _letters = [
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
  ];

  final Random _rng = Random();

  late vm.StaircaseConfig cfg;
  late vm.CalibrationResult cal;
  late vm.EyeSide side;

  late double _currentLogMAR;

  int _shownAtLevel = 0;
  int _correctAtLevel = 0;
  int _reversals = 0;

  int _lastDirection = 0;

  String _currentLetter = 'C';

  bool _started = false;

  /// Smallest screening level permitted by this service.
  ///
  /// Approximate values:
  ///  0.0  = 20/20
  /// -0.1  = 20/16
  /// -0.2  = 20/13
  /// -0.3  = 20/10
  /// -0.4  = 20/8
  /// -0.5  = 20/6
  /// -0.6  = 20/5
  /// -0.7  = 20/4
  static const double minimumLogMAR = -0.7;

  /// Largest screening level.
  ///
  /// Around 20/320.
  static const double maximumLogMAR = 1.2;

  Future<void> start({
    required vm.EyeSide eye,
    required vm.CalibrationResult calibration,
    vm.StaircaseConfig? config,
    double startLogMAR = 0.5,
  }) async {
    side = eye;
    cal = calibration;
    cfg = config ?? const vm.StaircaseConfig();

    _currentLogMAR = startLogMAR.clamp(
      minimumLogMAR,
      maximumLogMAR,
    );

    _shownAtLevel = 0;
    _correctAtLevel = 0;
    _reversals = 0;
    _lastDirection = 0;

    _currentLetter = _pick();

    _started = true;
  }

  String _pick() {
    return _letters[
        _rng.nextInt(_letters.length)
    ];
  }

  String get currentLetter => _currentLetter;

  double get currentLogMAR => _currentLogMAR;

  String get currentSnellen {
    final denominator =
        (20 * pow(10, _currentLogMAR)).round();

    return '20/$denominator';
  }

  int get shownAtLevel => _shownAtLevel;

  int get correctAtLevel => _correctAtLevel;

  int get reversals => _reversals;

  /// Records whether the displayed letter was identified correctly.
  ///
  /// Returns true when the staircase stopping rule has been reached.
  bool submitAnswer(bool correct) {
    if (!_started) {
      return false;
    }

    _shownAtLevel++;

    if (correct) {
      _correctAtLevel++;
    }

    if (_shownAtLevel < cfg.lettersPerLevel) {
      _currentLetter = _pick();
      return false;
    }

    /*
      Require at least 60% of letters at the current level
      to move to a smaller/harder level.

      For five letters:
      3 or more correct = pass.
    */
    final requiredCorrect =
        (cfg.lettersPerLevel * 0.60).ceil();

    final passedLevel =
        _correctAtLevel >= requiredCorrect;

    /*
      -1 = smaller letters / harder
       1 = larger letters / easier
    */
    final direction =
        passedLevel ? -1 : 1;

    if (_lastDirection != 0 &&
        direction != _lastDirection) {
      _reversals++;
    }

    _lastDirection = direction;

    final nextValue =
        _currentLogMAR +
        direction * cfg.stepLogMAR;

    _currentLogMAR = nextValue.clamp(
      minimumLogMAR,
      maximumLogMAR,
    );

    _shownAtLevel = 0;
    _correctAtLevel = 0;

    _currentLetter = _pick();

    /*
      Also stop if the user reaches the smallest
      browser-screening level.
    */
    if (_currentLogMAR <= minimumLogMAR &&
        passedLevel) {
      return true;
    }

    /*
      Stop according to the configured staircase
      reversal rule.
    */
    return _reversals >=
        cfg.reversalsToStop;
  }

  Widget currentWidget(
    BuildContext context,
  ) {
    if (!_started) {
      return const SizedBox.shrink();
    }

    final px = optotypePixelHeight(
      distanceCm:
          cal.targetDistanceCm,
      screenPxPerMm:
          cal.screenPxPerMm,
      logMAR:
          _currentLogMAR,
    );

    return SizedBox(
      width: px,
      height: px,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          _currentLetter,
          style: const TextStyle(
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),
    );
  }

  vm.AcuityResult finish({
    vm.VisionCorrection correction =
        vm.VisionCorrection.none,
    bool belowRange = false,
  }) {
    return vm.AcuityResult(
      _currentLogMAR,
      eye: side,
      belowRange: belowRange,
      correction: correction,
      testDistanceCm:
          cal.targetDistanceCm,
    );
  }
}