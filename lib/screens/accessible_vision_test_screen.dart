// lib/screens/accessible_vision_test_screen.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/vision_models.dart' as vm;
import '../services/report_service.dart';
import '../services/voice_service.dart';

enum _AccessibleStage {
  instructions,
  right,
  left,
  both,
  finished,
}

class AccessibleVisionTestScreen extends StatefulWidget {
  const AccessibleVisionTestScreen({
    super.key,
  });

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

  static const String _alphabet =
      'CDHKNORSVZ';

  final math.Random _random =
      math.Random();

  // ================================================================
  // VOICE
  // ================================================================

  final VoiceService _voice =
      VoiceService.instance;

  bool _voiceEnabled = true;
  bool _voiceReady = false;
  bool _isListening = false;

  String _heardWords = '';
  String _voiceMessage = '';

  // ================================================================
  // TEST STATE
  // ================================================================

  _AccessibleStage _stage =
      _AccessibleStage.instructions;

  int _index = 0;
  int _lastPassed = -1;

  String _line = '';

  double? _rightResult;
  double? _leftResult;
  double? _bothResult;

  bool _rightBelowRange = false;
  bool _leftBelowRange = false;
  bool _bothBelowRange = false;

  vm.VisionCorrection _correction =
      vm.VisionCorrection.none;

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
      _voiceReady =
          _voice.speechAvailable;
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
      (_) => _alphabet[
          _random.nextInt(
        _alphabet.length,
      )],
    ).join(' ');
  }

  String _snellen(
    double logMAR,
  ) {
    if ((logMAR - 1.3).abs() <
        0.01) {
      return '20/400';
    }

    if ((logMAR - 1.2).abs() <
        0.01) {
      return '20/320';
    }

    if ((logMAR - 1.1).abs() <
        0.01) {
      return '20/250';
    }

    if ((logMAR - 1.0).abs() <
        0.01) {
      return '20/200';
    }

    if ((logMAR - 0.9).abs() <
        0.01) {
      return '20/160';
    }

    if ((logMAR - 0.8).abs() <
        0.01) {
      return '20/125';
    }

    if ((logMAR - 0.7).abs() <
        0.01) {
      return '20/100';
    }

    if ((logMAR - 0.6).abs() <
        0.01) {
      return '20/80';
    }

    if ((logMAR - 0.5).abs() <
        0.01) {
      return '20/63';
    }

    return '20/50';
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

    String instruction;

    switch (_stage) {
      case _AccessibleStage.right:
        instruction =
            'Cover your left eye and use only your right eye. '
            'Stay approximately ten feet from the screen. '
            'Read the five letters from left to right.';
        break;

      case _AccessibleStage.left:
        instruction =
            'Cover your right eye and use only your left eye. '
            'Stay approximately ten feet from the screen. '
            'Read the five letters from left to right.';
        break;

      case _AccessibleStage.both:
        instruction =
            'Keep both eyes open. '
            'Stay approximately ten feet from the screen. '
            'Read the five letters from left to right.';
        break;

      default:
        return;
    }

    await _voice.speak(
      instruction,
    );
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

      _voiceMessage =
          'Listening... Say the five letters from left to right.';

      _isListening = true;
    });

    await _voice.listen(
      onWords: (words) {
        if (!mounted) {
          return;
        }

        setState(() {
          _heardWords =
              words.toUpperCase();
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

    final expected =
        _line
            .replaceAll(
              ' ',
              '',
            )
            .toUpperCase()
            .split('');

    final recognized =
        _extractLetters(
      _heardWords,
    );

    if (recognized.isEmpty) {
      setState(() {
        _voiceMessage =
            'I heard "$_heardWords", but could not identify the test letters. '
            'Please try again or use the buttons below.';
      });

      return;
    }

    int correct = 0;

    final count =
        math.min(
      expected.length,
      recognized.length,
    );

    for (int i = 0;
        i < count;
        i++) {
      if (expected[i] ==
          recognized[i]) {
        correct++;
      }
    }

    final recognizedText =
        recognized.join(' ');

    setState(() {
      _voiceMessage =
          'Heard: $recognizedText  •  $correct of 5 correct';
    });

    if (correct >= 3) {
      Future.delayed(
        const Duration(
          milliseconds: 900,
        ),
        () {
          if (mounted) {
            _markReadable();
          }
        },
      );
    } else {
      Future.delayed(
        const Duration(
          milliseconds: 900,
        ),
        () {
          if (mounted) {
            _markNotReadable();
          }
        },
      );
    }
  }

  // ================================================================
  // U.S. ENGLISH LETTER-NAME PARSER
  // ================================================================

  List<String> _extractLetters(
    String speech,
  ) {
    final text =
        speech
            .toUpperCase()
            .replaceAll(
              ',',
              ' ',
            )
            .replaceAll(
              '.',
              ' ',
            )
            .replaceAll(
              '-',
              ' ',
            );

    final words =
        text
            .split(
              RegExp(r'\s+'),
            )
            .where(
              (word) =>
                  word.trim().isNotEmpty,
            )
            .toList();

    const letterNames =
        <String, String>{
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

    final result =
        <String>[];

    for (final word in words) {
      final clean =
          word.replaceAll(
        RegExp('[^A-Z]'),
        '',
      );

      if (clean.isEmpty) {
        continue;
      }

      final mapped =
          letterNames[clean];

      if (mapped != null) {
        result.add(
          mapped,
        );
      } else if (
          clean.length == 1 &&
          _alphabet.contains(
            clean,
          )) {
        result.add(
          clean,
        );
      } else {
        // Sometimes speech recognition may return
        // several letters joined together, such as "CVRKD".
        bool allAllowed = true;

        for (final rune in clean.runes) {
          final letter =
              String.fromCharCode(
            rune,
          );

          if (!_alphabet.contains(
            letter,
          )) {
            allAllowed = false;
            break;
          }
        }

        if (allAllowed) {
          for (final rune in clean.runes) {
            result.add(
              String.fromCharCode(
                rune,
              ),
            );

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

    return result
        .take(5)
        .toList();
  }

  // ================================================================
  // TEST FLOW
  // ================================================================

  void _startRight() {
    setState(() {
      _resetLevel();

      _stage =
          _AccessibleStage.right;
    });

    Future.delayed(
      const Duration(
        milliseconds: 400,
      ),
      () {
        if (mounted) {
          _speakCurrentInstructions();
        }
      },
    );
  }

  void _markReadable() {
    if (_index <
        _steps.length - 1) {
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

    _finishCurrentEye(
      belowRange: false,
    );
  }

  void _markNotReadable() {
    _finishCurrentEye(
      belowRange:
          _lastPassed < 0,
    );
  }

  void _finishCurrentEye({
    required bool belowRange,
  }) {
    final result =
        _lastPassed >= 0
            ? _steps[_lastPassed]
            : _steps.first;

    bool speakNextEye = false;
    bool saveResults = false;

    setState(() {
      _heardWords = '';
      _voiceMessage = '';
      _isListening = false;

      switch (_stage) {
        case _AccessibleStage.right:
          _rightResult =
              result;

          _rightBelowRange =
              belowRange;

          _resetLevel();

          _stage =
              _AccessibleStage.left;

          speakNextEye = true;

          break;

        case _AccessibleStage.left:
          _leftResult =
              result;

          _leftBelowRange =
              belowRange;

          _resetLevel();

          _stage =
              _AccessibleStage.both;

          speakNextEye = true;

          break;

        case _AccessibleStage.both:
          _bothResult =
              result;

          _bothBelowRange =
              belowRange;

          _stage =
              _AccessibleStage.finished;

          saveResults = true;

          break;

        case _AccessibleStage.instructions:
        case _AccessibleStage.finished:
          break;
      }
    });

    if (speakNextEye) {
      Future.delayed(
        const Duration(
          milliseconds: 450,
        ),
        () {
          if (mounted) {
            _speakCurrentInstructions();
          }
        },
      );
    }

    if (saveResults) {
      _saveResults();
    }
  }

  // ================================================================
  // SAVE RESULTS
  // ================================================================

  void _saveResults() {
    if (_rightResult == null ||
        _leftResult == null ||
        _bothResult == null) {
      return;
    }

    ReportService.instance
        .updateAcuityModeAware(
      mode:
          vm.TestMode.distance,
      testMethod:
          VisionTestMethod.accessible,     
      responseMethod:
          VisionResponseMethod.voiceAssisted, 

      right:
          vm.AcuityResult(
        _rightResult!,
        eye:
            vm.EyeSide.right,
        belowRange:
            _rightBelowRange,
        correction:
            _correction,
        testDistanceCm:
            300,
      ),

      left:
          vm.AcuityResult(
        _leftResult!,
        eye:
            vm.EyeSide.left,
        belowRange:
            _leftBelowRange,
        correction:
            _correction,
        testDistanceCm:
            300,
      ),

      both:
          vm.AcuityResult(
        _bothResult!,
        eye:
            vm.EyeSide.both,
        belowRange:
            _bothBelowRange,
        correction:
            _correction,
        testDistanceCm:
            300,
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

      _correction =
          vm.VisionCorrection.none;

      _heardWords = '';
      _voiceMessage = '';
      _isListening = false;

      _resetLevel();

      _stage =
          _AccessibleStage.instructions;
    });
  }

  // ================================================================
  // MAIN BUILD
  // ================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
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
      color:
          Colors.white,
      child:
          ListView(
        padding:
            const EdgeInsets.all(
          20,
        ),
        children: [
          const Text(
            'Accessible Vision Test',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize:
                  26,
              fontWeight:
                  FontWeight.w900,
              color:
                  Colors.black,
            ),
          ),

          const SizedBox(
            height:
                8,
          ),

          const Text(
            'Large-Letter Distance Vision Screening',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize:
                  18,
              fontWeight:
                  FontWeight.w600,
              color:
                  Colors.black87,
            ),
          ),

          const SizedBox(
            height:
                24,
          ),

          Container(
            padding:
                const EdgeInsets.all(
              20,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF5F6F8,
              ),
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              border:
                  Border.all(
                color:
                    const Color(
                  0xFFD8DCE3,
                ),
              ),
            ),
            child:
                const Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Before You Begin',
                  style:
                      TextStyle(
                    fontSize:
                        21,
                    fontWeight:
                        FontWeight.w900,
                    color:
                        Colors.black,
                  ),
                ),

                SizedBox(
                  height:
                      18,
                ),

                Text(
                  '1. Stay approximately 10 ft / 3 m from the screen.',
                  style:
                      TextStyle(
                    fontSize:
                        18,
                    height:
                        1.4,
                  ),
                ),

                SizedBox(
                  height:
                      12,
                ),

                Text(
                  '2. The test begins with very large letters.',
                  style:
                      TextStyle(
                    fontSize:
                        18,
                    height:
                        1.4,
                  ),
                ),

                SizedBox(
                  height:
                      12,
                ),

                Text(
                  '3. Five high-contrast letters are shown on every line.',
                  style:
                      TextStyle(
                    fontSize:
                        18,
                    height:
                        1.4,
                  ),
                ),

                SizedBox(
                  height:
                      12,
                ),

                Text(
                  '4. Read the five letters from left to right.',
                  style:
                      TextStyle(
                    fontSize:
                        18,
                    height:
                        1.4,
                  ),
                ),

                SizedBox(
                  height:
                      12,
                ),

                Text(
                  '5. You may speak the letters or use the large buttons.',
                  style:
                      TextStyle(
                    fontSize:
                        18,
                    height:
                        1.4,
                  ),
                ),

                SizedBox(
                  height:
                      12,
                ),

                Text(
                  '6. There is no time limit.',
                  style:
                      TextStyle(
                    fontSize:
                        18,
                    height:
                        1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height:
                18,
          ),

          SwitchListTile(
            value:
                _voiceEnabled,
            onChanged:
                (value) {
              setState(() {
                _voiceEnabled =
                    value;
              });

              if (!value) {
                _voice.stopSpeaking();
              }
            },
            title:
                const Text(
              'Spoken instructions',
              style:
                  TextStyle(
                fontSize:
                    18,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            subtitle:
                Text(
              _voiceReady
                  ? 'PeekVision can read the instructions aloud.'
                  : 'Initializing voice features...',
            ),
            secondary:
                const Icon(
              Icons.volume_up,
            ),
          ),

          const SizedBox(
            height:
                12,
          ),

          DropdownButtonFormField<
              vm.VisionCorrection>(
            initialValue:
                _correction,
            decoration:
                const InputDecoration(
              labelText:
                  'Vision correction used during this test',
              helperText:
                  'Choose what you are wearing right now.',
              border:
                  OutlineInputBorder(),
            ),
            items:
                const [
              DropdownMenuItem(
                value:
                    vm.VisionCorrection.none,
                child:
                    Text(
                  'No glasses or contacts',
                ),
              ),
              DropdownMenuItem(
                value:
                    vm.VisionCorrection.distanceGlasses,
                child:
                    Text(
                  'Distance glasses',
                ),
              ),
              DropdownMenuItem(
                value:
                    vm.VisionCorrection.contactLenses,
                child:
                    Text(
                  'Contact lenses',
                ),
              ),
            ],
            onChanged:
                (value) {
              if (value ==
                  null) {
                return;
              }

              setState(() {
                _correction =
                    value;
              });
            },
          ),

          const SizedBox(
            height:
                24,
          ),

          FilledButton.icon(
            onPressed:
                _startRight,
            style:
                FilledButton.styleFrom(
              minimumSize:
                  const Size.fromHeight(
                60,
              ),
            ),
            icon:
                const Icon(
              Icons.play_arrow,
              size:
                  28,
            ),
            label:
                const Text(
              'Start Accessible Vision Test',
              style:
                  TextStyle(
                fontSize:
                    19,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(
            height:
                18,
          ),

          const Text(
            'This is a preliminary browser-based vision screening. '
            'It does not diagnose eye disease and does not replace a '
            'comprehensive eye examination.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.black54,
              fontSize:
                  14,
              height:
                  1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ACTIVE TEST
  // ================================================================

  Widget _buildTest() {
    final current =
        _steps[_index];

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final availableWidth =
            constraints.maxWidth;

        final availableHeight =
            constraints.maxHeight;

        final calculated =
            availableWidth *
                0.12 *
                math.pow(
                  10,
                  current -
                      0.4,
                );

        final maxByWidth =
            availableWidth *
                0.115;

        final maxByHeight =
            availableHeight *
                0.23;

        final fontSize =
            math.min(
          calculated,
          math.min(
            maxByWidth,
            maxByHeight,
          ),
        );

        return Container(
          width:
              double.infinity,
          height:
              double.infinity,
          color:
              Colors.white,
          padding:
              const EdgeInsets.all(
            18,
          ),
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.visibility,
                    size:
                        27,
                    color:
                        Colors.black,
                  ),

                  const SizedBox(
                    width:
                        10,
                  ),

                  Expanded(
                    child:
                        Text(
                      'Testing $_eyeTitle',
                      style:
                          const TextStyle(
                        fontSize:
                            22,
                        fontWeight:
                            FontWeight.w900,
                        color:
                            Colors.black,
                      ),
                    ),
                  ),

                  if (_voiceEnabled)
                    IconButton(
                      tooltip:
                          'Repeat spoken instructions',
                      onPressed:
                          _repeatInstructions,
                      icon:
                          const Icon(
                        Icons.volume_up,
                        color:
                            Colors.black,
                      ),
                    ),
                ],
              ),

              const SizedBox(
                height:
                    8,
              ),

              Text(
                _eyeInstruction,
                style:
                    const TextStyle(
                  fontSize:
                      19,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Colors.black,
                ),
              ),

              const SizedBox(
                height:
                    4,
              ),

              const Text(
                'Stay approximately 10 ft / 3 m from the screen.',
                style:
                    TextStyle(
                  fontSize:
                      16,
                  color:
                      Colors.black87,
                ),
              ),

              const SizedBox(
                height:
                    12,
              ),

              Expanded(
                child:
                    Container(
                  width:
                      double.infinity,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,
                    border:
                        Border.all(
                      color:
                          Colors.black,
                      width:
                          2,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child:
                      Center(
                    child:
                        FittedBox(
                      fit:
                          BoxFit.scaleDown,
                      child:
                          Text(
                        _line,
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          fontSize:
                              fontSize,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing:
                              12,
                          color:
                              Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height:
                    10,
              ),

              Text(
                'Visual Acuity Level: ${_snellen(current)}',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize:
                      19,
                  fontWeight:
                      FontWeight.w900,
                  color:
                      Colors.black,
                ),
              ),

              const SizedBox(
                height:
                    10,
              ),

              if (_voiceReady)
                FilledButton.tonalIcon(
                  onPressed:
                      _isListening
                          ? _stopListening
                          : _startListening,
                  style:
                      FilledButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(
                      56,
                    ),
                  ),
                  icon:
                      Icon(
                    _isListening
                        ? Icons.stop_circle
                        : Icons.mic,
                    size:
                        27,
                  ),
                  label:
                      Text(
                    _isListening
                        ? 'Stop & Check Answer'
                        : 'Speak the 5 Letters',
                    style:
                        const TextStyle(
                      fontSize:
                          18,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),

              if (_voiceMessage.isNotEmpty) ...[
                const SizedBox(
                  height:
                      8,
                ),

                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.all(
                    10,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFF3F4F6,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  child:
                      Text(
                    _voiceMessage,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize:
                          15,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Colors.black,
                    ),
                  ),
                ),
              ],

              const SizedBox(
                height:
                    10,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        FilledButton.icon(
                      onPressed:
                          _markReadable,
                      style:
                          FilledButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(
                          58,
                        ),
                      ),
                      icon:
                          const Icon(
                        Icons.check,
                        size:
                            28,
                      ),
                      label:
                          const Text(
                        'I Can Read',
                        style:
                            TextStyle(
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width:
                        12,
                  ),

                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          _markNotReadable,
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            Colors.black,
                        side:
                            const BorderSide(
                          color:
                              Colors.black,
                          width:
                              2,
                        ),
                        minimumSize:
                            const Size.fromHeight(
                          58,
                        ),
                      ),
                      icon:
                          const Icon(
                        Icons.close,
                        size:
                            28,
                      ),
                      label:
                          const Text(
                        'I Can’t Read',
                        style:
                            TextStyle(
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ================================================================
  // DETAILED REPORT
  // ================================================================

  Widget _buildFinished() {
    String resultText(
      double? value,
      bool belowRange,
    ) {
      if (value == null) {
        return 'Not tested';
      }

      if (belowRange) {
        return 'Below measurable online screening range';
      }

      return _snellen(
        value,
      );
    }

    String classification(
      double? value,
      bool belowRange,
    ) {
      if (value == null) {
        return 'Not tested';
      }

      if (belowRange) {
        return 'Below measurable screening range';
      }

      final level =
          _snellen(
        value,
      );

      if (level ==
              '20/400' ||
          level ==
              '20/320') {
        return 'Severe reduction in visual acuity';
      }

      if (level ==
              '20/250' ||
          level ==
              '20/200') {
        return 'Significant reduction in visual acuity';
      }

      if (level ==
              '20/160' ||
          level ==
              '20/125') {
        return 'Marked reduction in visual acuity';
      }

      if (level ==
              '20/100' ||
          level ==
              '20/80') {
        return 'Moderate reduction in visual acuity';
      }

      return 'Reduced visual acuity';
    }

    String comparison(
      double? value,
      bool belowRange,
    ) {
      if (value == null) {
        return 'Not available';
      }

      if (belowRange) {
        return 'Below the range measured by this online screening';
      }

      return 'Below normal 20/20 visual acuity';
    }

    String meaning(
      double? value,
      bool belowRange,
      String eyeName,
    ) {
      if (value == null) {
        return '$eyeName was not tested.';
      }

      if (belowRange) {
        return '$eyeName could not identify the largest letters presented '
            'during this Accessible Vision Test. The result is below the '
            'measurable range of this online screening. A comprehensive '
            'eye examination is recommended.';
      }

      final level =
          _snellen(
        value,
      );

      if (level ==
              '20/400' ||
          level ==
              '20/320') {
        return '$eyeName required very large letters during this screening. '
            'This indicates substantially reduced distance visual acuity '
            'compared with normal 20/20 visual acuity.';
      }

      if (level ==
              '20/250' ||
          level ==
              '20/200') {
        return '$eyeName required much larger letters than the normal 20/20 '
            'line during this screening. This represents a significant '
            'reduction in distance visual acuity.';
      }

      if (level ==
              '20/160' ||
          level ==
              '20/125') {
        return '$eyeName showed a marked reduction in distance visual acuity '
            'compared with normal 20/20 visual acuity.';
      }

      if (level ==
              '20/100' ||
          level ==
              '20/80') {
        return '$eyeName showed a moderate reduction in distance visual acuity '
            'during this screening.';
      }

      return '$eyeName showed reduced distance visual acuity compared with '
          'normal 20/20 visual acuity.';
    }

    String eyeComparison() {
      if (_rightResult ==
              null ||
          _leftResult ==
              null) {
        return 'A comparison between the right and left eyes is not available.';
      }

      if (_rightBelowRange &&
          _leftBelowRange) {
        return 'Both the RIGHT eye (OD) and LEFT eye (OS) were below the '
            'measurable range of this online screening.';
      }

      if (_rightBelowRange) {
        return 'The RIGHT eye (OD) performed weaker than the LEFT eye (OS). '
            'The right-eye result was below the measurable range of this '
            'online screening.';
      }

      if (_leftBelowRange) {
        return 'The LEFT eye (OS) performed weaker than the RIGHT eye (OD). '
            'The left-eye result was below the measurable range of this '
            'online screening.';
      }

      if (_rightResult! >
          _leftResult!) {
        return 'The RIGHT eye (OD) showed greater reduction in visual acuity '
            'than the LEFT eye (OS).';
      }

      if (_leftResult! >
          _rightResult!) {
        return 'The LEFT eye (OS) showed greater reduction in visual acuity '
            'than the RIGHT eye (OD).';
      }

      return 'The RIGHT eye (OD) and LEFT eye (OS) produced similar '
          'visual-acuity results.';
    }

    String overallImpression() {
      if (_rightBelowRange ||
          _leftBelowRange ||
          _bothBelowRange) {
        return 'One or more results were below the measurable range of the '
            'Accessible Vision Test. This screening cannot determine the '
            'cause of reduced vision. A comprehensive eye examination is '
            'recommended.';
      }

      final values =
          <double>[
        if (_rightResult !=
            null)
          _rightResult!,

        if (_leftResult !=
            null)
          _leftResult!,

        if (_bothResult !=
            null)
          _bothResult!,
      ];

      if (values.isEmpty) {
        return 'No completed visual-acuity results are available.';
      }

      final worst =
          values.reduce(
        (a, b) =>
            a > b
                ? a
                : b,
      );

      if (worst >=
          1.0) {
        return 'The Accessible Vision Test showed a significant reduction in '
            'distance visual acuity in one or more tested eyes.';
      }

      if (worst >=
          0.7) {
        return 'The Accessible Vision Test showed a moderate-to-marked '
            'reduction in distance visual acuity in one or more tested eyes.';
      }

      return 'The Accessible Vision Test showed reduced distance visual acuity '
          'in one or more tested eyes.';
    }

    Widget infoRow(
      String label,
      String value,
    ) {
      return Padding(
        padding:
            const EdgeInsets.only(
          bottom:
              8,
        ),
        child:
            Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width:
                  170,
              child:
                  Text(
                label,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),

            Expanded(
              child:
                  Text(
                value,
              ),
            ),
          ],
        ),
      );
    }

    Widget reportSection(
      String title,
      Widget child,
    ) {
      return Container(
        width:
            double.infinity,
        margin:
            const EdgeInsets.only(
          bottom:
              16,
        ),
        decoration:
            BoxDecoration(
          color:
              Colors.white,
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          border:
              Border.all(
            color:
                const Color(
              0xFFD8DCE3,
            ),
          ),
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal:
                    16,
                vertical:
                    13,
              ),
              decoration:
                  const BoxDecoration(
                color:
                    Color(
                  0xFFF0F3FA,
                ),
                borderRadius:
                    BorderRadius.vertical(
                  top:
                      Radius.circular(
                    14,
                  ),
                ),
              ),
              child:
                  Text(
                title,
                style:
                    const TextStyle(
                  fontSize:
                      17,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              child:
                  child,
            ),
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
        width:
            double.infinity,
        margin:
            const EdgeInsets.only(
          bottom:
              14,
        ),
        padding:
            const EdgeInsets.all(
          16,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(
            0xFFF7F8FA,
          ),
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          border:
              Border.all(
            color:
                const Color(
              0xFFE1E4E8,
            ),
          ),
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  const TextStyle(
                fontSize:
                    18,
                fontWeight:
                    FontWeight.w900,
              ),
            ),

            const SizedBox(
              height:
                  8,
            ),

            Text(
              resultText(
                value,
                belowRange,
              ),
              style:
                  const TextStyle(
                fontSize:
                    27,
                fontWeight:
                    FontWeight.w900,
                color:
                    Color(
                  0xFF174BAE,
                ),
              ),
            ),

            const SizedBox(
              height:
                  12,
            ),

            infoRow(
              'Interpretation:',
              classification(
                value,
                belowRange,
              ),
            ),

            infoRow(
              'Normal reference:',
              '20/20',
            ),

            infoRow(
              'Comparison:',
              comparison(
                value,
                belowRange,
              ),
            ),

            const SizedBox(
              height:
                  8,
            ),

            const Text(
              'What this means',
              style:
                  TextStyle(
                fontSize:
                    15,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height:
                  6,
            ),

            Text(
              meaning(
                value,
                belowRange,
                eyeName,
              ),
              style:
                  const TextStyle(
                fontSize:
                    15,
                height:
                    1.45,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color:
          Colors.white,
      child:
          ListView(
        padding:
            const EdgeInsets.all(
          18,
        ),
        children: [
          const Text(
            'ACCESSIBLE VISION SCREENING REPORT',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize:
                  25,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            height:
                6,
          ),

          const Text(
            'Large-Letter Distance Visual Acuity Screening',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              fontSize:
                  16,
              color:
                  Colors.black54,
            ),
          ),

          const SizedBox(
            height:
                22,
          ),

          reportSection(
            'TEST INFORMATION',
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                infoRow(
                  'Test type:',
                  'Accessible / Large-Letter Distance Vision Test',
                ),

                infoRow(
                  'Test distance:',
                  'Approximately 10 ft / 3 m',
                ),

                infoRow(
                  'Correction:',
                  _correction.label,
                ),

                infoRow(
                  'Normal reference:',
                  '20/20',
                ),

                infoRow(
                  'Method:',
                  'Five-letter high-contrast browser vision screening',
                ),

                infoRow(
                  'Response options:',
                  'Voice recognition or large-button response',
                ),

                infoRow(
                  'Largest level:',
                  '20/400',
                ),

                infoRow(
                  'Smallest level:',
                  '20/50',
                ),
              ],
            ),
          ),

          reportSection(
            'DISTANCE VISUAL ACUITY',
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                eyeReport(
                  title:
                      'Right Eye (OD)',
                  eyeName:
                      'Your RIGHT eye',
                  value:
                      _rightResult,
                  belowRange:
                      _rightBelowRange,
                ),

                eyeReport(
                  title:
                      'Left Eye (OS)',
                  eyeName:
                      'Your LEFT eye',
                  value:
                      _leftResult,
                  belowRange:
                      _leftBelowRange,
                ),

                eyeReport(
                  title:
                      'Both Eyes (OU)',
                  eyeName:
                      'Your combined vision with BOTH eyes',
                  value:
                      _bothResult,
                  belowRange:
                      _bothBelowRange,
                ),

                const SizedBox(
                  height:
                      4,
                ),

                const Text(
                  'Eye-to-Eye Comparison',
                  style:
                      TextStyle(
                    fontSize:
                        16,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height:
                      8,
                ),

                Text(
                  eyeComparison(),
                  style:
                      const TextStyle(
                    fontSize:
                        15,
                    height:
                        1.45,
                  ),
                ),
              ],
            ),
          ),

          reportSection(
            'OVERALL SCREENING IMPRESSION',
            Text(
              overallImpression(),
              style:
                  const TextStyle(
                fontSize:
                    16,
                fontWeight:
                    FontWeight.w600,
                height:
                    1.5,
              ),
            ),
          ),

          reportSection(
            'RECOMMENDATION',
            const Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '• Repeat the screening if positioning, lighting, eye covering, '
                  'or viewing distance may not have been correct.',
                  style:
                      TextStyle(
                    fontSize:
                        15,
                    height:
                        1.45,
                  ),
                ),

                SizedBox(
                  height:
                      10,
                ),

                Text(
                  '• If visual acuity remains substantially reduced, consider a '
                  'comprehensive examination by an optometrist or ophthalmologist.',
                  style:
                      TextStyle(
                    fontSize:
                        15,
                    height:
                        1.45,
                  ),
                ),

                SizedBox(
                  height:
                      10,
                ),

                Text(
                  '• If one eye performs significantly differently from the other, '
                  'professional evaluation is recommended.',
                  style:
                      TextStyle(
                    fontSize:
                        15,
                    height:
                        1.45,
                  ),
                ),

                SizedBox(
                  height:
                      10,
                ),

                Text(
                  '• Sudden loss of vision, severe eye pain, new flashes or '
                  'floaters, or an eye injury should be evaluated promptly.',
                  style:
                      TextStyle(
                    fontSize:
                        15,
                    height:
                        1.45,
                  ),
                ),
              ],
            ),
          ),

          reportSection(
            'SCREENING LIMITATIONS',
            const Text(
              'PeekVision provides preliminary browser-based vision screening '
              'only. This test does not diagnose the cause of reduced vision, '
              'eye disease, eyeglass prescription, eye pressure, retinal '
              'conditions, optic nerve disease or other clinical findings. '
              'Screen dimensions, display scaling, viewing distance, lighting, '
              'speech recognition and user responses can affect the result.',
              style:
                  TextStyle(
                fontSize:
                    15,
                height:
                    1.45,
              ),
            ),
          ),

          FilledButton.icon(
            onPressed:
                _restart,
            style:
                FilledButton.styleFrom(
              minimumSize:
                  const Size.fromHeight(
                56,
              ),
            ),
            icon:
                const Icon(
              Icons.refresh,
            ),
            label:
                const Text(
              'Retake Accessible Vision Test',
              style:
                  TextStyle(
                fontSize:
                    17,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(
            height:
                12,
          ),
        ],
      ),
    );
  }
}