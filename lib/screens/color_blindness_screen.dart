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

  int index = 0;
  final TextEditingController _answer = TextEditingController();

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  String get currentPlate => plates[index];

  void onCheckPressed() {
    final ans = _answer.text.trim();

    // ✅ Don’t allow next if empty
    if (ans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a number or type "Nothing".'),
        ),
      );
      return;
    }

    setState(() {
      if (index < plates.length - 1) {
        index++;
        _answer.clear();
      } else {
        // ✅ TODO: show final report dialog here
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Color Screening Result'),
            content: const Text(
              'Screening only — not a diagnosis.\n\n'
              'If you had difficulty seeing multiple plates, consider an eye exam with an optometrist or ophthalmologist.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  void onShowHintPressed() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hint'),
        content: const Text(
          'Look for the number formed by dots with slightly different color/brightness.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
            'Instructions (tap to expand)',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          children: const [
            Text(
              'Screening only — not a diagnosis.\n\n'
              'Display setup:\n'
              '• Brightness 80–100%\n'
              '• Disable Night Mode / True Tone / blue-light filters\n'
              '• Avoid glare/reflections\n\n'
              'Distance + timing:\n'
              '• Sit 30–50 cm (12–20 in) from the screen\n'
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
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onCheckPressed,
            icon: const Icon(Icons.check),
            label: const Text('Check'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onShowHintPressed,
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Show hint'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    // ✅ Reserve space for top + bottom so image always fits
                    const double topBlock = 140; // title + dropdown area
                    const double bottomBlock =
                        170; // plate info + input + buttons
                    final double available =
                        (c.maxHeight - topBlock - bottomBlock).clamp(220, 520);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Center(
                          child: Text(
                            'Color Vision Test — Ishihara',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Dropdown stays at top (doesn't force scroll)
                        _instructionsDropdown(),
                        const SizedBox(height: 10),

                        // ✅ Image always visible (auto-sized)
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

                        // Plate counter
                        Text(
                          'Plate ${index + 1} of ${plates.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Question + input
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
                        ),
                        const SizedBox(height: 12),

                        // Buttons always visible
                        _footerBar(),
                      ],
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
