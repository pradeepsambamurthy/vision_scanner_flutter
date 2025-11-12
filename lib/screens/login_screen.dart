// lib/screens/login_screen.dart
import 'package:eyesight_flutter/models/gender.dart';
import 'package:eyesight_flutter/models/patient_store.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as g;

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 420,
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: LoginFormEmbedded(),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginFormEmbedded extends StatefulWidget {
  const LoginFormEmbedded({super.key, this.onSuccess});
  final VoidCallback? onSuccess;

  @override
  State<LoginFormEmbedded> createState() => _LoginFormEmbeddedState();
}

class _LoginFormEmbeddedState extends State<LoginFormEmbedded> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  // MATCHES your enum: { male, female, other, preferNot }
  final List<Gender> _genders = const [
    Gender.male,
    Gender.female,
    Gender.other,
    Gender.preferNot,
  ];
  Gender? _gender;

  bool _busy = false;
  String? _error;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  // ---------- AUTH ----------
  Future<void> _signInWithGoogle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleUser = await g.GoogleSignIn().signIn();
        if (googleUser == null) {
          setState(() => _busy = false);
          return; // cancelled
        }
        final googleAuth = await googleUser.authentication;
        final cred = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );
        await FirebaseAuth.instance.signInWithCredential(cred);
      }
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!kIsWeb) {
        await g.GoogleSignIn().signOut();
      }
      await FirebaseAuth.instance.signOut();
      if (mounted) setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- FORM ----------
  String _labelForGender(Gender g) {
    switch (g) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.preferNot:
        return 'Prefer not to say';
    }
  }

  Future<void> _saveAndStart() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final age = int.parse(_ageCtrl.text.trim());

    // Save to your existing PatientStore
    PatientStore.name = name;
    PatientStore.age = age;
    PatientStore.gender = _gender;

    if (widget.onSuccess != null) {
      widget.onSuccess!.call();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved. You can start the test now.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.login, size: 20),
            const SizedBox(width: 8),
            Text(
              user == null ? 'Sign in / Sign up' : 'Welcome',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (_busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),

        // Step 1: Sign in
        if (user == null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _busy ? null : _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
              ),
              const SizedBox(height: 8),
              const Text(
                'After sign in we’ll collect your Name, Age, and Gender.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          )
        // Step 2: Profile form
        else
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.email ?? user.displayName ?? 'Signed in',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _signOut,
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    final n = int.tryParse(s);
                    if (n == null) return 'Enter a valid age';
                    if (n < 1 || n > 120) return 'Enter an age between 1 and 120';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Gender>(
                      value: _gender,
                      isExpanded: true,
                      hint: const Text('Select gender'),
                      items: _genders
                          .map(
                            (g) => DropdownMenuItem(
                          value: g,
                          child: Text(_labelForGender(g)),
                        ),
                      )
                          .toList(),
                      onChanged: (g) => setState(() => _gender = g),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _busy
                      ? null
                      : () {
                    if (_gender == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please select a gender')),
                      );
                      return;
                    }
                    _saveAndStart();
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Save & Start Test'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
