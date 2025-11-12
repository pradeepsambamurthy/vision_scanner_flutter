// lib/screens/acuity_test_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/vision_models.dart' as vm;
import '../services/report_service.dart';

enum _Eye { right, left }

enum _Stage { idleRight, testingRight, idleLeft, testingLeft, finished }

class AcuityTestScreen extends StatefulWidget {
  const AcuityTestScreen({super.key, this.mode = vm.TestMode.distance});
  final vm.TestMode mode;

  @override
  State<AcuityTestScreen> createState() => _AcuityTestScreenState();
}

class _AcuityTestScreenState extends State<AcuityTestScreen> {
  // Bigger -> smaller: extends to 1.0 (big) down to -0.3 (very small ~20/10)
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
  int _lastPassed = -1; // index of last passed line
  String _line = '';

  double? _resultRight;
  double? _resultLeft;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _generateLine();
  }

  // ------------ helpers ------------

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
      _resetForEye();
    });
  }

  String _snellen(double logMAR) {
    final denom = (20 * math.pow(10, logMAR)).round();
    return '20/$denom';
  }

  /// Rough font scaling so each step is visibly smaller/larger.
  double _fontFor(double logMAR, BoxConstraints c) {
    // Base scale derived from card width; tuned separately for distance/near.
    final base = (_mode == vm.TestMode.distance ? 0.095 : 0.080) * c.maxWidth;
    // logMAR increases 10^logMAR times larger
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
    if (_resultRight == null || _resultLeft == null) return;
    ReportService.instance.updateAcuityModeAware(
      mode: _mode,
      right: vm.AcuityResult(_resultRight!),
      left: vm.AcuityResult(_resultLeft!),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == vm.TestMode.near
                ? 'Near results saved. Opening report...'
                : 'Distance results saved. Opening report...',
          ),
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
    await Future.delayed(const Duration(milliseconds: 100));
    await _goReport();
  }

  // ------------ stage transitions ------------

  void _startRight() => setState(() => _stage = _Stage.testingRight);
  void _startLeft() => setState(() => _stage = _Stage.testingLeft);

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
    // Fails this line -> record last passed line and move to next eye/finish
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
      _stage = _Stage.finished;
      _autoSaveAndGoToReport(); // auto-generate report and navigate
    }
  }

  Future<void> _saveToReport() async {
    if (_resultRight == null || _resultLeft == null) return;
    ReportService.instance.updateAcuityModeAware(
      mode: _mode,
      right: vm.AcuityResult(_resultRight!),
      left: vm.AcuityResult(_resultLeft!),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _mode == vm.TestMode.near
              ? 'Saved near results.'
              : 'Saved distance results.',
        ),
      ),
    );
  }

  void _switchModeAndReset(vm.TestMode m) {
    setState(() {
      _mode = m;
      _resetAll();
    });
  }

  // ------------ UI ------------

  @override
  Widget build(BuildContext context) {
    final title = _mode == vm.TestMode.distance
        ? 'Acuity Test (Distance) — v2'
        : 'Acuity Test (Near) — v2';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title line
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        // Main card
        Expanded(
          child: Card(
            color: Colors.white,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mode selector at top of card (always visible)
                  Row(
                    children: [
                      const Text(
                        'Mode:',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<vm.TestMode>(
                          value: _mode,
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
                              child: Text('Distance — short-sight (myopia)'),
                            ),
                            DropdownMenuItem(
                              value: vm.TestMode.near,
                              child: Text('Near — long-sight / reading'),
                            ),
                          ],
                          onChanged: (m) {
                            if (m == null || m == _mode) return;
                            if (_stage == _Stage.testingLeft ||
                                _stage == _Stage.testingRight) {
                              showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Switch test type?'),
                                  content: const Text(
                                    'You are in the middle of a test. Switching will reset progress.',
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

                  // Stage content
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
          coverEyeText: 'Cover LEFT eye.',
          buttonText: 'Start Right Eye',
          onPressed: _startRight,
        );
      case _Stage.testingRight:
        return _TestRun(
          mode: _mode,
          eye: _Eye.right,
          index: _index,
          lastPassed: _lastPassed,
          line: _line,
          steps: _steps,
          fontFor: _fontFor,
          snellen: _snellen,
          onPass: _markPass,
          onFail: _markFail, // “Can’t read” → switch to left eye
        );
      case _Stage.idleLeft:
        return _CalibrationPanel(
          mode: _mode,
          coverEyeText: 'Cover RIGHT eye.',
          buttonText: 'Start Left Eye',
          onPressed: _startLeft,
        );
      case _Stage.testingLeft:
        return _TestRun(
          mode: _mode,
          eye: _Eye.left,
          index: _index,
          lastPassed: _lastPassed,
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
          snellen: _snellen,
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
    required this.coverEyeText,
    required this.buttonText,
    required this.onPressed,
  });

  final vm.TestMode mode;
  final String coverEyeText;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final line1 = mode == vm.TestMode.distance
        ? 'Stand ~3 m / 10 ft from the screen.'
        : 'Hold the screen at ~40 cm / 16″.';
    final line2 = mode == vm.TestMode.distance
        ? 'Wear your usual distance glasses/contacts if you normally use them.'
        : 'Wear your usual reading glasses if you normally use them.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calibration',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text('$line1 $coverEyeText'),
        Text(line2, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 12),
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
    required this.lastPassed,
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
  final int lastPassed;
  final String line;
  final List<double> steps;
  final double Function(double, BoxConstraints) fontFor;
  final String Function(double) snellen;
  final VoidCallback onPass;
  final VoidCallback onFail;

  @override
  Widget build(BuildContext context) {
    final cur = steps[index];
    final bool isRightEye = eye == _Eye.right;

    return LayoutBuilder(
      builder: (context, c) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${mode == vm.TestMode.distance ? 'Distance' : 'Near'} • '
            'Testing ${isRightEye ? 'RIGHT' : 'LEFT'} eye',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            isRightEye
                ? 'Read the 5 letters. If you can read the very smallest line, the test will switch to the other eye automatically.'
                : 'Read the 5 letters. If you can read the very smallest line, the test will navigate to the Report page automatically.',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),

          // Letters
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final cur = steps[index];
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
              'Line ${index + 1} of ${steps.length}  •  ${snellen(cur)} '
              '(logMAR ${cur.toStringAsFixed(1)})',
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
                  label: const Text('I Can Read '),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFail,
                  icon: const Icon(Icons.flag),
                  label: const Text('I Can’t read'),
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
    required this.snellen,
    required this.onSave,
    required this.onRetest,
    required this.onStartOtherMode,
  });

  final vm.TestMode mode;
  final double right;
  final double left;
  final String Function(double) snellen;
  final VoidCallback onSave;
  final VoidCallback onRetest;
  final VoidCallback onStartOtherMode;

  @override
  Widget build(BuildContext context) {
    final isNear = mode == vm.TestMode.near;

    Widget kv(String k, String v) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(v),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isNear ? 'Near results ready' : 'Distance results ready',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: kv(
                'Right',
                '${snellen(right)}  (logMAR ${right.toStringAsFixed(1)})',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: kv(
                'Left',
                '${snellen(left)}  (logMAR ${left.toStringAsFixed(1)})',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRetest,
                icon: const Icon(Icons.refresh),
                label: const Text('Retest this eye pair'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save),
                label: const Text('Save results to Report'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: onStartOtherMode,
          icon: const Icon(Icons.swap_horiz),
          label: Text(
            isNear
                ? 'Start Distance Test (short-sight)'
                : 'Start Near Test (long-sight)',
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tip: Doing both Distance and Near gives a better short-/long-sight interpretation.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}
