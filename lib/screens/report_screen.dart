// lib/screens/report_screen.dart
import 'package:flutter/material.dart';
import '../services/report_service.dart';

class ReportBody extends StatelessWidget {
  const ReportBody({super.key});

  @override
  Widget build(BuildContext context) {
    final data = ReportService.instance.current;

    final hasDistance =
        data.distanceRight != null ||
        data.distanceLeft != null ||
        data.distanceBoth != null;

    final hasNear =
        data.nearRight != null ||
        data.nearLeft != null ||
        data.nearBoth != null;

    final cb = data.colorBlindness;
    final hasColorVision = cb != null;

    final hasAnyReport = hasDistance || hasNear || hasColorVision;

    if (!hasAnyReport) {
      return const Center(
        child: Text(
          'No report yet. Run a vision test to generate your report.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    String show(dynamic v) => v == null ? 'Not tested' : v.toString();

    Widget block(String title, Widget child) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(.35),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: child,
            ),
          ],
        ),
      );
    }

    Widget eyeResult({
      required String title,
      required String value,
      required String meaning,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Screening estimate: $value',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(meaning, style: const TextStyle(height: 1.35)),
            ],
          ),
        ),
      );
    }

    String meaningForEye(dynamic v) {
      if (v == null) {
        return 'This eye was not tested.';
      }

      final text = v.toString();

      if (text.contains('20/20') ||
          text.contains('20/16') ||
          text.contains('20/12') ||
          text.contains('20/10') ||
          text.contains('20/8') ||
          text.contains('20/6') ||
          text.contains('20/5') ||
          text.contains('20/4') ||
          text.contains('20/3')) {
        return 'This screening result suggests relatively good visual acuity under the test conditions.';
      }

      if (text.contains('20/25') ||
          text.contains('20/30') ||
          text.contains('20/32') ||
          text.contains('20/40')) {
        return 'This screening result may indicate some difficulty seeing clearly. Consider repeating the test under recommended conditions.';
      }

      return 'This screening result may indicate greater difficulty seeing clearly. If the result repeats or you have concerns, consider a comprehensive eye examination.';
    }

    String bothEyesMeaning(dynamic both, dynamic right, dynamic left) {
      if (both == null) {
        return 'Both eyes together were not tested.';
      }

      return 'This shows how well you see when both eyes are open together. This is often how you see in daily life.';
    }

    String cbText(String key) {
      if (cb == null) return '—';
      final v = cb[key];
      if (v == null) return '—';
      return v.toString();
    }

    double cbAccuracy() {
      if (cb == null) return 0.0;
      final v = cb['accuracy'];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    final cbAccPct = (cbAccuracy() * 100).toStringAsFixed(0);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        block(
          'Vision Screening Summary',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.ageAdjustedVerdict ??
                    'Your vision screening result has been generated.',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              if (data.ageGroupLabel != null)
                Text('Age group: ${data.ageGroupLabel}'),
              const SizedBox(height: 8),
              Text(
                data.warning ??
                    'This screening did not identify an obvious concern based on the available results.',
                style: const TextStyle(height: 1.35),
              ),
            ],
          ),
        ),

        if (hasDistance)
          block(
            'Distance Vision Result',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This checks how clearly you see things far away.',
                  style: TextStyle(height: 1.35),
                ),
                const SizedBox(height: 12),
                eyeResult(
                  title: 'Right Eye',
                  value: show(data.distanceRight),
                  meaning: meaningForEye(data.distanceRight),
                ),
                eyeResult(
                  title: 'Left Eye',
                  value: show(data.distanceLeft),
                  meaning: meaningForEye(data.distanceLeft),
                ),
                eyeResult(
                  title: 'Both Eyes Together',
                  value: show(data.distanceBoth),
                  meaning: bothEyesMeaning(
                    data.distanceBoth,
                    data.distanceRight,
                    data.distanceLeft,
                  ),
                ),
              ],
            ),
          ),

        if (hasNear)
          block(
            'Near / Reading Vision Result',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This checks how clearly you see things up close, like reading on a phone or book.',
                  style: TextStyle(height: 1.35),
                ),
                const SizedBox(height: 12),
                eyeResult(
                  title: 'Right Eye',
                  value: show(data.nearRight),
                  meaning: meaningForEye(data.nearRight),
                ),
                eyeResult(
                  title: 'Left Eye',
                  value: show(data.nearLeft),
                  meaning: meaningForEye(data.nearLeft),
                ),
                eyeResult(
                  title: 'Both Eyes Together',
                  value: show(data.nearBoth),
                  meaning: bothEyesMeaning(
                    data.nearBoth,
                    data.nearRight,
                    data.nearLeft,
                  ),
                ),
              ],
            ),
          ),

        block(
          'What This Means',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.refractiveHint ??
                    'Your result gives a simple screening estimate only.',
                style: const TextStyle(height: 1.35),
              ),
              const SizedBox(height: 10),
              const Text(
                'If one eye is much weaker than the other, or if the result does not match how you feel you see in daily life, repeat the test once in good lighting. If the same result appears again, consider a professional eye exam.',
                style: TextStyle(height: 1.35),
              ),
            ],
          ),
        ),

        if (hasColorVision)
          block(
            'Color Vision Result',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Screening result: ${cbText('diagnosis')}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score: ${cbText('correct')} out of ${cbText('total')} plates',
                ),
                const SizedBox(height: 6),
                Text('Plate-match score: $cbAccPct%'),
                const SizedBox(height: 10),
                const Text(
                  'This preliminary screening checks for possible red-green color vision differences. Results can be affected by display settings, brightness, lighting, and viewing conditions. It is not a diagnosis.',
                  style: TextStyle(height: 1.35),
                ),
              ],
            ),
          ),

        block(
          'Recommendation',
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• Repeat the test if lighting, screen distance, or screen brightness was not ideal.',
                style: TextStyle(height: 1.4),
              ),
              SizedBox(height: 4),
              Text(
                '• If one eye repeatedly performs worse than the other, consider an eye exam.',
                style: TextStyle(height: 1.4),
              ),
              SizedBox(height: 4),
              Text(
                '• If you have eye pain, sudden vision changes, injury, flashes, floaters, or severe symptoms, seek professional care promptly.',
                style: TextStyle(height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        const Text(
          'Important: PeekVision provides preliminary vision screening only. Results are not a diagnosis or prescription and do not replace a comprehensive eye examination by a qualified eye-care professional.',
          style: TextStyle(
            color: Color(0xFFA85500),
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
