import 'dart:ui';
import 'package:flutter/material.dart';

class ColorBlindnessScreen extends StatefulWidget {
  const ColorBlindnessScreen({super.key});

  @override
  State<ColorBlindnessScreen> createState() => _ColorBlindnessScreenState();
}

class _ColorBlindnessScreenState extends State<ColorBlindnessScreen> {
  final List<String> plates = List.generate(
    12,
    (i) => 'assets/ishihara/p${(i + 1).toString().padLeft(2, '0')}.png',
  );

  /*
    IMPORTANT:
    Update these expected answers to match your actual plate images.

    Example:
    Plate 1 image = assets/ishihara/p01.png -> expectedAnswers[0]
    Plate 2 image = assets/ishihara/p02.png -> expectedAnswers[1]

    Use "nothing" for plates where the expected answer is no visible number.
  */
  final List<String> expectedAnswers = [
    '12',
    '8',
    '6',
    '5',
    '74',
    '45',
    '29',
    '17',
    '52',
    '7',
    '8',
    'nothing',
  ];

  int index = 0;
  int correctCount = 0;
  int incorrectCount = 0;

  final List<String> userAnswers = [];
  final TextEditingController _answer = TextEditingController();

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  String get currentPlate => plates[index];

  String _normalizeAnswer(String value) {
    final cleaned = value.trim().toLowerCase();

    if (cleaned == 'none' ||
        cleaned == 'no' ||
        cleaned == 'nothing' ||
        cleaned == 'blank' ||
        cleaned == 'cannot see' ||
        cleaned == "can't see" ||
        cleaned == 'cant see') {
      return 'nothing';
    }

    return cleaned.replaceAll(' ', '');
  }

  bool _isAnswerCorrect({
    required String userAnswer,
    required String expectedAnswer,
  }) {
    return _normalizeAnswer(userAnswer) == _normalizeAnswer(expectedAnswer);
  }

  String _resultTitle({required int correct, required int total}) {
    if (correct >= total - 1) {
      return 'Responses were generally consistent with the expected plate answers.';
    }

    if (correct >= (total * 0.70).round()) {
      return 'Some responses differed from the expected plate answers.';
    }

    return 'Several responses differed from the expected plate answers.';
  }

  String _resultExplanation({required int correct, required int total}) {
    if (correct >= total - 1) {
      return 'Most of your responses matched the expected answers for these Ishihara-style screening plates. This result is for preliminary screening only.';
    }

    if (correct >= (total * 0.70).round()) {
      return 'Some responses did not match the expected answers. Screen brightness, display color settings, lighting, viewing distance, and device calibration can affect the result. Consider repeating the screening under recommended conditions.';
    }

    return 'Several responses did not match the expected answers. This does not diagnose a color vision condition. Consider discussing the result with an optometrist or ophthalmologist, especially if you have concerns about color perception.';
  }

  String _missedPlateSummary() {
    final missed = <String>[];

    for (int i = 0; i < userAnswers.length; i++) {
      final user = userAnswers[i];
      final expected = expectedAnswers[i];

      if (!_isAnswerCorrect(userAnswer: user, expectedAnswer: expected)) {
        missed.add('Plate ${i + 1}: expected "$expected", entered "$user"');
      }
    }

    if (missed.isEmpty) {
      return 'Missed plates: None';
    }

    return 'Missed plates:\n${missed.join('\n')}';
  }

  String _finalResultText() {
    final total = plates.length;
    final percent = total == 0 ? 0 : ((correctCount / total) * 100).round();
    final missed = total - correctCount;

    return 'Result: ${_resultTitle(correct: correctCount, total: total)}\n\n'
        'Score: $correctCount / $total plates correct ($percent%)\n'
        'Missed plates: $missed\n\n'
        '${_resultExplanation(correct: correctCount, total: total)}\n\n'
        '${_missedPlateSummary()}\n\n'
        'Preliminary screening only — not a diagnosis. This result does not replace a comprehensive eye examination or professional color vision assessment.';
  }

  void _showFinalResultDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Color Vision Screening Result'),
        content: SingleChildScrollView(
          child: Text(
            _finalResultText(),
            style: const TextStyle(height: 1.35, fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restartTest();
            },
            child: const Text('Restart'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _restartTest() {
    setState(() {
      index = 0;
      correctCount = 0;
      incorrectCount = 0;
      userAnswers.clear();
      _answer.clear();
    });
  }

  void onCheckPressed() {
    final ans = _answer.text.trim();

    if (ans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a number or type "Nothing".'),
        ),
      );
      return;
    }

    final expected = expectedAnswers[index];
    final isCorrect = _isAnswerCorrect(
      userAnswer: ans,
      expectedAnswer: expected,
    );

    setState(() {
      userAnswers.add(ans);

      if (isCorrect) {
        correctCount++;
      } else {
        incorrectCount++;
      }

      if (index < plates.length - 1) {
        index++;
        _answer.clear();
      } else {
        _answer.clear();
      }
    });

    if (index == plates.length - 1 && userAnswers.length == plates.length) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _showFinalResultDialog();
        }
      });
    }
  }

  // ---------- UI helpers ----------
  Widget _glassModal({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }

  Widget _instructionsDropdown() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          collapsedIconColor: Colors.black87,
          iconColor: Colors.black87,
          title: const Text(
            'Color Vision Screening Instructions',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          children: const [
            Text(
              'This is a preliminary color vision screening only and is not a medical diagnosis.\n\n'
              'Display setup:\n'
              '• Use a comfortable, bright display setting\n'
              '• Disable Night Mode / True Tone / blue-light filters\n'
              '• Avoid glare/reflections\n\n'
              'Distance + timing:\n'
              '• Sit approximately 30–50 cm (12–20 in) from the screen\n'
              '• View each plate for 3–5 seconds only\n'
              '• Answer the FIRST number you see\n\n'
              'Glasses / contacts:\n'
              '• If you wear prescription glasses daily → keep them ON\n'
              '• If you wear contact lenses → keep them ON\n'
              '• If you have separate reading vs distance glasses → use what you normally use at this screen distance\n'
              '• Remove sunglasses and tinted/blue-light glasses\n',
              style: TextStyle(
                color: Colors.black87,
                height: 1.35,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerBar() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onCheckPressed,
        icon: const Icon(Icons.check),
        label: Text(index == plates.length - 1 ? 'Finish' : 'Check'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentExpectedAnswer = expectedAnswers[index];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: _glassModal(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: _whiteCard(
                child: LayoutBuilder(
                  builder: (context, c) {
                    const double topBlock = 140;
                    const double bottomBlock = 190;
                    final double available =
                        (c.maxHeight - topBlock - bottomBlock).clamp(220, 520);

                    return SingleChildScrollView(
                      primary: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Free Online Color Vision Screening',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Use Ishihara-style plates for a preliminary online color vision screening for possible red-green color vision differences. Results can be affected by screen brightness, display color settings, calibration, lighting, and viewing conditions.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),

                          const SizedBox(height: 12),

                          _instructionsDropdown(),
                          const SizedBox(height: 10),

                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: SizedBox(
                                width: available,
                                height: available,
                                child: Image.asset(
                                  currentPlate,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Plate ${index + 1} of ${plates.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                'Completed: ${userAnswers.length} / ${plates.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          Text(
                            'What number do you see? (Type "Nothing" if none)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _answer,
                            decoration: const InputDecoration(
                              hintText: 'Example: 12  or  Nothing',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => onCheckPressed(),
                          ),

                          /*
                          Developer note:
                          This is hidden from the user UI. It only keeps the variable
                          referenced so you can easily debug expected answer mapping.
                        */
                          Offstage(
                            offstage: true,
                            child: Text('Expected: $currentExpectedAnswer'),
                          ),

                          const SizedBox(height: 12),
                          _footerBar(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
