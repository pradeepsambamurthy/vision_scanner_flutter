// lib/screens/capture_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/report_service.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _gender; // 'Male' / 'Female' / 'Other' / null
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Prefill from Auth displayName
        if ((user.displayName ?? '').trim().isNotEmpty) {
          _nameCtrl.text = user.displayName!.trim();
        }
        // Prefill from Firestore if present
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          if ((data['name'] ?? '').toString().trim().isNotEmpty) {
            _nameCtrl.text = data['name'].toString().trim();
          }
          if (data['age'] != null) {
            _ageCtrl.text = data['age'].toString();
          }
          if ((data['gender'] ?? '').toString().isNotEmpty) {
            _gender = data['gender'].toString();
          }
        }
      }
    } catch (_) {
      // ignore prefilling errors
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndStart() async {
    final name = _nameCtrl.text.trim();
    final age = int.tryParse(_ageCtrl.text.trim());
    final gender = _gender;

    // Save to report service (used by your PDF/report)
    ReportService.instance.setDemographics(
      name: name.isEmpty ? null : name,
      age: age,
      gender: gender,
    );

    // Persist to Firestore for next time (if signed in)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name.isEmpty ? null : name,
        'age': age,
        'gender': gender,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // keep Auth displayName in sync (optional)
      if (name.isNotEmpty && name != (user.displayName ?? '')) {
        await user.updateDisplayName(name);
      }
    }

    if (!mounted) return;
    // IMPORTANT: go to /test (the _TestGate will enforce that gender is set)
    Navigator.pushNamed(context, '/test');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Start / Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name (optional)',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ageCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Age (years, optional)',
                border: OutlineInputBorder(),
                helperText: 'Leave blank if unknown',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null; // optional
                final n = int.tryParse(v.trim());
                if (n == null || n < 1 || n > 120) {
                  return 'Enter a valid age (1–120) or leave blank';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(
                  value: 'Other',
                  child: Text('Other / Prefer not to say'),
                ),
              ],
              decoration: const InputDecoration(
                labelText: 'Gender (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _gender = val),
              // To make gender REQUIRED, uncomment:
              // validator: (v) => (v == null || v.isEmpty) ? 'Please select gender' : null,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                if (_formKey.currentState?.validate() != true) return;
                _saveAndStart();
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Save & Start Test'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: You can wear your usual glasses if you normally use them.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
