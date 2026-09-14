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
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      );
    }

    // ================================================================
    // RESULT CLASSIFICATION
    // ================================================================

    String classification(
      vm.AcuityResult? result,
    ) {
      if (result == null) {
        return 'Not tested';
      }

      if (result.belowRange) {
        return 'Below the measurable screening range';
      }

      final d = result.denominator;

      if (d >= 320) {
        return 'Severe reduction in visual acuity';
      }

      if (d >= 200) {
        return 'Significant reduction in visual acuity';
      }

      if (d >= 125) {
        return 'Marked reduction in visual acuity';
      }

      if (d >= 80) {
        return 'Moderate reduction in visual acuity';
      }

      if (d >= 50) {
        return 'Reduced visual acuity';
      }

      if (d >= 30) {
        return 'Mild reduction in visual acuity';
      }

      if (d == 25) {
        return 'Slightly below normal 20/20 visual acuity';
      }

      if (d == 20) {
        return 'Normal 20/20 visual acuity';
      }

      if (d >= 13) {
        return 'Better than 20/20 visual acuity';
      }

      if (d >= 8) {
        return 'Very small letters reached';
      }

      return 'Extremely small letters reached';
    }

    String comparisonToStandard(
      vm.AcuityResult? result,
    ) {
      if (result == null) {
        return 'Not available';
      }

      if (result.belowRange) {
        return 'Below the range measured by this screening';
      }

      final d = result.denominator;

      if (d > 20) {
        return 'Below normal 20/20 visual acuity';
      }

      if (d == 20) {
        return 'At normal 20/20 visual acuity';
      }

      return 'Better than normal 20/20 visual acuity';
    }

    String simpleMeaning(
      vm.AcuityResult? result, {
      required String eyeName,
      required String testType,
    }) {
      if (result == null) {
        return '$eyeName was not tested.';
      }

      if (result.belowRange) {
        return '$eyeName could not read the largest line presented during '
            'this $testType screening. The result was below the measurable '
            'range of this online screening. A comprehensive eye examination '
            'should be considered.';
      }

      final d = result.denominator;

      if (d >= 320) {
        return '$eyeName required very large letters during this $testType '
            'screening. This represents a substantial reduction in visual '
            'acuity compared with normal 20/20 vision.';
      }

      if (d >= 200) {
        return '$eyeName required much larger letters than the normal 20/20 '
            'line during this $testType screening. This represents a '
            'significant reduction in visual acuity.';
      }

      if (d >= 125) {
        return '$eyeName showed a marked reduction in $testType visual '
            'acuity compared with normal 20/20 vision.';
      }

      if (d >= 80) {
        return '$eyeName showed a moderate reduction in $testType visual '
            'acuity during this screening.';
      }

      if (d >= 50) {
        return '$eyeName showed reduced $testType visual acuity compared '
            'with normal 20/20 vision.';
      }

      if (d >= 30) {
        return '$eyeName needed somewhat larger letters than the normal '
            '20/20 line. This represents a mild reduction in $testType '
            'visual acuity.';
      }

      if (d == 25) {
        return '$eyeName was slightly below normal 20/20 visual acuity '
            'during this $testType screening.';
      }

      if (d == 20) {
        return '$eyeName reached normal 20/20 visual acuity during this '
            '$testType screening.';
      }

      if (d >= 13) {
        return '$eyeName was able to read letters smaller than the normal '
            '20/20 line. This represents better-than-20/20 performance '
            'during this browser screening.';
      }

      if (d >= 8) {
        return '$eyeName was able to read very small letters beyond the '
            'normal 20/20 level. These results are sensitive to screen '
            'calibration and exact viewing distance.';
      }

      return '$eyeName reached an extremely small letter level in this '
          'browser screening. Because results this small are highly affected '
          'by physical screen size, display scaling and exact viewing '
          'distance, this should be treated as the smallest screening level '
          'reached rather than a clinically confirmed ${result.snellen} '
          'measurement.';
    }

    // ================================================================
    // EYE COMPARISON
    // ================================================================

    String compareEyes(
      vm.AcuityResult? right,
      vm.AcuityResult? left, {
      required String testType,
    }) {
      if (right == null ||
          left == null) {
        return 'A right-versus-left eye comparison is not available.';
      }

      if (right.belowRange &&
          left.belowRange) {
        return 'Both eyes were below the range measured by this $testType '
            'screening.';
      }

      if (right.belowRange) {
        return 'The RIGHT eye (OD) performed weaker than the LEFT eye (OS) '
            'in this $testType screening.';
      }

      if (left.belowRange) {
        return 'The LEFT eye (OS) performed weaker than the RIGHT eye (OD) '
            'in this $testType screening.';
      }

      final rightD =
          right.denominator;
      final leftD =
          left.denominator;

      if ((rightD - leftD)
              .abs() <=
          5) {
        return 'The RIGHT eye (OD) and LEFT eye (OS) produced similar '
            '$testType screening results.';
      }

      if (rightD >
          leftD) {
        return 'The RIGHT eye (OD) performed weaker than the LEFT eye (OS) '
            'in this $testType screening.';
      }

      return 'The LEFT eye (OS) performed weaker than the RIGHT eye (OD) '
          'in this $testType screening.';
    }

    // ================================================================
    // COLOR VISION
    // ================================================================

    final cb =
        data.colorBlindness;

    String cbText(
      String key,
    ) {
      if (cb == null) {
        return '—';
      }

      final value =
          cb[key];

      if (value == null) {
        return '—';
      }

      return value.toString();
    }

    double cbAccuracy() {
      if (cb == null) {
        return 0;
      }

      final value =
          cb['accuracy'];

      if (value is num) {
        return value.toDouble();
      }

      if (value is String) {
        return double.tryParse(
              value,
            ) ??
            0;
      }

      return 0;
    }

    final cbPct =
        (cbAccuracy() * 100)
            .round();

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
    // OVERALL IMPRESSION
    // ================================================================

    String overallImpression() {
      final parts =
          <String>[];

      if (hasDistance) {
        final r =
            data.distanceRight;
        final l =
            data.distanceLeft;
        final b =
            data.distanceBoth;

        final values = [
          if (r != null &&
              !r.belowRange)
            r.denominator,
          if (l != null &&
              !l.belowRange)
            l.denominator,
          if (b != null &&
              !b.belowRange)
            b.denominator,
        ];

        final anyBelowRange =
            (r?.belowRange ?? false) ||
                (l?.belowRange ??
                    false) ||
                (b?.belowRange ??
                    false);

        if (anyBelowRange) {
          parts.add(
            'At least one distance-vision result was below the range measured '
            'by this screening.',
          );
        } else if (values.isNotEmpty) {
          final worst =
              values.reduce(
            (a, b) =>
                a > b ? a : b,
          );

          if (worst <= 20) {
            parts.add(
              'Distance visual acuity reached normal 20/20 vision or better '
              'in the tested eyes.',
            );
          } else if (worst <=
              40) {
            parts.add(
              'Distance visual acuity showed a mild reduction compared with '
              'normal 20/20 vision in one or more tested eyes.',
            );
          } else if (worst <=
              100) {
            parts.add(
              'Distance visual acuity showed a moderate reduction compared '
              'with normal 20/20 vision in one or more tested eyes.',
            );
          } else {
            parts.add(
              'Distance visual acuity showed a significant reduction compared '
              'with normal 20/20 vision in one or more tested eyes.',
            );
          }
        }
      }

      if (hasNear) {
        final r =
            data.nearRight;
        final l =
            data.nearLeft;
        final b =
            data.nearBoth;

        final values = [
          if (r != null &&
              !r.belowRange)
            r.denominator,
          if (l != null &&
              !l.belowRange)
            l.denominator,
          if (b != null &&
              !b.belowRange)
            b.denominator,
        ];

        final anyBelowRange =
            (r?.belowRange ?? false) ||
                (l?.belowRange ??
                    false) ||
                (b?.belowRange ??
                    false);

        if (anyBelowRange) {
          parts.add(
            'At least one near-vision result was below the range measured '
            'by this screening.',
          );
        } else if (values.isNotEmpty) {
          final worst =
              values.reduce(
            (a, b) =>
                a > b ? a : b,
          );

          if (worst <= 20) {
            parts.add(
              'Near visual acuity reached the normal screening reference '
              'or better in the tested eyes.',
            );
          } else if (worst <=
              40) {
            parts.add(
              'Near visual acuity showed a mild reduction in one or more '
              'tested eyes.',
            );
          } else {
            parts.add(
              'Near visual acuity showed a noticeable reduction in one or '
              'more tested eyes.',
            );
          }
        }
      }

      if (hasColorVision) {
        parts.add(
          colorVisionSummary(),
        );
      }

      if (parts.isEmpty) {
        return 'Screening results are available below.';
      }

      return parts.join(
        '\n\n',
      );
    }

    // ================================================================
    // UI HELPERS
    // ================================================================

    Widget section(
      String title,
      Widget child,
    ) {
      return Container(
        margin:
            const EdgeInsets.only(
          bottom: 16,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            14,
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
                horizontal: 16,
                vertical: 13,
              ),
              decoration:
                  BoxDecoration(
                color: Theme.of(
                  context,
                )
                    .colorScheme
                    .primaryContainer
                    .withOpacity(
                      .35,
                    ),
                borderRadius:
                    const BorderRadius.vertical(
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
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
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

    Widget infoRow(
      String label,
      String value,
    ) {
      return Padding(
        padding:
            const EdgeInsets.only(
          bottom: 7,
        ),
        child:
            Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 170,
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

    Widget acuityCard({
      required String title,
      required vm.AcuityResult? result,
      required String testType,
    }) {
      return Container(
        width:
            double.infinity,
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.all(
          14,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(
            0xFFF7F8FB,
          ),
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          border:
              Border.all(
            color:
                const Color(
              0xFFE4E7EC,
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
                fontSize: 16,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              result?.screeningLevel ??
                  'Not tested',
              style:
                  const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.w900,
                color:
                    Color(
                  0xFF174BAE,
                ),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            infoRow(
              'Classification:',
              classification(
                result,
              ),
            ),

            infoRow(
              'Normal reference:',
              '20/20',
            ),

            infoRow(
              'Comparison:',
              comparisonToStandard(
                result,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            const Text(
              'What this means',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              simpleMeaning(
                result,
                eyeName:
                    title.contains(
                      'Right',
                    )
                        ? 'Your RIGHT eye'
                        : title.contains(
                            'Left',
                          )
                            ? 'Your LEFT eye'
                            : 'Your combined vision with BOTH eyes',
                testType:
                    testType,
              ),
              style:
                  const TextStyle(
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    // ================================================================
    // REPORT DATA
    // ================================================================

    final distanceInfo =
        data.distanceRight ??
            data.distanceLeft ??
            data.distanceBoth;

    final nearInfo =
        data.nearRight ??
            data.nearLeft ??
            data.nearBoth;

    // ================================================================
    // REPORT
    // ================================================================

    return ListView(
      padding:
          const EdgeInsets.only(
        bottom: 32,
      ),
      children: [
        section(
          'VISION SCREENING REPORT',
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Overall Screening Summary',
                style:
                    TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                overallImpression(),
                style:
                    const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                ),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                infoRow(
                  'Test method:',
                  data.distanceTestMethodLabel,
                ),

                infoRow(
                  'Response method:',
                  data.distanceResponseMethodLabel,
                ),

                infoRow(
                  'Test type:',
                  'Distance visual acuity screening',
                ),

                infoRow(
                  'Test distance:',
                  distanceInfo
                          ?.testDistanceLabel ??
                      'Approximately 10 ft / 3 m',
                ),

                infoRow(
                  'Correction:',
                  distanceInfo
                          ?.correction.label ??
                      'Not recorded',
                ),

                infoRow(
                  'Normal reference:',
                  '20/20',
                ),

                infoRow(
                  'Screening method:',
                  data.distanceTestMethod ==
                          VisionTestMethod.accessible
                      ? 'Five-letter high-contrast large-letter browser screening'
                      : 'Five-letter browser visual-acuity screening',
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                acuityCard(
                  title:
                      'Right Eye (OD)',
                  result:
                      data.distanceRight,
                  testType:
                      'distance',
                ),

                acuityCard(
                  title:
                      'Left Eye (OS)',
                  result:
                      data.distanceLeft,
                  testType:
                      'distance',
                ),

                acuityCard(
                  title:
                      'Both Eyes (OU)',
                  result:
                      data.distanceBoth,
                  testType:
                      'distance',
                ),

                const SizedBox(
                  height: 4,
                ),

                const Text(
                  'Eye-to-Eye Comparison',
                  style:
                      TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  compareEyes(
                    data.distanceRight,
                    data.distanceLeft,
                    testType:
                        'distance',
                  ),
                  style:
                      const TextStyle(
                    height: 1.45,
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                infoRow(
                  'Test method:',
                  data.nearTestMethodLabel,
                ),

                infoRow(
                  'Response method:',
                  data.nearResponseMethodLabel,
                ),

                infoRow(
                  'Test type:',
                  'Near / reading visual acuity screening',
                ),

                infoRow(
                  'Test distance:',
                  nearInfo
                          ?.testDistanceLabel ??
                      'Approximately 40 cm / 16 in',
                ),

                infoRow(
                  'Correction:',
                  nearInfo
                          ?.correction.label ??
                      'Not recorded',
                ),

                infoRow(
                  'Normal reference:',
                  '20/20',
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                acuityCard(
                  title:
                      'Right Eye (OD)',
                  result:
                      data.nearRight,
                  testType:
                      'near',
                ),

                acuityCard(
                  title:
                      'Left Eye (OS)',
                  result:
                      data.nearLeft,
                  testType:
                      'near',
                ),

                acuityCard(
                  title:
                      'Both Eyes (OU)',
                  result:
                      data.nearBoth,
                  testType:
                      'near',
                ),

                const SizedBox(
                  height: 4,
                ),

                const Text(
                  'Eye-to-Eye Comparison',
                  style:
                      TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  compareEyes(
                    data.nearRight,
                    data.nearLeft,
                    testType:
                        'near',
                  ),
                  style:
                      const TextStyle(
                    height: 1.45,
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                infoRow(
                  'Correct plates:',
                  '${cbText('correct')} of ${cbText('total')}',
                ),

                infoRow(
                  'Plate-match score:',
                  '$cbPct%',
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  colorVisionSummary(),
                  style:
                      const TextStyle(
                    height: 1.45,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  'Color vision screening can be affected by display color '
                  'settings, brightness, blue-light filters, True Tone, '
                  'Night Mode, room lighting and viewing conditions.',
                  style:
                      TextStyle(
                    color:
                        Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

        // ============================================================
        // OVERALL
        // ============================================================

        section(
          'OVERALL SCREENING IMPRESSION',
          Text(
            overallImpression(),
            style:
                const TextStyle(
              fontSize: 15,
              height: 1.45,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        // ============================================================
        // RECOMMENDATION
        // ============================================================

        section(
          'RECOMMENDATION',
          const Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                '• Results should be interpreted together with how you see '
                'in daily life.',
                style:
                    TextStyle(
                  height: 1.4,
                ),
              ),

              SizedBox(
                height: 8,
              ),

              Text(
                '• If one eye performs noticeably weaker than the other, '
                'repeat the screening under the recommended conditions.',
                style:
                    TextStyle(
                  height: 1.4,
                ),
              ),

              SizedBox(
                height: 8,
              ),

              Text(
                '• If reduced vision or an eye-to-eye difference remains, '
                'consider a comprehensive eye examination.',
                style:
                    TextStyle(
                  height: 1.4,
                ),
              ),

              SizedBox(
                height: 8,
              ),

              Text(
                '• Sudden vision loss, severe eye pain, new flashes or '
                'floaters, or an eye injury should be evaluated promptly '
                'by an eye-care professional.',
                style:
                    TextStyle(
                  height: 1.4,
                ),
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
            style:
                TextStyle(
              height: 1.45,
            ),
          ),
        ),

        const SizedBox(
          height: 4,
        ),

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
          style:
              TextStyle(
            color:
                Color(
              0xFFA85500,
            ),
            fontWeight:
                FontWeight.w700,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}