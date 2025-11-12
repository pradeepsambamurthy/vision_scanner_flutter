// lib/screens/report_screen.dart
import 'package:flutter/material.dart';
import '../services/report_service.dart';

/// Content-only body to render inside the Report tab.
/// Pulls values from ReportService.instance.current.
class ReportBody extends StatelessWidget {
  const ReportBody({super.key});

  @override
  Widget build(BuildContext context) {
    final data = ReportService.instance.current;

    final hasDistance = data.distanceRight != null || data.distanceLeft != null;
    final hasNear = data.nearRight != null || data.nearLeft != null;
    final hasAny = hasDistance || hasNear;

    if (!hasAny) {
      return const Text(
        'No report yet. Run a test to generate your report.',
        style: TextStyle(color: Colors.white),
      );
    }

    // Helper to safely show a value from the private _PseudoAcuity type.
    String show(dynamic v) => v == null ? '—' : v.toString();

    Widget row(String label, String right, String left) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text('Right: $right')),
          Expanded(child: Text('Left:  $left')),
        ],
      ),
    );

    Widget block(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: child,
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary snapshot
        block(
          'Summary',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overall: ${data.overallLabel}'),
              const SizedBox(height: 4),
              Text(data.assessment),
              if (data.ageGroupLabel != null) ...[
                const SizedBox(height: 6),
                Text('Age Group: ${data.ageGroupLabel}'),
              ],
            ],
          ),
        ),

        // Distance section
        if (hasDistance)
          block(
            'Distance Acuity',
            row(
              'Distance',
              show(data.distanceRight), // e.g. "20/40 (logMAR 0.30)"
              show(data.distanceLeft),
            ),
          ),

        // Near section
        if (hasNear)
          block(
            'Near Acuity',
            row('Near', show(data.nearRight), show(data.nearLeft)),
          ),

        // Guidance from ReportService
        block(
          'Assessment',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.ageAdjustedVerdict ?? '—'),
              const SizedBox(height: 6),
              Text(data.refractiveHint ?? '—'),
              const SizedBox(height: 6),
              Text(
                data.warning ?? '—',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        const Text(
          'Disclaimer: Screening only. Not a diagnosis. See an eye care professional for concerns.',
          style: TextStyle(color: Color(0xFFA85500)),
        ),
      ],
    );
  }
}
