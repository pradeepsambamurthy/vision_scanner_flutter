// lib/screens/login_gate.dart
import 'package:flutter/material.dart';

class LoginGate extends StatelessWidget {
  const LoginGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/app'),
          child: const Text('Continue'),
        ),
      ),
    );
  }
}
