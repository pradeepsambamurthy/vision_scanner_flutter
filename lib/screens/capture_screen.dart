// lib/screens/capture_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _loadLocalProfile();
  }

  Future<void> _loadLocalProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _nameCtrl.text = prefs.getString('profile_name') ?? '';
      _ageCtrl.text = prefs.getString('profile_age') ?? '';
      _gender = prefs.getString('profile_gender');
    } catch (_) {
      // ignore
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

    // Save to report service (used by PDF/report)
    ReportService.instance.setDemographics(
      name: name.isEmpty ? null : name,
      age: age,
      gender: gender,
    );

    // Save locally (no login)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    await prefs.setString('profile_age', _ageCtrl.text.trim());
    if (gender == null) {
      await prefs.remove('profile_gender');
    } else {
      await prefs.setString('profile_gender', gender);
    }

    if (!mounted) return;
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
              initialValue: _gender,
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
          ],
        ),
      ),
    );
  }
}
