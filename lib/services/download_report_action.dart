// lib/actions/download_report_action.dart
import 'package:flutter/material.dart';
import '../services/report_service.dart';
import '../services/report_pdf.dart';
import '../services/report_saver.dart';

class DownloadReportAction {
  static Future<void> run(BuildContext context) async {
    try {
      final data =
      ReportService.normalize(ReportService.instance.current);
      final bytes = await ReportPdf.build(data);
      await ReportSaver.saveAndOpen(bytes);

      // Optional toast
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report saved (and opened if possible).')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }
}
