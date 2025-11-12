// lib/services/cloud_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/report_service.dart';

class CloudService {
  CloudService._();
  static final CloudService instance = CloudService._();

  final _db = FirebaseFirestore.instance;

  /// Saves the current report under: users/{uid}/reports/{autoId}
  /// Fields match ReportData.toMapForStorage() plus createdAt.
  Future<void> saveReport() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final r = ReportService.instance.current;
    final data = r.toMapForStorage()
      ..addAll({'createdAt': FieldValue.serverTimestamp()});

    await _db.collection('users').doc(uid).collection('reports').add(data);
  }
}
