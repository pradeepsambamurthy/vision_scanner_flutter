import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/vision_models.dart' as vm;
import '../services/report_service.dart';

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
    0.3,
    0.2,
    0.1,
    0.0,
    -0.1,
    -0.2,
    -0.3,
    -0.4,
    -0.5,
    -0.6,
    -0.7,
    -0.8,
    -0.9,
    -1.0,
  ];

  static const String _alphabet = 'CDHKNORSVZ';

  final _rng = math.Random();
  vm.TestMode _mode = vm.TestMode.distance;

  _Stage _stage = _Stage.idleRight;
  int _index = 0;
  int _lastPassed = -1;
  String _line = '';

  double? _resultRight;
  double? _resultLeft;
  double? _resultBoth;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _generateLine();
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
      _resetForEye();
    });
  }

  String _snellen(double logMAR) {
    final denom = (20 * math.pow(10, logMAR)).round();
    return '20/$denom';
  }

  String _simpleMeaning(double logMAR) {
   final denom = (20 * math.pow(10, logMAR)).round();

   final testType =
       _mode == vm.TestMode.distance ? 'distance vision' : 'near vision';

   if (denom <= 20) {
     return 'This screening result suggests relatively good $testType under the test conditions.';
   } else if (denom <= 40) {
     return 'This screening result may indicate some difficulty with $testType.';
   } else {
     return 'This screening result may indicate greater difficulty with $testType. Consider discussing the result with an eye-care professional.';
   }
  }

  String _bothEyesMeaning() {
    if (_resultBoth == null) {
      return 'Both-eyes result is not available.';
    }

    final both = _resultBoth!;
    final right = _resultRight;
    final left = _resultLeft;

    if (right == null || left == null) {
      return 'With both eyes open, this is your combined vision screening result.';
    }

    final bestSingleEye = math.min(right, left);

    if (both <= bestSingleEye) {
      return 'With both eyes open, your vision appears as good as or better than either eye alone.';
    }

    return 'With both eyes open, your vision is slightly lower than the better single-eye result. You may want to repeat the test in good lighting.';
  }

  double _fontFor(double logMAR, BoxConstraints c) {
    final base = (_mode == vm.TestMode.distance ? 0.095 : 0.080) * c.maxWidth;
    return base * math.pow(10, logMAR);
  }

  Future<void> _goReport() async {
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/report',
      arguments: {'completed': _mode},
    );
  }

  Future<void> _autoSaveAndGoToReport() async {
    if (_resultRight == null || _resultLeft == null || _resultBoth == null) {
      return;
    }

    /*
      NOTE:
      Your current ReportService appears to save only Right and Left eyes.
      This saves Right and Left as before.
      To show "Both Eyes" inside the Report tab, report_service.dart and
      report_screen.dart also need to be updated.
    */
    ReportService.instance.updateAcuityModeAware(
      mode: _mode,
      right: vm.AcuityResult(_resultRight!),
      left: vm.AcuityResult(_resultLeft!),
      both: vm.AcuityResult(_resultBoth!),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == vm.TestMode.near
                ? 'Near results saved. Opening report...'
                : 'Distance results saved. Opening report...',
          ),
          duration: const Duration(milliseconds: 900),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 150));
    await _goReport();
  }

  void _startRight() => setState(() => _stage = _Stage.testingRight);
  void _startLeft() => setState(() => _stage = _Stage.testingLeft);
  void _startBoth() => setState(() => _stage = _Stage.testingBoth);

  void _markPass() {
    setState(() {
      _lastPassed = _index;

      if (_index < _steps.length - 1) {
        _index++;
        _generateLine();
      } else {
        _finishCurrentEye();
      }
    });
  }

  void _markFail() {
    setState(() {
      _finishCurrentEye();
    });
  }

  void _finishCurrentEye() {
    final logmar = (_lastPassed >= 0) ? _steps[_lastPassed] : _steps.first;

    if (_stage == _Stage.testingRight) {
      _resultRight = logmar;
      _stage = _Stage.idleLeft;
      _resetForEye();
    } else if (_stage == _Stage.testingLeft) {
      _resultLeft = logmar;
      _stage = _Stage.idleBoth;
      _resetForEye();
    } else if (_stage == _Stage.testingBoth) {
      _resultBoth = logmar;
      _stage = _Stage.finished;
      _autoSaveAndGoToReport();
    }
  }

  Future<void> _saveToReport() async {
    if (_resultRight == null || _resultLeft == null || _resultBoth == null) {
      return;
    }

    ReportService.instance.updateAcuityModeAware(
      mode: _mode,
      right: vm.AcuityResult(_resultRight!),
      left: vm.AcuityResult(_resultLeft!),
      both: vm.AcuityResult(_resultBoth!),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _mode == vm.TestMode.near
              ? 'Near results saved.'
              : 'Distance results saved.',
        ),
      ),
    );
  }

  void _switchModeAndReset(vm.TestMode m) {
   setState(() {
     _mode = m;
     _stage = _Stage.idleRight;
     _resultRight = null;
     _resultLeft = null;
     _resultBoth = null;
     _resetForEye();
   });
 }

  @override
  Widget build(BuildContext context) {
    final title = _mode == vm.TestMode.distance
        ? 'Free Online Distance Visual Acuity Test'
        : 'Free Online Near Vision Test';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
         padding: const EdgeInsets.symmetric(vertical: 6),
         child: Column(
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
                  ? 'Check your distance visual acuity using a preliminary online eye-chart screening. Follow the distance and eye-covering instructions carefully.'
                  : 'Check your near and reading vision using a preliminary online vision screening. Follow the viewing-distance instructions carefully.',
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Mode:',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<vm.TestMode>(
                          initialValue: _mode,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
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
                          onChanged: (m) {
                            if (m == null || m == _mode) return;

                            if (_stage == _Stage.testingRight ||
                                _stage == _Stage.testingLeft ||
                                _stage == _Stage.testingBoth) {
                              showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Switch test type?'),
                                  content: const Text(
                                    'You are in the middle of a test. Switching will reset your progress.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _switchModeAndReset(m);
                                      },
                                      child: const Text('Switch & Reset'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              _switchModeAndReset(m);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
          title: 'Step 1 of 3: Right Eye',
          coverEyeText: 'Cover your LEFT eye. Use only your RIGHT eye.',
          buttonText: 'Start Right Eye',
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
          onPass: _markPass,
          onFail: _markFail,
        );

      case _Stage.idleLeft:
        return _CalibrationPanel(
          mode: _mode,
          title: 'Step 2 of 3: Left Eye',
          coverEyeText: 'Cover your RIGHT eye. Use only your LEFT eye.',
          buttonText: 'Start Left Eye',
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
          onPass: _markPass,
          onFail: _markFail,
        );

      case _Stage.idleBoth:
        return _CalibrationPanel(
          mode: _mode,
          title: 'Step 3 of 3: Both Eyes',
          coverEyeText: 'Keep BOTH eyes open. Do not cover either eye.',
          buttonText: 'Start Both Eyes',
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
          onPass: _markPass,
          onFail: _markFail,
        );

      case _Stage.finished:
        return _FinishPanel(
          mode: _mode,
          right: _resultRight!,
          left: _resultLeft!,
          both: _resultBoth!,
          snellen: _snellen,
          simpleMeaning: _simpleMeaning,
          bothEyesMeaning: _bothEyesMeaning,
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

// ---------- sub-widgets ----------

class _CalibrationPanel extends StatelessWidget {
  const _CalibrationPanel({
    required this.mode,
    required this.title,
    required this.coverEyeText,
    required this.buttonText,
    required this.onPressed,
  });

  final vm.TestMode mode;
  final String title;
  final String coverEyeText;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final line1 = mode == vm.TestMode.distance
        ? 'Stand about 3 meters / 10 feet from the screen.'
        : 'Hold the screen about 40 cm / 16 inches away.';

    final line2 = mode == vm.TestMode.distance
        ? 'Wear your usual distance glasses or contacts if you normally use them.'
        : 'Wear your usual reading glasses or contacts if you normally use them.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Text(line1),
        const SizedBox(height: 6),
        Text(coverEyeText, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(line2, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        FilledButton(onPressed: onPressed, child: Text(buttonText)),
      ],
    );
  }
}

class _TestRun extends StatelessWidget {
  const _TestRun({
    required this.mode,
    required this.eye,
    required this.index,
    required this.line,
    required this.steps,
    required this.fontFor,
    required this.snellen,
    required this.onPass,
    required this.onFail,
  });

  final vm.TestMode mode;
  final _Eye eye;
  final int index;
  final String line;
  final List<double> steps;
  final double Function(double, BoxConstraints) fontFor;
  final String Function(double) snellen;
  final VoidCallback onPass;
  final VoidCallback onFail;

  String get _eyeLabel {
    switch (eye) {
      case _Eye.right:
        return 'RIGHT eye';
      case _Eye.left:
        return 'LEFT eye';
      case _Eye.both:
        return 'BOTH eyes';
    }
  }

  String get _instruction {
    switch (eye) {
      case _Eye.right:
        return 'Cover your left eye. Read the letters using only your right eye.';
      case _Eye.left:
        return 'Cover your right eye. Read the letters using only your left eye.';
      case _Eye.both:
        return 'Keep both eyes open. Read the letters using both eyes together.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = steps[index];

    return LayoutBuilder(
      builder: (context, c) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${mode == vm.TestMode.distance ? 'Distance' : 'Near'} test • Testing $_eyeLabel',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(_instruction, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),

          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final size = fontFor(cur, c);
                return Center(
                  child: Text(
                    line,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      letterSpacing: 8,
                      fontWeight: FontWeight.w800,
                      fontSize: size,
                      height: 1.0,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Line ${index + 1} of ${steps.length} • Screening estimate: ${snellen(cur)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),

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
      ),
    );
  }
}

class _FinishPanel extends StatelessWidget {
  const _FinishPanel({
    required this.mode,
    required this.right,
    required this.left,
    required this.both,
    required this.snellen,
    required this.simpleMeaning,
    required this.bothEyesMeaning,
    required this.onSave,
    required this.onRetest,
    required this.onStartOtherMode,
  });

  final vm.TestMode mode;
  final double right;
  final double left;
  final double both;
  final String Function(double) snellen;
  final String Function(double) simpleMeaning;
  final String Function() bothEyesMeaning;
  final VoidCallback onSave;
  final VoidCallback onRetest;
  final VoidCallback onStartOtherMode;

  @override
  Widget build(BuildContext context) {
    final isNear = mode == vm.TestMode.near;

    Widget resultCard(String title, String result, String meaning) {
      return Card(
        elevation: 0,
        color: const Color(0xFFF6F7FB),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Screening estimate: $result',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(meaning),
            ],
          ),
        ),
      );
    }

    return ListView(
      children: [
        Text(
          isNear
              ? 'Near vision results ready'
              : 'Distance vision results ready',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 12),

        resultCard('Right Eye', snellen(right), simpleMeaning(right)),
        resultCard('Left Eye', snellen(left), simpleMeaning(left)),
        resultCard('Both Eyes', snellen(both), bothEyesMeaning()),

        const SizedBox(height: 12),
        const Text(
          'This is a preliminary screening result only. It is not a diagnosis or prescription and does not replace a comprehensive eye examination by a qualified eye-care professional.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRetest,
                icon: const Icon(Icons.refresh),
                label: const Text('Retest'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save),
                label: const Text('Save Results'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: onStartOtherMode,
          icon: const Icon(Icons.swap_horiz),
          label: Text(isNear ? 'Start Distance Test' : 'Start Near Test'),
        ),
      ],
    );
  }
}
