import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/vision_models.dart' as vm;
import '../services/display_calibration_service.dart';
import '../services/report_service.dart';
import '../utils/vision_test_profile.dart';
import '../widgets/display_calibration_dialog.dart';

enum _Eye { right, left, both }

enum _Stage {
  idleRight,
  testingRight,
  idleLeft,
  testingLeft,
  idleBoth,
  testingBoth,
  finished,
}

class AcuityTestScreen extends StatefulWidget {
  const AcuityTestScreen({super.key, this.mode = vm.TestMode.distance});

  final vm.TestMode mode;

  @override
  State<AcuityTestScreen> createState() => _AcuityTestScreenState();
}

class _AcuityTestScreenState extends State<AcuityTestScreen> {
  static const List<double> _steps = [
    0.4, // 20/50
    0.3, // 20/40
    0.2, // 20/32
    0.1, // 20/25
    0.0, // 20/20
    -0.1, // 20/16
    -0.2, // 20/13
    -0.3, // 20/10
    -0.4, // 20/8
    -0.5, // 20/6
    -0.6, // 20/5
    -0.7, // 20/4
  ];

  static const String _alphabet = 'CDHKNORSVZ';

  final math.Random _rng = math.Random();

  vm.TestMode _mode = vm.TestMode.distance;
  vm.VisionCorrection _correction = vm.VisionCorrection.none;

  _Stage _stage = _Stage.idleRight;

  int _index = 0;
  int _lastPassed = -1;

  String _line = '';

  double? _resultRight;
  double? _resultLeft;
  double? _resultBoth;

  bool _rightBelowRange = false;
  bool _leftBelowRange = false;
  bool _bothBelowRange = false;

  // Stores the test distance and device profile for the current test.
  VisionTestProfile? _testProfile;

  @override
  void initState() {
    super.initState();

    _mode = widget.mode;
    _generateLine();
  }

  // ================================================================
  // BASIC HELPERS
  // ================================================================

  double get _testDistanceCm {
    final profile = _testProfile;

    if (profile != null) {
      return profile.distanceCm;
    }

    return _mode == vm.TestMode.near ? 40.0 : 300.0;
  }

  String get _testDistanceText {
    final profile = _testProfile;

    if (profile != null) {
      return profile.distanceLabel;
    }

    if (_mode == vm.TestMode.near) {
      return '40 cm / 15.7 in';
    }

    return 'Calculated after screen calibration';
  }

  void _generateLine() {
    _line = List.generate(
      5,
      (_) => _alphabet[_rng.nextInt(_alphabet.length)],
    ).join(' ');
  }

  void _resetForEye() {
    _index = 0;
    _lastPassed = -1;

    _generateLine();
  }

  void _resetAll() {
    setState(() {
      _stage = _Stage.idleRight;

      _resultRight = null;
      _resultLeft = null;
      _resultBoth = null;

      _rightBelowRange = false;
      _leftBelowRange = false;
      _bothBelowRange = false;

      // Keep the screen calibration, but recalculate the
      // testing profile when the test starts again.
      _testProfile = null;

      _resetForEye();
    });
  }

  String _snellen(double logMAR) {
    final denominator = (20 * math.pow(10, logMAR)).round();

    return '20/$denominator';
  }

  int _denominator(double logMAR) {
    return (20 * math.pow(10, logMAR)).round();
  }

  String _screeningLevel(double value, {required bool belowRange}) {
    if (belowRange) {
      return 'Below 20/50 screening range';
    }

    return _snellen(value);
  }

  // ================================================================
  // TEST PROFILE / CALIBRATION
  // ================================================================

  Future<bool> _prepareTestProfile() async {
    if (!DisplayCalibrationService.instance.isCalibrated) {
      final calibrated = await showDisplayCalibrationDialog(context);

      if (!calibrated || !mounted) {
        return false;
      }
    }

    final VisionTestProfile profile;

    if (_mode == vm.TestMode.near) {
      // Near vision remains at 40 cm on phone, tablet and desktop.
      profile = VisionTestProfile.near(context);
    } else {
      // The Standard Distance Test begins at 20/50.
      // PeekVision calculates the longest appropriate distance
      // for this calibrated display, up to 3 meters.
      profile = VisionTestProfile.distance(
        context: context,
        largestLogMar: _steps.first,
      );
    }

    if (!mounted) {
      return false;
    }

    setState(() {
      _testProfile = profile;
    });

    return true;
  }

  // ================================================================
  // HUMAN-READABLE RESULT
  // ================================================================

  String _humanResultLabel(double value, {required bool belowRange}) {
    if (belowRange) {
      return 'Could not read the largest line';
    }

    final d = _denominator(value);

    if (d >= 40) {
      return 'Some reduction seen';
    }

    if (d >= 30) {
      return 'Mild reduction seen';
    }

    if (d >= 20) {
      return 'Clear in this screening';
    }

    if (d >= 13) {
      return 'Sharper than the standard 20/20 level';
    }

    if (d >= 8) {
      return 'Very small letters were readable';
    }

    return 'Extremely small letters were readable';
  }

  String _simpleMeaning(
    double value, {
    required String eyeLabel,
    required bool belowRange,
  }) {
    final type = _mode == vm.TestMode.distance ? 'distance' : 'near';

    if (belowRange) {
      return '$eyeLabel could not read the largest line presented during '
          'this $type screening. Repeat the test under the recommended '
          'conditions. If the same result occurs again, consider a '
          'comprehensive eye examination.';
    }

    final d = _denominator(value);

    if (d >= 40) {
      return '$eyeLabel showed some reduction in $type visual acuity. '
          'Repeating the screening under ideal conditions may be helpful.';
    }

    if (d >= 30) {
      return '$eyeLabel showed a mild reduction in $type visual acuity '
          'during this screening.';
    }

    if (d >= 20) {
      return '$eyeLabel reached approximately the standard 20/20 screening '
          'range or close to it. No obvious reduction was seen under the '
          'test conditions.';
    }

    if (d >= 13) {
      return '$eyeLabel was able to read letters smaller than the standard '
          '20/20 screening level. This represents strong performance under '
          'the current browser test conditions.';
    }

    return '$eyeLabel reached a very small letter level during this browser '
        'screening. Display calibration and the selected viewing distance '
        'were used to size the letters, but this remains a browser-based '
        'screening rather than a professionally calibrated clinical chart.';
  }

  String _compareEyes() {
    if (_resultRight == null || _resultLeft == null) {
      return 'A right-versus-left eye comparison is not available.';
    }

    if (_rightBelowRange && _leftBelowRange) {
      return 'Both eyes were below the range measured by this screening.';
    }

    if (_rightBelowRange) {
      return 'The RIGHT eye (OD) performed weaker than the LEFT eye (OS). '
          'If this difference remains when you repeat the screening, '
          'consider a comprehensive eye examination.';
    }

    if (_leftBelowRange) {
      return 'The LEFT eye (OS) performed weaker than the RIGHT eye (OD). '
          'If this difference remains when you repeat the screening, '
          'consider a comprehensive eye examination.';
    }

    final rightD = _denominator(_resultRight!);

    final leftD = _denominator(_resultLeft!);

    if ((rightD - leftD).abs() <= 5) {
      return 'The RIGHT eye (OD) and LEFT eye (OS) produced similar '
          'screening results.';
    }

    if (rightD > leftD) {
      return 'The RIGHT eye (OD) performed weaker than the LEFT eye (OS) '
          'during this screening.';
    }

    return 'The LEFT eye (OS) performed weaker than the RIGHT eye (OD) '
        'during this screening.';
  }

  String _bothEyesMeaning() {
    if (_resultBoth == null) {
      return 'Both-eyes screening was not completed.';
    }

    final type = _mode == vm.TestMode.distance ? 'distance' : 'near';

    if (_bothBelowRange) {
      return 'With both eyes open, the largest line could not be read during '
          'this $type screening.';
    }

    final d = _denominator(_resultBoth!);

    if (d >= 40) {
      return 'With both eyes open, some reduction in $type vision was seen '
          'during this screening.';
    }

    if (d >= 30) {
      return 'With both eyes open, a mild reduction in $type vision was seen.';
    }

    if (d >= 20) {
      return 'With both eyes open, $type vision appeared generally clear '
          'under the screening conditions.';
    }

    return 'With both eyes open, very small letters were readable during '
        'this browser screening. The calibrated display size and selected '
        'viewing distance were used, but very small-letter results should '
        'still be interpreted as screening information rather than a '
        'clinical measurement.';
  }

  // ================================================================
  // LETTER SIZE
  // ================================================================

  double _fontFor(double logMAR) {
    final profile = _testProfile;

    if (profile == null) {
      return 32.0;
    }

    return DisplayCalibrationService.instance.optotypeHeightPx(
      logMar: logMAR,
      distanceCm: profile.distanceCm,
    );
  }

  // ================================================================
  // SAVE RESULTS
  // ================================================================

  Future<void> _saveResults() async {
    if (_resultRight == null || _resultLeft == null || _resultBoth == null) {
      return;
    }

    ReportService.instance.updateAcuityModeAware(
      mode: _mode,
      right: vm.AcuityResult(
        _resultRight!,
        eye: vm.EyeSide.right,
        belowRange: _rightBelowRange,
        correction: _correction,
        testDistanceCm: _testDistanceCm,
      ),
      left: vm.AcuityResult(
        _resultLeft!,
        eye: vm.EyeSide.left,
        belowRange: _leftBelowRange,
        correction: _correction,
        testDistanceCm: _testDistanceCm,
      ),
      both: vm.AcuityResult(
        _resultBoth!,
        eye: vm.EyeSide.both,
        belowRange: _bothBelowRange,
        correction: _correction,
        testDistanceCm: _testDistanceCm,
      ),
    );
  }

  Future<void> _goReport() async {
    if (!mounted) {
      return;
    }

    await Navigator.pushNamed(
      context,
      '/report',
      arguments: {'completed': _mode},
    );
  }

  Future<void> _autoSaveAndGoToReport() async {
    await _saveResults();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Screening results saved. Opening report...'),
        duration: Duration(milliseconds: 800),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 150));

    await _goReport();
  }

  Future<void> _saveToReport() async {
    await _saveResults();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Screening results saved.')));
  }

  // ================================================================
  // TEST FLOW
  // ================================================================

  Future<void> _startRight() async {
    final ready = await _prepareTestProfile();

    if (!ready || !mounted) {
      return;
    }

    setState(() {
      _stage = _Stage.testingRight;
    });
  }

  void _startLeft() {
    if (_testProfile == null) {
      return;
    }

    setState(() {
      _stage = _Stage.testingLeft;
    });
  }

  void _startBoth() {
    if (_testProfile == null) {
      return;
    }

    setState(() {
      _stage = _Stage.testingBoth;
    });
  }

  void _markPass() {
    if (_index < _steps.length - 1) {
      setState(() {
        _lastPassed = _index;
        _index++;

        _generateLine();
      });

      return;
    }

    _lastPassed = _index;

    _finishCurrentEye(belowRange: false);
  }

  void _markFail() {
    _finishCurrentEye(belowRange: _lastPassed < 0);
  }

  void _finishCurrentEye({required bool belowRange}) {
    final result = _lastPassed >= 0 ? _steps[_lastPassed] : _steps.first;

    bool finishedAll = false;

    setState(() {
      if (_stage == _Stage.testingRight) {
        _resultRight = result;
        _rightBelowRange = belowRange;

        _stage = _Stage.idleLeft;

        _resetForEye();
      } else if (_stage == _Stage.testingLeft) {
        _resultLeft = result;
        _leftBelowRange = belowRange;

        _stage = _Stage.idleBoth;

        _resetForEye();
      } else if (_stage == _Stage.testingBoth) {
        _resultBoth = result;
        _bothBelowRange = belowRange;

        _stage = _Stage.finished;

        finishedAll = true;
      }
    });

    if (finishedAll) {
      _autoSaveAndGoToReport();
    }
  }

  void _switchModeAndReset(vm.TestMode mode) {
    setState(() {
      _mode = mode;

      _stage = _Stage.idleRight;

      _resultRight = null;
      _resultLeft = null;
      _resultBoth = null;

      _rightBelowRange = false;
      _leftBelowRange = false;
      _bothBelowRange = false;

      _correction = vm.VisionCorrection.none;

      // The new mode needs its own distance profile.
      _testProfile = null;

      _resetForEye();
    });
  }

  // ================================================================
  // MAIN SCREEN
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final title = _mode == vm.TestMode.distance
        ? 'Free Online Distance Visual Acuity Test'
        : 'Free Online Near Vision Test';

    final isMobile = MediaQuery.of(context).size.width < 600;

    final isActivelyTesting =
        _stage == _Stage.testingRight ||
        _stage == _Stage.testingLeft ||
        _stage == _Stage.testingBoth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!(isMobile && isActivelyTesting))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _mode == vm.TestMode.distance
                      ? 'Calibrate your display first. PeekVision will then '
                            'calculate an appropriate viewing distance for this '
                            'screen and show progressively smaller letters.'
                      : 'Calibrate your display first, then keep the screen '
                            'approximately 40 cm / 16 in from your eyes while '
                            'reading progressively smaller letters.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: Card(
            color: Colors.white,
            elevation: 0,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!(isMobile && isActivelyTesting)) ...[
                    Row(
                      children: [
                        const Text(
                          'Test:',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: DropdownButtonFormField<vm.TestMode>(
                            initialValue: _mode,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: vm.TestMode.distance,
                                child: Text('Distance vision'),
                              ),
                              DropdownMenuItem(
                                value: vm.TestMode.near,
                                child: Text('Near / reading vision'),
                              ),
                            ],
                            onChanged: (mode) {
                              if (mode != null && mode != _mode) {
                                _switchModeAndReset(mode);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<vm.VisionCorrection>(
                      initialValue: _correction,
                      decoration: const InputDecoration(
                        labelText: 'Vision correction used during this test',
                        border: OutlineInputBorder(),
                        helperText: 'Choose what you are wearing right now.',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: vm.VisionCorrection.none,
                          child: Text('No glasses or contacts'),
                        ),
                        DropdownMenuItem(
                          value: vm.VisionCorrection.distanceGlasses,
                          child: Text('Distance glasses'),
                        ),
                        DropdownMenuItem(
                          value: vm.VisionCorrection.readingGlasses,
                          child: Text('Reading glasses'),
                        ),
                        DropdownMenuItem(
                          value: vm.VisionCorrection.contactLenses,
                          child: Text('Contact lenses'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _correction = value;
                        });
                      },
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Test distance: $_testDistanceText',
                      style: const TextStyle(color: Colors.black54),
                    ),

                    if (_testProfile != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${_testProfile!.deviceLabel} • '
                        '${DisplayCalibrationService.instance.isCalibrated ? 'Display calibrated' : 'Display not calibrated'}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],

                  Expanded(child: _buildStage()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case _Stage.idleRight:
        return _CalibrationPanel(
          mode: _mode,
          title: 'Step 1 of 3 — Right Eye (OD)',
          coverEyeText: 'Cover your LEFT eye. Read using only your RIGHT eye.',
          buttonText: DisplayCalibrationService.instance.isCalibrated
              ? 'Start Right Eye'
              : 'Calibrate & Start Right Eye',
          distanceText: _testDistanceText,
          deviceText: _testProfile?.deviceLabel,
          onPressed: _startRight,
        );

      case _Stage.testingRight:
        return _TestRun(
          mode: _mode,
          eye: _Eye.right,
          index: _index,
          line: _line,
          steps: _steps,
          fontFor: _fontFor,
          snellen: _snellen,
          distanceText: _testDistanceText,
          onPass: _markPass,
          onFail: _markFail,
        );

      case _Stage.idleLeft:
        return _CalibrationPanel(
          mode: _mode,
          title: 'Step 2 of 3 — Left Eye (OS)',
          coverEyeText: 'Cover your RIGHT eye. Read using only your LEFT eye.',
          buttonText: 'Start Left Eye',
          distanceText: _testDistanceText,
          deviceText: _testProfile?.deviceLabel,
          onPressed: _startLeft,
        );

      case _Stage.testingLeft:
        return _TestRun(
          mode: _mode,
          eye: _Eye.left,
          index: _index,
          line: _line,
          steps: _steps,
          fontFor: _fontFor,
          snellen: _snellen,
          distanceText: _testDistanceText,
          onPass: _markPass,
          onFail: _markFail,
        );

      case _Stage.idleBoth:
        return _CalibrationPanel(
          mode: _mode,
          title: 'Step 3 of 3 — Both Eyes (OU)',
          coverEyeText: 'Keep BOTH eyes open.',
          buttonText: 'Start Both Eyes',
          distanceText: _testDistanceText,
          deviceText: _testProfile?.deviceLabel,
          onPressed: _startBoth,
        );

      case _Stage.testingBoth:
        return _TestRun(
          mode: _mode,
          eye: _Eye.both,
          index: _index,
          line: _line,
          steps: _steps,
          fontFor: _fontFor,
          snellen: _snellen,
          distanceText: _testDistanceText,
          onPass: _markPass,
          onFail: _markFail,
        );

      case _Stage.finished:
        return _FinishPanel(
          mode: _mode,
          right: _resultRight!,
          left: _resultLeft!,
          both: _resultBoth!,
          rightBelowRange: _rightBelowRange,
          leftBelowRange: _leftBelowRange,
          bothBelowRange: _bothBelowRange,
          screeningLevel: _screeningLevel,
          resultLabel: _humanResultLabel,
          meaning: _simpleMeaning,
          bothEyesMeaning: _bothEyesMeaning,
          eyeComparison: _compareEyes,
          testDistance: _testDistanceText,
          deviceLabel: _testProfile?.deviceLabel ?? 'Unknown device',
          onSave: _saveToReport,
          onRetest: _resetAll,
          onStartOtherMode: () => _switchModeAndReset(
            _mode == vm.TestMode.distance
                ? vm.TestMode.near
                : vm.TestMode.distance,
          ),
        );
    }
  }
}

// ================================================================
// PRE-TEST PANEL
// ================================================================

class _CalibrationPanel extends StatelessWidget {
  const _CalibrationPanel({
    required this.mode,
    required this.title,
    required this.coverEyeText,
    required this.buttonText,
    required this.distanceText,
    required this.onPressed,
    this.deviceText,
  });

  final vm.TestMode mode;
  final String title;
  final String coverEyeText;
  final String buttonText;
  final String distanceText;
  final String? deviceText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final distanceInstruction = mode == vm.TestMode.distance
        ? distanceText == 'Calculated after screen calibration'
              ? 'PeekVision will calculate the testing distance after '
                    'screen calibration.'
              : 'Stay $distanceText from the screen.'
        : 'Keep the screen approximately $distanceText from your eyes.';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),

          const SizedBox(height: 12),

          Text(
            distanceInstruction,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          if (deviceText != null) ...[
            const SizedBox(height: 4),
            Text(
              '$deviceText • Display calibrated',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],

          const SizedBox(height: 8),

          Text(
            coverEyeText,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 12),

          const Text(
            'You will start with larger letters. If you can read them, '
            'progressively smaller letters will be shown. Select '
            '“I Can’t Read” when you can no longer clearly read the line.',
            style: TextStyle(height: 1.4),
          ),

          const SizedBox(height: 12),

          const Text(
            'This is a preliminary browser-based screening. Display '
            'calibration improves consistency across devices, but browser '
            'rendering, viewing distance, lighting and user positioning '
            'can still affect the result.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.35),
          ),

          const SizedBox(height: 18),

          FilledButton(onPressed: onPressed, child: Text(buttonText)),
        ],
      ),
    );
  }
}

// ================================================================
// ACTIVE TEST
// ================================================================

class _TestRun extends StatelessWidget {
  const _TestRun({
    required this.mode,
    required this.eye,
    required this.index,
    required this.line,
    required this.steps,
    required this.fontFor,
    required this.snellen,
    required this.distanceText,
    required this.onPass,
    required this.onFail,
  });

  final vm.TestMode mode;
  final _Eye eye;
  final int index;
  final String line;
  final List<double> steps;

  final double Function(double) fontFor;

  final String Function(double) snellen;

  final String distanceText;

  final VoidCallback onPass;
  final VoidCallback onFail;

  String get eyeName {
    switch (eye) {
      case _Eye.right:
        return 'RIGHT eye (OD)';

      case _Eye.left:
        return 'LEFT eye (OS)';

      case _Eye.both:
        return 'BOTH eyes (OU)';
    }
  }

  String get eyeInstruction {
    switch (eye) {
      case _Eye.right:
        return 'Cover your LEFT eye without pressing on it.';

      case _Eye.left:
        return 'Cover your RIGHT eye without pressing on it.';

      case _Eye.both:
        return 'Keep BOTH eyes open.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = steps[index];

    final isMobile = MediaQuery.of(context).size.width < 600;

    final size = fontFor(current);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Testing $eyeName',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isMobile ? 15 : 16,
          ),
        ),

        Text(
          eyeInstruction,
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          mode == vm.TestMode.distance
              ? 'Testing distance: $distanceText'
              : 'Viewing distance: $distanceText',
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: isMobile ? 6 : 10),

        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Center(
              child: Text(
                line,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size,
                  height: 1.0,
                  letterSpacing: size * 0.10,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Line ${index + 1} of ${steps.length}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),

        const SizedBox(height: 4),

        Text(
          'Screening level: ${snellen(current)}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),

        SizedBox(height: isMobile ? 8 : 12),

        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onPass,
                icon: const Icon(Icons.check),
                label: const Text('I Can Read'),
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: OutlinedButton.icon(
                onPressed: onFail,
                icon: const Icon(Icons.flag),
                label: const Text('I Can’t Read'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ================================================================
// FINISH SCREEN
// ================================================================

class _FinishPanel extends StatelessWidget {
  const _FinishPanel({
    required this.mode,
    required this.right,
    required this.left,
    required this.both,
    required this.rightBelowRange,
    required this.leftBelowRange,
    required this.bothBelowRange,
    required this.screeningLevel,
    required this.resultLabel,
    required this.meaning,
    required this.bothEyesMeaning,
    required this.eyeComparison,
    required this.testDistance,
    required this.deviceLabel,
    required this.onSave,
    required this.onRetest,
    required this.onStartOtherMode,
  });

  final vm.TestMode mode;

  final double right;
  final double left;
  final double both;

  final bool rightBelowRange;
  final bool leftBelowRange;
  final bool bothBelowRange;

  final String Function(double, {required bool belowRange}) screeningLevel;

  final String Function(double, {required bool belowRange}) resultLabel;

  final String Function(
    double, {
    required String eyeLabel,
    required bool belowRange,
  })
  meaning;

  final String Function() bothEyesMeaning;
  final String Function() eyeComparison;

  final String testDistance;
  final String deviceLabel;

  final VoidCallback onSave;
  final VoidCallback onRetest;
  final VoidCallback onStartOtherMode;

  @override
  Widget build(BuildContext context) {
    Widget resultCard(
      String title,
      double value,
      bool belowRange,
      String description,
    ) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                resultLabel(value, belowRange: belowRange),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 8),

              Text(description, style: const TextStyle(height: 1.4)),

              const SizedBox(height: 8),

              Text(
                'Screening level: ${screeningLevel(value, belowRange: belowRange)}',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      children: [
        const Text(
          'Vision screening complete',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),

        const SizedBox(height: 8),

        Text(
          'Test distance: $testDistance',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 3),

        Text(
          '$deviceLabel • Display calibrated',
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),

        const SizedBox(height: 12),

        resultCard(
          'Right Eye (OD)',
          right,
          rightBelowRange,
          meaning(
            right,
            eyeLabel: 'Your RIGHT eye',
            belowRange: rightBelowRange,
          ),
        ),

        resultCard(
          'Left Eye (OS)',
          left,
          leftBelowRange,
          meaning(left, eyeLabel: 'Your LEFT eye', belowRange: leftBelowRange),
        ),

        resultCard('Both Eyes (OU)', both, bothBelowRange, bothEyesMeaning()),

        const SizedBox(height: 10),

        Text(
          eyeComparison(),
          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onRetest,
                child: const Text('Retest'),
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: FilledButton(
                onPressed: onSave,
                child: const Text('Save Results'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        FilledButton.tonal(
          onPressed: onStartOtherMode,
          child: Text(
            mode == vm.TestMode.distance
                ? 'Start Near Vision Test'
                : 'Start Distance Vision Test',
          ),
        ),
      ],
    );
  }
}
