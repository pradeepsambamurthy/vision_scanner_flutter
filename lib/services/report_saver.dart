// lib/services/report_saver.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

class ReportSaver {
  static Future<File> savePdf(Uint8List bytes, {String? fileName}) async {
    final dir = await getApplicationDocumentsDirectory();
    final name = fileName ??
        'vision_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> openPdf(File file) async {
    final res = await OpenFilex.open(file.path);
    if (res.type != ResultType.done) {
      // Emulator often has no PDF viewer — share as fallback
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Vision Screener report',
      );
    }
  }

  static Future<void> saveAndOpen(Uint8List bytes) async {
    final file = await savePdf(bytes);
    await openPdf(file);
  }

  static Future<void> saveAndShare(Uint8List bytes) async {
    final file = await savePdf(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Vision Screener report');
  }
}
