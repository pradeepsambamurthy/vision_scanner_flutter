// lib/screens/login_screen.dart
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Google (mobile)
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
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _withBusy(Future<void> Function() fn) async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await fn();
      widget.onSuccess?.call();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Auth error: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- Email / password ----------
  Future<void> _signInEmail() async => _withBusy(() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _email.text.trim(),
      password: _pass.text,
    );
  });

  Future<void> _signUpEmail() async => _withBusy(() async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _email.text.trim(),
      password: _pass.text,
    );
  });

  // ---------- Google ----------
  Future<void> _signInGoogle() async => _withBusy(() async {
    final auth = FirebaseAuth.instance;

    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      await auth.signInWithPopup(provider);
      return;
    }

    // Android/iOS
    final googleUser = await g.GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Google sign-in canceled.');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );
    await auth.signInWithCredential(credential);
  });

  @override
  Widget build(BuildContext context) {
    final btnStyle = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return AbsorbPointer(
      absorbing: _busy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          TextField(
            controller: _email,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pass,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _signInEmail,
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _signUpEmail,
                  child: const Text('Create account'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Or continue with', textAlign: TextAlign.center),
          const SizedBox(height: 8),

          ElevatedButton.icon(
            style: btnStyle,
            onPressed: _signInGoogle,
            icon: const Icon(Icons.g_mobiledata),
            label: const Text('Google'),
          ),
        ],
      ),
    );
  }
}
