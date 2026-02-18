// lib/services/cloud_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_service.dart';

class CloudService {
  CloudService._();
  static final CloudService instance = CloudService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Saves the current report publicly: public_reports/{autoId}
  Future<void> saveReport() async {
    final r = ReportService.instance.current;

    final data = r.toMapForStorage()
      ..addAll({'createdAt': FieldValue.serverTimestamp()});

    await _db.collection('public_reports').add(data);
  }
}
