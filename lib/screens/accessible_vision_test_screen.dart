// lib/screens/accessible_vision_test_screen.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/vision_models.dart' as vm;
import '../services/display_calibration_service.dart';
import '../services/report_service.dart';
import '../services/voice_service.dart';
import '../utils/vision_test_profile.dart';
import '../widgets/display_calibration_dialog.dart';

enum _AccessibleStage { instructions, right, left, both, finished }

class AccessibleVisionTestScreen extends StatefulWidget {
  const AccessibleVisionTestScreen({super.key});

  @override
  State<AccessibleVisionTestScreen> createState() =>
      _AccessibleVisionTestScreenState();
}

class _AccessibleVisionTestScreenState
    extends State<AccessibleVisionTestScreen> {
  // ================================================================
  // LARGE-LETTER VISUAL ACUITY LEVELS
  // ================================================================

  static const List<double> _steps = [
    1.3, // 20/400
    1.2, // 20/320
    1.1, // 20/250
    1.0, // 20/200
    0.9, // 20/160
    0.8, // 20/125
    0.7, // 20/100
    0.6, // 20/80
    0.5, // 20/63
    0.4, // 20/50
  ];

  static const String _alphabet = 'CDHKNORSVZ';

  final math.Random _random = math.Random();

  // ================================================================
  // VOICE
  // ================================================================

  final VoiceService _voice = VoiceService.instance;

  bool _voiceEnabled = true;
  bool _voiceReady = false;
  bool _isListening = false;

  String _heardWords = '';
  String _voiceMessage = '';

  // ================================================================
  // TEST STATE
  // ================================================================

  _AccessibleStage _stage = _AccessibleStage.instructions;

  int _index = 0;
  int _lastPassed = -1;

  String _line = '';

  double? _rightResult;
  double? _leftResult;
  double? _bothResult;

  bool _rightBelowRange = false;
  bool _leftBelowRange = false;
  bool _bothBelowRange = false;

  vm.VisionCorrection _correction = vm.VisionCorrection.none;

  // Stores the distance/device profile selected after screen calibration.
  VisionTestProfile? _testProfile;

  // ================================================================
  // INIT / DISPOSE
  // ================================================================

  @override
  void initState() {
    super.initState();

    _generateLine();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    await _voice.initialize();

    if (!mounted) {
      return;
    }

    setState(() {
      _voiceReady = _voice.speechAvailable;
    });
  }

  @override
  void dispose() {
    _voice.stopSpeaking();
    _voice.cancelListening();

    super.dispose();
  }

  // ================================================================
  // BASIC HELPERS
  // ================================================================

  void _generateLine() {
    _line = List.generate(
      5,
      (_) => _alphabet[_random.nextInt(_alphabet.length)],
    ).join(' ');
  }

  String _snellen(double logMAR) {
    if ((logMAR - 1.3).abs() < 0.01) return '20/400';
    if ((logMAR - 1.2).abs() < 0.01) return '20/320';
    if ((logMAR - 1.1).abs() < 0.01) return '20/250';
    if ((logMAR - 1.0).abs() < 0.01) return '20/200';
    if ((logMAR - 0.9).abs() < 0.01) return '20/160';
    if ((logMAR - 0.8).abs() < 0.01) return '20/125';
    if ((logMAR - 0.7).abs() < 0.01) return '20/100';
    if ((logMAR - 0.6).abs() < 0.01) return '20/80';
    if ((logMAR - 0.5).abs() < 0.01) return '20/63';

    return '20/50';
  }

  int _stepIndex(double value) {
    for (int i = 0; i < _steps.length; i++) {
      if ((_steps[i] - value).abs() < 0.01) {
        return i;
      }
    }

    return -1;
  }

  String? _nextSmallerLevel(double value) {
    final index = _stepIndex(value);

    if (index < 0 || index >= _steps.length - 1) {
      return null;
    }

    return _snellen(_steps[index + 1]);
  }

  bool _reachedSmallest(double? value) {
    if (value == null) {
      return false;
    }

    return (value - _steps.last).abs() < 0.01;
  }

  void _resetLevel() {
    _index = 0;
    _lastPassed = -1;

    _heardWords = '';
    _voiceMessage = '';
    _isListening = false;

    _generateLine();
  }

  String get _eyeTitle {
    switch (_stage) {
      case _AccessibleStage.right:
        return 'Right Eye (OD)';

      case _AccessibleStage.left:
        return 'Left Eye (OS)';

      case _AccessibleStage.both:
        return 'Both Eyes (OU)';

      default:
        return '';
    }
  }

  String get _eyeInstruction {
    switch (_stage) {
      case _AccessibleStage.right:
        return 'Cover your LEFT eye and use only your RIGHT eye.';

      case _AccessibleStage.left:
        return 'Cover your RIGHT eye and use only your LEFT eye.';

      case _AccessibleStage.both:
        return 'Keep BOTH eyes open.';

      default:
        return '';
    }
  }

  // ================================================================
  // SPOKEN INSTRUCTIONS
  // ================================================================

  Future<void> _speakCurrentInstructions() async {
    if (!_voiceEnabled) {
      return;
    }

    final profile = _testProfile;

    if (profile == null) {
      return;
    }

    final distance = profile.spokenDistance;

    String instruction;

    switch (_stage) {
      case _AccessibleStage.right:
        instruction =
            'Cover your left eye and use only your right eye. '
            'Stay $distance from the screen. '
            'Read the five letters from left to right.';
        break;

      case _AccessibleStage.left:
        instruction =
            'Cover your right eye and use only your left eye. '
            'Stay $distance from the screen. '
            'Read the five letters from left to right.';
        break;

      case _AccessibleStage.both:
        instruction =
            'Keep both eyes open. '
            'Stay $distance from the screen. '
            'Read the five letters from left to right.';
        break;

      default:
        return;
    }

    await _voice.speak(instruction);
  }

  Future<void> _repeatInstructions() async {
    await _speakCurrentInstructions();
  }

  // ================================================================
  // SPEECH RECOGNITION
  // ================================================================

  Future<void> _startListening() async {
    if (!_voiceReady) {
      setState(() {
        _voiceMessage =
            'Voice recognition is not available in this browser. '
            'You can still use the buttons below.';
      });

      return;
    }

    await _voice.stopSpeaking();

    setState(() {
      _heardWords = '';
      _voiceMessage = 'Listening... Say the five letters from left to right.';
      _isListening = true;
    });

    await _voice.listen(
      onWords: (words) {
        if (!mounted) {
          return;
        }

        setState(() {
          _heardWords = words.toUpperCase();
        });
      },
    );
  }

  Future<void> _stopListening() async {
    await _voice.stopListening();

    if (!mounted) {
      return;
    }

    setState(() {
      _isListening = false;
    });

    _scoreVoiceAnswer();
  }

  void _scoreVoiceAnswer() {
    if (_heardWords.trim().isEmpty) {
      setState(() {
        _voiceMessage =
            'No letters were recognized. Please try speaking again.';
      });

      return;
    }

    final expected = _line.replaceAll(' ', '').toUpperCase().split('');

    final recognized = _extractLetters(_heardWords);

    if (recognized.isEmpty) {
      setState(() {
        _voiceMessage =
            'I heard "$_heardWords", but could not identify the test letters. '
            'Please try again or use the buttons below.';
      });

      return;
    }

    int correct = 0;

    final count = math.min(expected.length, recognized.length);

    for (int i = 0; i < count; i++) {
      if (expected[i] == recognized[i]) {
        correct++;
      }
    }

    final recognizedText = recognized.join(' ');

    setState(() {
      _voiceMessage = 'Heard: $recognizedText  •  $correct of 5 correct';
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }

      if (correct >= 3) {
        _markReadable();
      } else {
        _markNotReadable();
      }
    });
  }

  // ================================================================
  // U.S. ENGLISH LETTER-NAME PARSER
  // ================================================================

  List<String> _extractLetters(String speech) {
    final text = speech
        .toUpperCase()
        .replaceAll(',', ' ')
        .replaceAll('.', ' ')
        .replaceAll('-', ' ');

    final words = text
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();

    const letterNames = <String, String>{
      'C': 'C',
      'SEE': 'C',
      'SEA': 'C',
      'D': 'D',
      'DEE': 'D',
      'H': 'H',
      'AITCH': 'H',
      'EIGHTCH': 'H',
      'K': 'K',
      'KAY': 'K',
      'KAYE': 'K',
      'N': 'N',
      'EN': 'N',
      'O': 'O',
      'OH': 'O',
      'R': 'R',
      'ARE': 'R',
      'S': 'S',
      'ESS': 'S',
      'V': 'V',
      'VEE': 'V',
      'Z': 'Z',
      'ZEE': 'Z',
      'ZED': 'Z',
    };

    final result = <String>[];

    for (final word in words) {
      final clean = word.replaceAll(RegExp('[^A-Z]'), '');

      if (clean.isEmpty) {
        continue;
      }

      final mapped = letterNames[clean];

      if (mapped != null) {
        result.add(mapped);
      } else if (clean.length == 1 && _alphabet.contains(clean)) {
        result.add(clean);
      } else {
        bool allAllowed = true;

        for (final rune in clean.runes) {
          final letter = String.fromCharCode(rune);

          if (!_alphabet.contains(letter)) {
            allAllowed = false;
            break;
          }
        }

        if (allAllowed) {
          for (final rune in clean.runes) {
            result.add(String.fromCharCode(rune));

            if (result.length == 5) {
              break;
            }
          }
        }
      }

      if (result.length >= 5) {
        break;
      }
    }

    return result.take(5).toList();
  }

  // ================================================================
  // TEST FLOW
  // ================================================================

  Future<void> _startRight() async {
    if (!DisplayCalibrationService.instance.isCalibrated) {
      final calibrated = await showDisplayCalibrationDialog(context);

      if (!calibrated || !mounted) {
        return;
      }
    }

    final profile = VisionTestProfile.distance(
      context: context,

      // 20/400 is the largest level
      // in the Accessible Vision Test.
      largestLogMar: _steps.first,
    );

    setState(() {
      _testProfile = profile;

      _resetLevel();

      _stage = _AccessibleStage.right;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _speakCurrentInstructions();
      }
    });
  }

  void _markReadable() {
    if (_index < _steps.length - 1) {
      setState(() {
        _lastPassed = _index;
        _index++;

        _heardWords = '';
        _voiceMessage = '';

        _generateLine();
      });

      return;
    }

    _lastPassed = _index;

    _finishCurrentEye(belowRange: false);
  }

  void _markNotReadable() {
    _finishCurrentEye(belowRange: _lastPassed < 0);
  }

  void _finishCurrentEye({required bool belowRange}) {
    final result = _lastPassed >= 0 ? _steps[_lastPassed] : _steps.first;

    bool speakNextEye = false;
    bool saveResults = false;

    setState(() {
      _heardWords = '';
      _voiceMessage = '';
      _isListening = false;

      switch (_stage) {
        case _AccessibleStage.right:
          _rightResult = result;
          _rightBelowRange = belowRange;

          _resetLevel();

          _stage = _AccessibleStage.left;

          speakNextEye = true;
          break;

        case _AccessibleStage.left:
          _leftResult = result;
          _leftBelowRange = belowRange;

          _resetLevel();

          _stage = _AccessibleStage.both;

          speakNextEye = true;
          break;

        case _AccessibleStage.both:
          _bothResult = result;
          _bothBelowRange = belowRange;

          _stage = _AccessibleStage.finished;

          saveResults = true;
          break;

        case _AccessibleStage.instructions:
        case _AccessibleStage.finished:
          break;
      }
    });

    if (speakNextEye) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) {
          _speakCurrentInstructions();
        }
      });
    }

    if (saveResults) {
      _saveResults();
    }
  }

  // ================================================================
  // SAVE RESULTS
  // ================================================================

  void _saveResults() {
    if (_rightResult == null || _leftResult == null || _bothResult == null) {
      return;
    }

    final testDistance = _testProfile?.distanceCm ?? 300.0;

    ReportService.instance.updateAcuityModeAware(
      mode: vm.TestMode.distance,
      testMethod: VisionTestMethod.accessible,
      responseMethod: VisionResponseMethod.voiceAssisted,
      right: vm.AcuityResult(
        _rightResult!,
        eye: vm.EyeSide.right,
        belowRange: _rightBelowRange,
        correction: _correction,
        testDistanceCm: testDistance,
      ),
      left: vm.AcuityResult(
        _leftResult!,
        eye: vm.EyeSide.left,
        belowRange: _leftBelowRange,
        correction: _correction,
        testDistanceCm: testDistance,
      ),
      both: vm.AcuityResult(
        _bothResult!,
        eye: vm.EyeSide.both,
        belowRange: _bothBelowRange,
        correction: _correction,
        testDistanceCm: testDistance,
      ),
    );
  }

  void _restart() {
    _voice.stopSpeaking();
    _voice.cancelListening();

    setState(() {
      _rightResult = null;
      _leftResult = null;
      _bothResult = null;

      _rightBelowRange = false;
      _leftBelowRange = false;
      _bothBelowRange = false;

      _correction = vm.VisionCorrection.none;

      _heardWords = '';
      _voiceMessage = '';
      _isListening = false;

      // Keep screen calibration, but recalculate
      // the profile when the test starts again.
      _testProfile = null;

      _resetLevel();

      _stage = _AccessibleStage.instructions;
    });
  }

  // ================================================================
  // MAIN BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _AccessibleStage.instructions:
        return _buildInstructions();

      case _AccessibleStage.right:
      case _AccessibleStage.left:
      case _AccessibleStage.both:
        return _buildTest();

      case _AccessibleStage.finished:
        return _buildFinished();
    }
  }

  // ================================================================
  // INSTRUCTIONS
  // ================================================================

  Widget _buildInstructions() {
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Accessible Vision Test',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Large-Letter Distance Vision Screening',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8DCE3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before You Begin',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: 18),

                Text(
                  '1. PeekVision will first calibrate the physical size of '
                  'this screen.',
                  style: TextStyle(fontSize: 18, height: 1.4),
                ),

                SizedBox(height: 12),

                Text(
                  '2. After calibration, PeekVision will calculate an '
                  'appropriate viewing distance for this screen.',
                  style: TextStyle(fontSize: 18, height: 1.4),
                ),

                SizedBox(height: 12),

                Text(
                  '3. Follow the testing distance shown on the screen and '
                  'keep that distance throughout the test.',
                  style: TextStyle(fontSize: 18, height: 1.4),
                ),

                SizedBox(height: 12),

                Text(
                  '4. The test begins with very large letters and gradually '
                  'moves to smaller letters.',
                  style: TextStyle(fontSize: 18, height: 1.4),
                ),

                SizedBox(height: 12),

                Text(
                  '5. Five high-contrast letters are shown on every line. '
                  'Read them from left to right.',
                  style: TextStyle(fontSize: 18, height: 1.4),
                ),

                SizedBox(height: 12),

                Text(
                  '6. You may speak the letters or use the large buttons. '
                  'There is no time limit.',
                  style: TextStyle(fontSize: 18, height: 1.4),
                ),

                SizedBox(height: 12),

                Text(
                  '7. This Accessible Vision Test covers large-letter '
                  'screening levels from 20/400 through 20/50.',
                  style: TextStyle(fontSize: 18, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          SwitchListTile(
            value: _voiceEnabled,
            onChanged: (value) {
              setState(() {
                _voiceEnabled = value;
              });

              if (!value) {
                _voice.stopSpeaking();
              }
            },
            title: const Text(
              'Spoken instructions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              _voiceReady
                  ? 'PeekVision can read the instructions aloud.'
                  : 'Initializing voice features...',
            ),
            secondary: const Icon(Icons.volume_up),
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<vm.VisionCorrection>(
            initialValue: _correction,
            decoration: const InputDecoration(
              labelText: 'Vision correction used during this test',
              helperText: 'Choose what you are wearing right now.',
              border: OutlineInputBorder(),
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

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _startRight,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
            ),
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text(
              'Calibrate & Start Accessible Test',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'This is a preliminary browser-based vision screening. '
            'Display calibration improves consistency across different '
            'screens, but the result is still an approximation and does '
            'not replace a professionally calibrated eye chart or a '
            'comprehensive eye examination.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ACTIVE TEST
  // ================================================================

  Widget _buildTest() {
    final current = _steps[_index];
    final profile = _testProfile;

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 600;

        final fontSize = DisplayCalibrationService.instance.optotypeHeightPx(
          logMar: current,
          distanceCm: profile.distanceCm,
        );

        debugPrint(
          'Accessible level ${_snellen(current)} '
          'logMAR=$current '
          'fontSize=${fontSize.toStringAsFixed(2)}',
        );

        // The letter area must be tall enough for very large Accessible
        // optotypes. On mobile the whole test can then scroll vertically.
        final calculatedLetterHeight = fontSize * 1.8;

        final letterBoxHeight = calculatedLetterHeight < 220.0
            ? 220.0
            : calculatedLetterHeight;

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 12 : 18),
            children: [
              Row(
                children: [
                  const Icon(Icons.visibility, size: 27, color: Colors.black),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Testing $_eyeTitle',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  if (_voiceEnabled)
                    IconButton(
                      tooltip: 'Repeat spoken instructions',
                      onPressed: _repeatInstructions,
                      icon: const Icon(Icons.volume_up, color: Colors.black),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                _eyeInstruction,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Testing distance: ${profile.distanceLabel}',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                '${profile.deviceLabel} • Display calibrated',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: letterBoxHeight,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      _line,
                      key: ValueKey('accessible-line-$_index'),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: fontSize * 0.10,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Visual Acuity Level: ${_snellen(current)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),

              Text(
                'Level ${_index + 1} of ${_steps.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),

              const SizedBox(height: 10),

              if (_voiceReady)
                FilledButton.tonalIcon(
                  onPressed: _isListening ? _stopListening : _startListening,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  icon: Icon(
                    _isListening ? Icons.stop_circle : Icons.mic,
                    size: 27,
                  ),
                  label: Text(
                    _isListening
                        ? 'Stop & Check Answer'
                        : 'Speak the 5 Letters',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

              if (_voiceMessage.isNotEmpty) ...[
                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _voiceMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _markReadable,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(58),
                      ),
                      icon: const Icon(Icons.check, size: 28),
                      label: const Text(
                        'I Can Read',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _markNotReadable,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 2),
                        minimumSize: const Size.fromHeight(58),
                      ),
                      icon: const Icon(Icons.close, size: 28),
                      label: const Text(
                        'I Can’t Read',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ================================================================
  // REPORT HELPERS
  // ================================================================

  String _resultText(double? value, bool belowRange) {
    if (value == null) {
      return 'Not tested';
    }

    if (belowRange) {
      return 'Below the range measured by this test';
    }

    return _snellen(value);
  }

  String _classification(double? value, bool belowRange) {
    if (value == null) {
      return 'Not tested';
    }

    if (belowRange) {
      return 'Largest letters were difficult to read';
    }

    final level = _snellen(value);

    if (level == '20/50') {
      return 'Reached the smallest level available in this test';
    }

    if (level == '20/63') {
      return 'Stopped one level before the smallest level';
    }

    if (level == '20/80' || level == '20/100') {
      return 'Smaller letters became difficult within the test range';
    }

    if (level == '20/125' || level == '20/160') {
      return 'Noticeable difficulty with smaller letters';
    }

    if (level == '20/200' || level == '20/250') {
      return 'Substantial difficulty with smaller letters';
    }

    return 'Very large letters were required';
  }

  String _comparison(double? value, bool belowRange) {
    if (value == null) {
      return 'Not available';
    }

    if (belowRange) {
      return 'The largest level presented was difficult to read';
    }

    final level = _snellen(value);

    if (level == '20/50') {
      return 'Reached the smallest letter level offered by this test';
    }

    final next = _nextSmallerLevel(value);

    if (next != null) {
      return 'You read $level, but the next smaller $next level became difficult';
    }

    return 'Smaller letters became difficult';
  }

  String _meaning(double? value, bool belowRange, String eyeName) {
    if (value == null) {
      return '$eyeName was not tested.';
    }

    if (belowRange) {
      return '$eyeName had difficulty reading the largest letters presented '
          'in this Accessible Vision Test. Repeat the screening under the '
          'recommended conditions. If you get a similar result again, '
          'consider a professional eye examination.';
    }

    final level = _snellen(value);

    if (_reachedSmallest(value)) {
      return '$eyeName successfully read the smallest letters offered by '
          'this Accessible Vision Test. This means you completed the full '
          'large-letter range measured by this test.';
    }

    final next = _nextSmallerLevel(value);

    if (next != null) {
      return '$eyeName was able to read the $level level, but the next '
          'smaller $next level became difficult. This is the smallest '
          'large-letter level you were able to read during this screening.';
    }

    return '$eyeName reached the $level level during this screening.';
  }

  String _correctionGuidance(double? value, bool belowRange) {
    if (value == null) {
      return '';
    }

    if (_reachedSmallest(value) && !belowRange) {
      return 'You reached the smallest level offered by this Accessible '
          'Vision Test. This result alone cannot determine whether glasses '
          'are needed or whether an existing prescription should be changed.';
    }

    if (_correction == vm.VisionCorrection.none) {
      return 'You completed this screening without glasses or contact lenses. '
          'If you continue to notice difficulty seeing clearly, a professional '
          'eye examination and refraction can determine whether glasses or '
          'contact lenses may help.';
    }

    return 'You completed this screening while using your current vision '
        'correction. If you continue to notice difficulty seeing clearly, '
        'a professional eye examination can determine whether your '
        'prescription needs adjustment or whether another cause is involved.';
  }

  String _eyeComparison() {
    if (_rightResult == null || _leftResult == null) {
      return 'A comparison between the right and left eyes is not available.';
    }

    if (_rightBelowRange && _leftBelowRange) {
      return 'Both eyes had difficulty with the largest letters presented '
          'in this screening.';
    }

    if (_rightBelowRange) {
      return 'The RIGHT eye (OD) had more difficulty than the LEFT eye (OS).';
    }

    if (_leftBelowRange) {
      return 'The LEFT eye (OS) had more difficulty than the RIGHT eye (OD).';
    }

    if (_rightResult! > _leftResult!) {
      return 'The RIGHT eye (OD) had more difficulty with smaller letters '
          'than the LEFT eye (OS).';
    }

    if (_leftResult! > _rightResult!) {
      return 'The LEFT eye (OS) had more difficulty with smaller letters '
          'than the RIGHT eye (OD).';
    }

    return 'The RIGHT eye (OD) and LEFT eye (OS) reached the same '
        'screening level.';
  }

  String _overallImpression() {
    if (_rightBelowRange || _leftBelowRange || _bothBelowRange) {
      return 'One or more tested conditions had difficulty even with the '
          'largest letters presented. Repeat the screening under the '
          'recommended conditions. If you get a similar result again, '
          'consider a professional eye examination.';
    }

    final values = <double>[
      if (_rightResult != null) _rightResult!,
      if (_leftResult != null) _leftResult!,
      if (_bothResult != null) _bothResult!,
    ];

    if (values.isEmpty) {
      return 'No completed visual-acuity results are available.';
    }

    final allReachedSmallest = values.every(
      (value) => (value - _steps.last).abs() < 0.01,
    );

    if (allReachedSmallest) {
      return 'All tested conditions reached the smallest letter level '
          'offered by this Accessible Vision Test: 20/50. This means the '
          'full large-letter screening range was completed successfully.';
    }

    final worst = values.reduce((a, b) => a > b ? a : b);

    final level = _snellen(worst);

    return 'At least one tested condition could read the $level level but '
        'had difficulty with smaller letters. This screening shows where '
        'the large-letter test became difficult. If the result is repeatable '
        'or you are having trouble seeing in daily life, consider a '
        'professional eye examination.';
  }

  // ================================================================
  // DETAILED REPORT
  // ================================================================

  Widget _buildFinished() {
    Widget infoRow(String label, String value) {
      final isMobile = MediaQuery.of(context).size.width < 600;

      if (isMobile) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 170,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
    }

    Widget reportSection(String title, Widget child) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8DCE3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F3FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ),
      );
    }

    Widget eyeReport({
      required String title,
      required String eyeName,
      required double? value,
      required bool belowRange,
    }) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE1E4E8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 8),

            Text(
              _resultText(value, belowRange),
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: Color(0xFF174BAE),
              ),
            ),

            const SizedBox(height: 12),

            infoRow('Screening level:', _resultText(value, belowRange)),

            infoRow('Interpretation:', _classification(value, belowRange)),

            infoRow('Test range:', '20/400 to 20/50'),

            infoRow('How this compares:', _comparison(value, belowRange)),

            const SizedBox(height: 8),

            const Text(
              'What this means',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 6),

            Text(
              _meaning(value, belowRange, eyeName),
              style: const TextStyle(fontSize: 15, height: 1.45),
            ),

            if (value != null) ...[
              const SizedBox(height: 14),

              const Text(
                'About glasses or contacts',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 6),

              Text(
                _correctionGuidance(value, belowRange),
                style: const TextStyle(fontSize: 15, height: 1.45),
              ),
            ],
          ],
        ),
      );
    }

    final profile = _testProfile;

    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'ACCESSIBLE VISION SCREENING REPORT',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 6),

          const Text(
            'Large-Letter Distance Visual Acuity Screening',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),

          const SizedBox(height: 22),

          reportSection(
            'TEST INFORMATION',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoRow(
                  'Test type:',
                  'Accessible / Large-Letter Distance Vision Test',
                ),

                infoRow(
                  'Test distance:',
                  profile?.distanceLabel ?? 'Not available',
                ),

                infoRow('Device:', profile?.deviceLabel ?? 'Unknown'),

                infoRow(
                  'Display calibration:',
                  DisplayCalibrationService.instance.isCalibrated
                      ? 'Completed'
                      : 'Not completed',
                ),

                infoRow('Correction:', _correction.label),

                infoRow('Test range:', '20/400 to 20/50'),

                infoRow(
                  'Method:',
                  'Five-letter high-contrast browser vision screening',
                ),

                infoRow(
                  'Response options:',
                  'Voice recognition or large-button response',
                ),

                const SizedBox(height: 10),

                const Text(
                  'How your screening level is determined',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 6),

                const Text(
                  'The test begins with the largest letters and gradually '
                  'moves to smaller letters. Your screening level is the '
                  'smallest level you were able to read before the next '
                  'smaller level became difficult.',
                  style: TextStyle(height: 1.45),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Letter size is calculated using the calibrated display '
                  'scale and the testing distance selected for this screen. '
                  'If you reach 20/50, you have completed the full range '
                  'offered by this Accessible Vision Test.',
                  style: TextStyle(color: Colors.black54, height: 1.45),
                ),
              ],
            ),
          ),

          reportSection(
            'DISTANCE VISUAL ACUITY',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                eyeReport(
                  title: 'Right Eye (OD)',
                  eyeName: 'Your RIGHT eye',
                  value: _rightResult,
                  belowRange: _rightBelowRange,
                ),

                eyeReport(
                  title: 'Left Eye (OS)',
                  eyeName: 'Your LEFT eye',
                  value: _leftResult,
                  belowRange: _leftBelowRange,
                ),

                eyeReport(
                  title: 'Both Eyes (OU)',
                  eyeName: 'With BOTH eyes open',
                  value: _bothResult,
                  belowRange: _bothBelowRange,
                ),

                const SizedBox(height: 4),

                const Text(
                  'Eye-to-Eye Comparison',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),

                const SizedBox(height: 8),

                Text(
                  _eyeComparison(),
                  style: const TextStyle(fontSize: 15, height: 1.45),
                ),
              ],
            ),
          ),

          reportSection(
            'OVERALL SCREENING CONCLUSION',
            Text(
              _overallImpression(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),

          reportSection(
            'WHAT SHOULD I DO NEXT?',
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• If you reached 20/50, you completed the full range '
                  'offered by this Accessible Vision Test.',
                  style: TextStyle(fontSize: 15, height: 1.45),
                ),

                SizedBox(height: 10),

                Text(
                  '• If you stopped before 20/50, repeat the screening if '
                  'screen calibration, positioning, lighting, eye covering '
                  'or viewing distance may not have been correct.',
                  style: TextStyle(fontSize: 15, height: 1.45),
                ),

                SizedBox(height: 10),

                Text(
                  '• If you continue to have difficulty seeing clearly in '
                  'daily life, consider a comprehensive eye examination.',
                  style: TextStyle(fontSize: 15, height: 1.45),
                ),

                SizedBox(height: 10),

                Text(
                  '• If one eye performs noticeably differently from the '
                  'other, repeat the screening. If the difference remains, '
                  'consider professional evaluation.',
                  style: TextStyle(fontSize: 15, height: 1.45),
                ),

                SizedBox(height: 10),

                Text(
                  '• Sudden vision loss, severe eye pain, new flashes or '
                  'floaters, or an eye injury should be evaluated promptly '
                  'by an eye-care professional.',
                  style: TextStyle(fontSize: 15, height: 1.45),
                ),
              ],
            ),
          ),

          reportSection(
            'SCREENING LIMITATIONS',
            const Text(
              'PeekVision provides preliminary browser-based vision '
              'screening only. Display calibration and distance-based '
              'letter sizing improve consistency across phones, tablets '
              'and computer screens, but browser rendering and user '
              'calibration are still approximations. This Accessible Vision '
              'Test measures large-letter levels from 20/400 through 20/50. '
              'It does not diagnose the cause of reduced vision, determine '
              'an eyeglass prescription, or evaluate eye pressure, retina, '
              'optic nerve or other clinical findings. Browser zoom, display '
              'scaling, calibration accuracy, viewing distance, lighting, '
              'speech recognition and user responses can affect the result.',
              style: TextStyle(fontSize: 15, height: 1.45),
            ),
          ),

          FilledButton.icon(
            onPressed: _restart,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text(
              'Retake Accessible Vision Test',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
