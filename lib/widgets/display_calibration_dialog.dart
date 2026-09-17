import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/display_calibration_service.dart';

Future<bool> showDisplayCalibrationDialog(
  BuildContext context,
) async {
  final result =
      await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        const DisplayCalibrationDialog(),
  );

  return result ?? false;
}

class DisplayCalibrationDialog
    extends StatefulWidget {
  const DisplayCalibrationDialog({
    super.key,
  });

  @override
  State<DisplayCalibrationDialog>
      createState() =>
          _DisplayCalibrationDialogState();
}

class _DisplayCalibrationDialogState
    extends State<DisplayCalibrationDialog> {
  // ISO/IEC 7810 bank card short side.
  static const double cardShortSideMm =
      53.98;

  double _barWidth = 200;

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.sizeOf(context).width;

    final maxWidth = math
        .min(
          screenWidth - 80,
          420.0,
        )
        .toDouble();

    final safeMax =
        math.max(
          120.0,
          maxWidth,
        ).toDouble();

    if (_barWidth > safeMax) {
      _barWidth = safeMax;
    }

    return AlertDialog(
      title: const Text(
        'Screen Calibration',
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'For more consistent letter sizing, '
              'calibrate this screen before the vision test.',
            ),

            const SizedBox(height: 16),

            const Text(
              'Place the SHORT side of a standard '
              'credit/debit card against the blue bar below.',
              style: TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Move the slider until the blue bar is exactly '
              'the same physical width as the short side of your card.',
            ),

            const SizedBox(height: 24),

            Center(
              child: Container(
                width: _barWidth,
                height: 20,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.blue,
                  borderRadius:
                      BorderRadius.circular(
                    4,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Slider(
              min: 80,
              max: safeMax,
              value: _barWidth.clamp(
                80,
                safeMax,
              ),
              onChanged: (value) {
                setState(() {
                  _barWidth =
                      value;
                });
              },
            ),

            const SizedBox(height: 8),

            const Text(
              'Calibration affects visual-acuity sizing only. '
              'Browser zoom should remain at its normal setting '
              'while taking the test.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
              false,
            );
          },
          child: const Text(
            'Cancel',
          ),
        ),

        FilledButton(
          onPressed: () {
            DisplayCalibrationService
                .instance
                .calibrate(
              logicalPixels:
                  _barWidth,
              physicalMillimeters:
                  cardShortSideMm,
            );

            Navigator.pop(
              context,
              true,
            );
          },
          child: const Text(
            'Save Calibration',
          ),
        ),
      ],
    );
  }
}