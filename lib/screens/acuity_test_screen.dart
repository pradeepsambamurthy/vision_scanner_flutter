// lib/screens/acuity_test_screen.dart
import 'package:flutter/material.dart';

// Namespaced models (enums + result types)
import '../models/vision_models.dart' as vm;

// Only the service class to avoid type clashes
import '../services/acuity_service.dart' show AcuityService;
import '../services/calibration_service.dart';
import '../services/compliance_service.dart';
import '../services/report_service.dart';

class AcuityTestScreen extends StatefulWidget {
  const AcuityTestScreen({super.key, this.onCompleted});

  /// Optional: parent (e.g., AppShell) can listen for completion to switch tabs
  /// and/or store results immediately. If not provided, we navigate to /report.
  final void Function({
    required vm.TestMode mode,
    required vm.AcuityResult right,
    required vm.AcuityResult left,
  })?
  onCompleted;

  @override
  State<AcuityTestScreen> createState() => _AcuityTestScreenState();
}

class _AcuityTestScreenState extends State<AcuityTestScreen> {
  final _acuity = AcuityService.instance;
  final _calib = CalibrationService.instance;
  final _comp = ComplianceService.instance; // reserved for future use

  late vm.TestMode _mode; // distance (default) or near
  vm.CalibrationResult? _cal;

  vm.EyeSide _eye = vm.EyeSide.right;
  vm.AcuityResult? _r, _l;

  bool _started = false;
  bool _busy = false;

  String get _introStatus => _mode == vm.TestMode.near
      ? 'Hold device ~40 cm / 16 in away. Cover LEFT eye.'
      : 'Stand ~3 m / 10 ft from screen. Cover LEFT eye.';

  String _status = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    _mode = (args is Map && args['mode'] is vm.TestMode)
        ? args['mode'] as vm.TestMode
        : vm.TestMode.distance;
    _status = _introStatus;
  }

  Future<void> _begin() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _cal = await _calib.quickDefaults(mode: _mode);
      if (_cal == null) {
        _snack('Calibration failed. Please try again.');
        return;
      }
      _eye = vm.EyeSide.right; // start with RIGHT eye
      await _acuity.start(eye: _eye, calibration: _cal!);
      setState(() {
        _started = true;
        _status = _introStatus;
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  /// Convert whatever the service returns into our vm.AcuityResult
  vm.AcuityResult _toVmResult(dynamic raw) {
    if (raw is vm.AcuityResult) return raw;
    try {
      final value = raw?.logMAR ?? raw?.logmar ?? raw?.logmarValue;
      if (value is num) return vm.AcuityResult(value.toDouble());
    } catch (_) {}
    return const vm.AcuityResult(0.3); // conservative fallback (~20/40)
  }

  /// User tapped "I read it" (continues staircase; finishes only at stop rule)
  Future<void> _onCouldRead() async {
    if (_busy) return;
    final finished = _acuity.submitAnswer(true);
    setState(() {});
    if (!finished) return;

    setState(() => _busy = true);
    try {
      final vm.AcuityResult res = _toVmResult(_acuity.finish());
      await _handleEyeDone(res);
    } finally {
      setState(() => _busy = false);
    }
  }

  /// User tapped "Couldn't read" (immediately finalize current eye)
  Future<void> _onCouldNotRead() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final vm.AcuityResult res = _toVmResult(_acuity.finish());
      await _handleEyeDone(res);
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _handleEyeDone(vm.AcuityResult res) async {
    if (_eye == vm.EyeSide.right) {
      _r = res;
      _eye = vm.EyeSide.left;
      _status = _mode == vm.TestMode.near
          ? 'Now cover RIGHT eye. Keep ~40 cm / 16 in distance.'
          : 'Now cover RIGHT eye. Keep 3 m / 10 ft distance.';
      await _acuity.start(eye: _eye, calibration: _cal!);
      setState(() {});
      return;
    }

    // Finished LEFT eye
    _l = res;

    // Persist results by mode so the report can compare distance vs near
    ReportService.instance.updateAcuityModeAware(
      mode: _mode,
      right: _r ?? const vm.AcuityResult(0.3),
      left: _l ?? const vm.AcuityResult(0.3),
    );

    // Notify parent if it wants to handle navigation/tab switch
    final right = _r ?? const vm.AcuityResult(0.3);
    final left = _l ?? const vm.AcuityResult(0.3);
    if (widget.onCompleted != null) {
      widget.onCompleted!(mode: _mode, right: right, left: left);
      return;
    }

    // Default behavior: open the Report tab via '/report'
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/report',
      arguments: {'completed': _mode},
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _mode == vm.TestMode.near
        ? 'Acuity Test (Near)'
        : 'Acuity Test (Distance)';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: !_started
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calibration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_introStatus),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy ? null : _begin,
                      child: const Text('Start Right Eye'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_status),
                    const SizedBox(height: 8),
                    Text(
                      'Testing ${_eye == vm.EyeSide.right ? 'RIGHT' : 'LEFT'} eye',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),

                    // Responsive letter area; if AcuityService already sizes, this still works.
                    Expanded(
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            final w = c.maxWidth, h = c.maxHeight;
                            final box = ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: w * 0.9,
                                maxHeight: h * 0.9,
                              ),
                              child: _acuity.currentWidget(context),
                            );
                            return box;
                          },
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _busy ? null : _onCouldRead,
                            icon: const Icon(Icons.check),
                            label: const Text('I read it'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _onCouldNotRead,
                            icon: const Icon(Icons.close),
                            label: const Text("Couldn't read"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
