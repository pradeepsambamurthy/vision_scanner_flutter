import 'dart:math' as math;
import 'package:flutter/material.dart';

class ColorBlindnessScreen extends StatefulWidget {
  const ColorBlindnessScreen({super.key});

  @override
  State<ColorBlindnessScreen> createState() => _ColorBlindnessScreenState();
}

class _ColorBlindnessScreenState extends State<ColorBlindnessScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color Blindness Screening',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Screening only — not a diagnosis. For best results, use maximum brightness and avoid night-mode / blue-light filters.',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
          child: TabBar(
            controller: _tab,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.black.withOpacity(0.08),
            ),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            tabs: const [
              Tab(text: 'Ishihara'),
              Tab(text: 'Red/Green'),
              Tab(text: 'Blue/Yellow'),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              _IshiharaSimple(),
              _AdjustToMatch(
                title: 'Red/Green Match',
                mode: _MatchMode.redGreen,
              ),
              _AdjustToMatch(
                title: 'Blue/Yellow Match',
                mode: _MatchMode.blueYellow,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// -------------------------
/// 1) Simple Ishihara-like plate (generated dots)
/// -------------------------
class _IshiharaSimple extends StatefulWidget {
  const _IshiharaSimple();

  @override
  State<_IshiharaSimple> createState() => _IshiharaSimpleState();
}

class _IshiharaSimpleState extends State<_IshiharaSimple> {
  final _answerCtrl = TextEditingController();
  bool _showHint = false;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: CustomPaint(
                painter: _DotPlatePainter(),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Question: What number do you see?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _answerCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter number (e.g., 12)',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            FilledButton(
              onPressed: () {
                final v = _answerCtrl.text.trim();
                // This generated plate encodes "12"
                final ok = v == '12';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Looks good ✅'
                          : 'Not matching. If you see nothing / different number, it may indicate color-vision deficiency.',
                    ),
                  ),
                );
              },
              child: const Text('Check'),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () => setState(() => _showHint = !_showHint),
              child: Text(_showHint ? 'Hide hint' : 'Show hint'),
            ),
          ],
        ),
        if (_showHint)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Hint: The intended number is 12 (screening demo). For clinical-quality Ishihara, use validated plates.',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _DotPlatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(12);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.48;

    // Dots background colors (Ishihara-ish palette)
    Color bg1() => const Color(0xFFB96D4A); // warm brown
    Color bg2() => const Color(0xFF9C5E3F);
    Color fg1() => const Color(0xFF58A85A); // green-ish
    Color fg2() => const Color(0xFF4F9E59);

    bool insideCircle(Offset p) => (p - center).distance <= radius;

    // Define a rough "12" mask using normalized coordinates
    bool inTwelveMask(Offset p) {
      final dx = (p.dx - center.dx) / radius; // -1..1
      final dy = (p.dy - center.dy) / radius; // -1..1

      // "1" = thin vertical bar on left
      final one = (dx > -0.55 && dx < -0.42 && dy > -0.55 && dy < 0.55);

      // "2" = top curve + diagonal + bottom bar on right
      final top = (dx > -0.05 && dx < 0.55 && dy > -0.55 && dy < -0.35);
      final diag =
          (dx + dy > 0.05 &&
          dx + dy < 0.22 &&
          dx > 0.05 &&
          dy > -0.35 &&
          dy < 0.25);
      final bot = (dx > -0.05 && dx < 0.55 && dy > 0.35 && dy < 0.55);

      return one || top || diag || bot;
    }

    // Draw lots of dots
    final dotCount = 1800;
    for (int i = 0; i < dotCount; i++) {
      final r = radius * math.sqrt(rnd.nextDouble());
      final t = rnd.nextDouble() * math.pi * 2;
      final p = center + Offset(r * math.cos(t), r * math.sin(t));
      if (!insideCircle(p)) continue;

      final dotR = 2.0 + rnd.nextDouble() * 4.0;
      final isFg = inTwelveMask(p);

      final paint = Paint()
        ..color = isFg
            ? (rnd.nextBool() ? fg1() : fg2())
            : (rnd.nextBool() ? bg1() : bg2());
      canvas.drawCircle(p, dotR, paint);
    }

    // Soft border
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black.withOpacity(0.08);
    canvas.drawCircle(center, radius, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// -------------------------
/// 2) Slider-based “match” tests
/// -------------------------
enum _MatchMode { redGreen, blueYellow }

class _AdjustToMatch extends StatefulWidget {
  const _AdjustToMatch({required this.title, required this.mode});
  final String title;
  final _MatchMode mode;

  @override
  State<_AdjustToMatch> createState() => _AdjustToMatchState();
}

class _AdjustToMatchState extends State<_AdjustToMatch> {
  double _value = 0.5;

  @override
  Widget build(BuildContext context) {
    Color left;
    Color right;

    if (widget.mode == _MatchMode.redGreen) {
      // left: fixed gray, right: red-green mix
      left = const Color(0xFF9E9E9E);
      final r = (255 * _value).round();
      final g = (255 * (1 - _value)).round();
      right = Color.fromARGB(255, r, g, 60);
    } else {
      // blue-yellow mix
      left = const Color(0xFF9E9E9E);
      final b = (255 * _value).round();
      final y = (255 * (1 - _value)).round();
      right = Color.fromARGB(255, y, y, b);
    }

    return ListView(
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Move the slider until the right square looks as close as possible to the left gray square.',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _Swatch(label: 'Reference', color: left),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Swatch(label: 'Adjust', color: right),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Slider(value: _value, onChanged: (v) => setState(() => _value = v)),

        const SizedBox(height: 6),

        FilledButton(
          onPressed: () {
            // Simple heuristic: if user ends at extremes, might be struggling
            final extreme = (_value < 0.12) || (_value > 0.88);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  extreme
                      ? 'You ended near an extreme. If matching felt hard, consider a professional color vision test.'
                      : 'Saved ✅ (Screening demo)',
                ),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1.6,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.10)),
            ),
          ),
        ),
      ],
    );
  }
}
