// lib/screens/report_screen.dart

import 'package:flutter/material.dart';

import '../models/vision_models.dart' as vm;
import '../services/report_service.dart';

class ReportBody extends StatelessWidget {
  const ReportBody({super.key});

  @override
  Widget build(BuildContext context) {
    final data = ReportService.instance.current;

    final hasDistance = data.hasDistance;
    final hasNear = data.hasNear;
    final hasColorVision = data.hasColorVision;

    if (!data.hasAnyReport) {
      return const Center(
        child: Text(
          'No screening report yet.\n\n'
          'Complete a vision or color vision screening to see your report.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
        ),
      );
    }

    // ================================================================
    // RESULT HELPERS
    // ================================================================

    String screeningComparison(vm.AcuityResult? result) {
      if (result == null) {
        return 'Not available';
      }

      if (result.belowRange) {
        return 'Below the range measured by this screening';
      }

      final d = result.denominator;

      if (d > 20) {
        return 'Below the standard 20/20 reference level';
      }

      if (d == 20) {
        return 'At the standard 20/20 reference level';
      }

      return 'Smaller letters than the standard 20/20 level were readable';
    }

    String classification(vm.AcuityResult? result) {
      if (result == null) {
        return 'Not tested';
      }

      if (result.belowRange) {
        return 'Largest line was difficult to read';
      }

      final d = result.denominator;

      if (d >= 50) {
        return 'Reduced visual acuity in this screening';
      }

      if (d == 40) {
        return 'Some reduction compared with 20/20';
      }

      if (d == 32) {
        return 'Fairly close to the 20/20 reference';
      }

      if (d == 25) {
        return 'Close to the 20/20 reference';
      }

      if (d == 20) {
        return 'Reached the standard 20/20 reference level';
      }

      if (d >= 13) {
        return 'Smaller-than-20/20 letters were readable';
      }

      return 'Very small letters were readable';
    }

    String resultMeaning(
      vm.AcuityResult? result, {
      required String eyeName,
      required String testType,
    }) {
      if (result == null) {
        return '$eyeName was not tested.';
      }

      if (result.belowRange) {
        return '$eyeName had difficulty reading even the largest line used '
            'in this $testType screening. Repeat the test under the recommended '
            'conditions. If you get a similar result again, consider a '
            'professional eye examination.';
      }

      final d = result.denominator;
      final level = result.screeningLevel;

      if (d >= 50) {
        return '$eyeName could read letters at the $level level, but smaller '
            'letters became difficult. The standard reference level is 20/20. '
            'Because the screening stopped before 20/20, your $testType vision '
            'appeared reduced under these test conditions.';
      }

      if (d == 40) {
        return '$eyeName could read the 20/40 line but had difficulty with '
            'smaller letters. This is somewhat below the standard 20/20 '
            'reference level under these screening conditions.';
      }

      if (d == 32) {
        return '$eyeName reached the 20/32 level. This is fairly close to the '
            'standard 20/20 reference, although smaller letters were still '
            'difficult to read.';
      }

      if (d == 25) {
        return '$eyeName reached the 20/25 level. This is close to the standard '
            '20/20 reference, with only slight difficulty at smaller letter '
            'sizes.';
      }

      if (d == 20) {
        return '$eyeName reached the standard 20/20 reference level. '
            'The next smaller letters became difficult. 20/20 is a standard '
            'reference level and does not mean that it is the smallest possible '
            'line a person can read.';
      }

      if (d == 16) {
        return '$eyeName was able to read letters smaller than the standard '
            '20/20 reference level. This suggests strong visual acuity under '
            'the current screening conditions.';
      }

      if (d == 13) {
        return '$eyeName was able to read noticeably smaller letters than the '
            'standard 20/20 reference level. This suggests very good visual '
            'acuity under the current screening conditions.';
      }

      if (d == 10) {
        return '$eyeName was able to read very small letters beyond the '
            'standard 20/20 reference level. This represents strong screening '
            'performance, although results at this size are more sensitive to '
            'screen size, scaling and viewing distance.';
      }

      if (d == 8) {
        return '$eyeName reached a very small letter level during this browser '
            'screening. Because results this small depend strongly on physical '
            'screen size, display scaling and viewing distance, this should be '
            'treated as the smallest screening level reached rather than a '
            'clinically confirmed measurement.';
      }

      if (d == 6) {
        return '$eyeName reached an extremely small letter level. This is well '
            'beyond the standard 20/20 reference, but browser calibration can '
            'strongly affect results at this size.';
      }

      if (d == 5) {
        return '$eyeName reached an extremely small letter level during this '
            'screening. Interpret this cautiously because physical screen size '
            'and exact viewing distance have a large effect at this level.';
      }

      if (d <= 4) {
        return '$eyeName reached the smallest letter level currently presented '
            'by PeekVision. This shows very strong performance under the test '
            'conditions, but it should not be interpreted as a clinically '
            'confirmed $level measurement without proper display calibration.';
      }

      return '$eyeName reached the $level screening level.';
    }

    // ================================================================
    // CORRECTION-SPECIFIC GUIDANCE
    // ================================================================

    bool isUsingCorrection(vm.AcuityResult? result) {
      if (result == null) {
        return false;
      }

      return result.correction != vm.VisionCorrection.none;
    }

    bool isBelowTwentyTwenty(vm.AcuityResult? result) {
      if (result == null) {
        return false;
      }

      if (result.belowRange) {
        return true;
      }

      return result.denominator > 20;
    }

    String correctionGuidance(vm.AcuityResult? result) {
      if (result == null) {
        return '';
      }

      if (!isBelowTwentyTwenty(result)) {
        return 'No obvious reduction in visual acuity was seen at the standard '
            '20/20 reference level under these screening conditions. This '
            'screening does not replace a comprehensive eye examination.';
      }

      if (isUsingCorrection(result)) {
        return 'You completed this screening while using your usual vision '
            'correction. Because the result was below the standard 20/20 '
            'reference level, an eye examination can check whether your current '
            'glasses or contact lens prescription may need to be updated. '
            'Other causes of reduced vision are also possible.';
      }

      return 'You completed this screening without glasses or contact lenses. '
          'A refractive error may be one possible reason for reduced vision. '
          'A professional eye examination and refraction can determine whether '
          'glasses or contact lenses could improve your vision.';
    }

    // ================================================================
    // EYE COMPARISON
    // ================================================================

    String compareEyes(
      vm.AcuityResult? right,
      vm.AcuityResult? left, {
      required String testType,
    }) {
      if (right == null || left == null) {
        return 'A right-versus-left eye comparison is not available.';
      }

      if (right.belowRange && left.belowRange) {
        return 'Both eyes had difficulty with the largest line used in this '
            '$testType screening.';
      }

      if (right.belowRange) {
        return 'The RIGHT eye (OD) performed weaker than the LEFT eye (OS) '
            'during this $testType screening.';
      }

      if (left.belowRange) {
        return 'The LEFT eye (OS) performed weaker than the RIGHT eye (OD) '
            'during this $testType screening.';
      }

      final rightD = right.denominator;
      final leftD = left.denominator;

      if ((rightD - leftD).abs() <= 5) {
        return 'The RIGHT eye (OD) and LEFT eye (OS) produced similar '
            '$testType screening results.';
      }

      if (rightD > leftD) {
        return 'The RIGHT eye (OD) performed weaker than the LEFT eye (OS) '
            'during this $testType screening.';
      }

      return 'The LEFT eye (OS) performed weaker than the RIGHT eye (OD) '
          'during this $testType screening.';
    }

    // ================================================================
    // CONCLUSION FOR A TEST
    // ================================================================

    String testConclusion(
      vm.AcuityResult? right,
      vm.AcuityResult? left,
      vm.AcuityResult? both, {
      required String testType,
    }) {
      final results = [
        if (right != null) right,
        if (left != null) left,
        if (both != null) both,
      ];

      if (results.isEmpty) {
        return 'No $testType visual acuity result is available.';
      }

      if (results.any((r) => r.belowRange)) {
        return 'At least one eye had difficulty reading the largest line used '
            'in the $testType screening. Repeat the screening under the '
            'recommended conditions. If you get a similar result again, '
            'consider a professional eye examination.';
      }

      final worst = results.reduce(
        (a, b) => a.denominator > b.denominator ? a : b,
      );

      final d = worst.denominator;

      if (d >= 50) {
        return 'Your $testType screening showed that at least one tested eye '
            'could read its recorded line but had difficulty with smaller '
            'letters before reaching the standard 20/20 reference level. '
            'This suggests reduced $testType visual acuity under the test '
            'conditions.';
      }

      if (d == 40) {
        return 'Your $testType screening was somewhat below the standard '
            '20/20 reference level in at least one tested eye. If this result '
            'is repeatable, consider a professional eye examination.';
      }

      if (d == 32) {
        return 'Your $testType screening was fairly close to the standard '
            '20/20 reference level, although at least one eye had difficulty '
            'with smaller letters.';
      }

      if (d == 25) {
        return 'Your $testType screening was close to the standard 20/20 '
            'reference level, with only slight difficulty at smaller letter '
            'sizes.';
      }

      if (d == 20) {
        return 'Your $testType vision reached the standard 20/20 reference '
            'level under the screening conditions. Remember that 20/20 is a '
            'reference level, not the smallest possible line a person can read.';
      }

      if (d >= 13) {
        return 'Your $testType screening showed that letters smaller than the '
            'standard 20/20 reference level were readable under the current '
            'test conditions.';
      }

      return 'Your $testType screening reached very small letter sizes beyond '
          'the standard 20/20 reference level. Results at these sizes should '
          'be interpreted cautiously because screen calibration and viewing '
          'distance can significantly affect them.';
    }

    // ================================================================
    // COLOR VISION
    // ================================================================

    final cb = data.colorBlindness;

    String cbText(String key) {
      if (cb == null) {
        return '—';
      }

      final value = cb[key];

      if (value == null) {
        return '—';
      }

      return value.toString();
    }

    double cbAccuracy() {
      if (cb == null) {
        return 0;
      }

      final value = cb['accuracy'];

      if (value is num) {
        return value.toDouble();
      }

      if (value is String) {
        return double.tryParse(value) ?? 0;
      }

      return 0;
    }

    final cbPct = (cbAccuracy() * 100).round();

    String colorVisionSummary() {
      if (!hasColorVision) {
        return 'Color vision screening was not completed.';
      }

      if (cbPct >= 90) {
        return 'Most responses matched the expected plate answers. '
            'No obvious red-green color vision difference was identified '
            'by this preliminary screening.';
      }

      if (cbPct >= 70) {
        return 'Some responses differed from the expected plate answers. '
            'Screen brightness, color settings, lighting and viewing '
            'conditions can affect the result.';
      }

      return 'Several responses differed from the expected plate answers. '
          'This does not diagnose a color vision condition. Professional '
          'color vision testing may be appropriate if there are concerns.';
    }

    // ================================================================
    // OVERALL CONCLUSION
    // ================================================================

    String overallImpression() {
      final parts = <String>[];

      if (hasDistance) {
        parts.add(
          testConclusion(
            data.distanceRight,
            data.distanceLeft,
            data.distanceBoth,
            testType: 'distance',
          ),
        );
      }

      if (hasNear) {
        parts.add(
          testConclusion(
            data.nearRight,
            data.nearLeft,
            data.nearBoth,
            testType: 'near',
          ),
        );
      }

      if (hasColorVision) {
        parts.add(colorVisionSummary());
      }

      if (parts.isEmpty) {
        return 'Screening results are available below.';
      }

      return parts.join('\n\n');
    }

    // ================================================================
    // UI HELPERS
    // ================================================================

    Widget section(String title, Widget child) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(.35),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ),
      );
    }

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
        padding: const EdgeInsets.only(bottom: 7),
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

    Widget acuityCard({
      required String title,
      required vm.AcuityResult? result,
      required String testType,
    }) {
      final eyeName = title.contains('Right')
          ? 'Your RIGHT eye'
          : title.contains('Left')
          ? 'Your LEFT eye'
          : 'With BOTH eyes open';

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 10),

            Text(
              result?.screeningLevel ?? 'Not tested',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF174BAE),
              ),
            ),

            const SizedBox(height: 10),

            infoRow('Screening level:', result?.screeningLevel ?? 'Not tested'),

            infoRow('Standard reference:', '20/20'),

            infoRow('How this compares:', screeningComparison(result)),

            infoRow('Summary:', classification(result)),

            const SizedBox(height: 8),

            const Text(
              'What this means',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 5),

            Text(
              resultMeaning(result, eyeName: eyeName, testType: testType),
              style: const TextStyle(height: 1.45),
            ),

            if (result != null) ...[
              const SizedBox(height: 14),

              const Text(
                'About glasses or contacts',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 5),

              Text(
                correctionGuidance(result),
                style: const TextStyle(height: 1.45),
              ),
            ],
          ],
        ),
      );
    }

    // ================================================================
    // REPORT DATA
    // ================================================================

    final distanceInfo =
        data.distanceRight ?? data.distanceLeft ?? data.distanceBoth;

    final nearInfo = data.nearRight ?? data.nearLeft ?? data.nearBoth;

    // ================================================================
    // REPORT
    // ================================================================

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        section(
          'VISION SCREENING REPORT',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overall Screening Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 8),

              Text(
                overallImpression(),
                style: const TextStyle(fontSize: 15, height: 1.45),
              ),

              const SizedBox(height: 14),

              const Text(
                'How your result is determined',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 6),

              const Text(
                'The screening starts with larger letters and moves to '
                'progressively smaller letters. Your recorded screening level '
                'represents the smallest line you were able to read before the '
                'next smaller line became difficult. The standard 20/20 level '
                'is used as a reference; it is not the smallest possible line '
                'that a person can read.',
                style: TextStyle(height: 1.45),
              ),
            ],
          ),
        ),

        // ============================================================
        // DISTANCE TEST INFORMATION
        // ============================================================
        if (hasDistance)
          section(
            'TEST INFORMATION — DISTANCE VISION',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoRow('Test method:', data.distanceTestMethodLabel),

                infoRow('Response method:', data.distanceResponseMethodLabel),

                infoRow('Test type:', 'Distance visual acuity screening'),

                infoRow(
                  'Test distance:',
                  distanceInfo?.testDistanceLabel ??
                      'Approximately 10 ft / 3 m',
                ),

                infoRow(
                  'Correction:',
                  distanceInfo?.correction.label ?? 'Not recorded',
                ),

                infoRow('Standard reference:', '20/20'),

                const SizedBox(height: 8),

                const Text(
                  'The test progresses from larger to smaller letters. '
                  'The result shown for each eye is the smallest line '
                  'successfully read during this screening.',
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
              ],
            ),
          ),

        // ============================================================
        // DISTANCE RESULTS
        // ============================================================
        if (hasDistance)
          section(
            'DISTANCE VISUAL ACUITY',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                acuityCard(
                  title: 'Right Eye (OD)',
                  result: data.distanceRight,
                  testType: 'distance',
                ),

                acuityCard(
                  title: 'Left Eye (OS)',
                  result: data.distanceLeft,
                  testType: 'distance',
                ),

                acuityCard(
                  title: 'Both Eyes (OU)',
                  result: data.distanceBoth,
                  testType: 'distance',
                ),

                const SizedBox(height: 4),

                const Text(
                  'Eye-to-Eye Comparison',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 8),

                Text(
                  compareEyes(
                    data.distanceRight,
                    data.distanceLeft,
                    testType: 'distance',
                  ),
                  style: const TextStyle(height: 1.45),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Distance Vision Conclusion',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 8),

                Text(
                  testConclusion(
                    data.distanceRight,
                    data.distanceLeft,
                    data.distanceBoth,
                    testType: 'distance',
                  ),
                  style: const TextStyle(
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // ============================================================
        // NEAR TEST INFORMATION
        // ============================================================
        if (hasNear)
          section(
            'TEST INFORMATION — NEAR VISION',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoRow('Test method:', data.nearTestMethodLabel),

                infoRow('Response method:', data.nearResponseMethodLabel),

                infoRow('Test type:', 'Near / reading visual acuity screening'),

                infoRow(
                  'Test distance:',
                  nearInfo?.testDistanceLabel ?? 'Approximately 40 cm / 16 in',
                ),

                infoRow(
                  'Correction:',
                  nearInfo?.correction.label ?? 'Not recorded',
                ),

                infoRow('Standard reference:', '20/20'),

                const SizedBox(height: 8),

                const Text(
                  'The test progresses from larger to smaller letters. '
                  'The result shown for each eye is the smallest line '
                  'successfully read during this screening.',
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
              ],
            ),
          ),

        // ============================================================
        // NEAR RESULTS
        // ============================================================
        if (hasNear)
          section(
            'NEAR / READING VISUAL ACUITY',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                acuityCard(
                  title: 'Right Eye (OD)',
                  result: data.nearRight,
                  testType: 'near',
                ),

                acuityCard(
                  title: 'Left Eye (OS)',
                  result: data.nearLeft,
                  testType: 'near',
                ),

                acuityCard(
                  title: 'Both Eyes (OU)',
                  result: data.nearBoth,
                  testType: 'near',
                ),

                const SizedBox(height: 4),

                const Text(
                  'Eye-to-Eye Comparison',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 8),

                Text(
                  compareEyes(data.nearRight, data.nearLeft, testType: 'near'),
                  style: const TextStyle(height: 1.45),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Near Vision Conclusion',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 8),

                Text(
                  testConclusion(
                    data.nearRight,
                    data.nearLeft,
                    data.nearBoth,
                    testType: 'near',
                  ),
                  style: const TextStyle(
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // ============================================================
        // COLOR VISION
        // ============================================================
        if (hasColorVision)
          section(
            'COLOR VISION SCREENING',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoRow(
                  'Correct plates:',
                  '${cbText('correct')} of ${cbText('total')}',
                ),

                infoRow('Plate-match score:', '$cbPct%'),

                const SizedBox(height: 8),

                Text(
                  colorVisionSummary(),
                  style: const TextStyle(height: 1.45),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Color vision screening can be affected by display color '
                  'settings, brightness, blue-light filters, True Tone, '
                  'Night Mode, room lighting and viewing conditions.',
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
              ],
            ),
          ),

        // ============================================================
        // OVERALL CONCLUSION
        // ============================================================
        section(
          'OVERALL SCREENING CONCLUSION',
          Text(
            overallImpression(),
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ============================================================
        // RECOMMENDATION
        // ============================================================
        section(
          'WHAT SHOULD I DO NEXT?',
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• If your result is below the standard 20/20 reference, '
                'repeat the screening under the recommended conditions.',
                style: TextStyle(height: 1.4),
              ),

              SizedBox(height: 8),

              Text(
                '• If you receive a similar result again, consider a '
                'professional eye examination.',
                style: TextStyle(height: 1.4),
              ),

              SizedBox(height: 8),

              Text(
                '• If you do not currently wear glasses or contacts, an eye '
                'exam can determine whether vision correction may help.',
                style: TextStyle(height: 1.4),
              ),

              SizedBox(height: 8),

              Text(
                '• If you already wear glasses or contacts and your vision '
                'remains below the reference level, an eye-care professional '
                'can check whether your prescription needs to be updated.',
                style: TextStyle(height: 1.4),
              ),

              SizedBox(height: 8),

              Text(
                '• If one eye performs noticeably weaker than the other, '
                'repeat the screening. If the difference remains, consider '
                'a professional eye examination.',
                style: TextStyle(height: 1.4),
              ),

              SizedBox(height: 8),

              Text(
                '• Sudden vision loss, severe eye pain, new flashes or '
                'floaters, or an eye injury should be evaluated promptly '
                'by an eye-care professional.',
                style: TextStyle(height: 1.4),
              ),
            ],
          ),
        ),

        // ============================================================
        // LIMITATIONS
        // ============================================================
        section(
          'WHAT THIS SCREENING DOES NOT MEASURE',
          const Text(
            'PeekVision does not measure eyeglass prescription strength '
            '(sphere, cylinder or axis), intraocular pressure, cornea, '
            'retina, macula, lens, optic nerve health, pupil reactions or '
            'other findings assessed during a comprehensive professional '
            'eye examination.',
            style: TextStyle(height: 1.45),
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'Important: PeekVision provides preliminary browser-based vision '
          'screening only. Results are not a diagnosis or prescription and '
          'do not replace a comprehensive eye examination. Physical screen '
          'size, display scaling, viewing distance, lighting, device '
          'settings, speech recognition and user responses can affect the '
          'results. Very small acuity levels such as 20/10, 20/8, 20/6, '
          '20/5 and 20/4 represent the smallest screening level reached and '
          'should not be considered clinically confirmed measurements '
          'without proper display calibration.',
          style: TextStyle(
            color: Color(0xFFA85500),
            fontWeight: FontWeight.w700,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
