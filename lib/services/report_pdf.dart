// lib/services/report_pdf.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'report_service.dart';

class ReportPdf {
  static Future<Uint8List> build(ReportData r) async {
    final doc = pw.Document();
    final now = DateTime.now();

    pw.Widget row(String label, String value) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(value),
      ],
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text('Vision Screener Report',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.SizedBox(height: 4),
          pw.Text('Generated: ${now.toLocal()}'),
          pw.SizedBox(height: 16),

          // Demographics
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                row('Name', r.name ?? '—'),
                row('Age', (r.resolvedAge?.toString()) ?? '—'),
                row('Gender', r.resolvedGender),
              ],
            ),
          ),

          pw.SizedBox(height: 16),
          pw.Text('Summary',
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          row('Overall', r.overallLabel),
          row('Right', r.rightSnellen ?? '—'),
          row('Left', r.leftSnellen ?? '—'),

          pw.SizedBox(height: 12),
          pw.Text('Distance',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          row('Right', r.distanceRightSnellen ?? '—'),
          row('Left', r.distanceLeftSnellen ?? '—'),

          pw.SizedBox(height: 8),
          pw.Text('Near', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          row('Right', r.nearRightSnellen ?? '—'),
          row('Left', r.nearLeftSnellen ?? '—'),

          pw.SizedBox(height: 16),
          pw.Text('Assessment',
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if (r.ageGroupLabel != null) pw.Text('Age Group: ${r.ageGroupLabel}'),
          if (r.ageAdjustedVerdict != null) pw.Text(r.ageAdjustedVerdict!),
          if (r.gender != null) pw.Text('Gender: ${r.gender}'),
          if (r.refractiveHint != null) pw.Text(r.refractiveHint!),
          if (r.warning != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                r.warning!,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),

          pw.SizedBox(height: 24),
          pw.Text(
            'Disclaimer: Screening only. Not a diagnosis. '
                'Consult an eye care professional for concerns.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    return doc.save();
  }
}
