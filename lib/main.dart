import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/app_shell.dart';
import 'screens/capture_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const VisionApp());
}

class VisionApp extends StatelessWidget {
  const VisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E60E6),
        brightness: Brightness.light,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PeekVision',
      theme: theme,
      home: const AppShell(),
      routes: {
        '/start': (_) => const CaptureScreen(),
        '/app': (_) => const AppShell(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/report') {
          return MaterialPageRoute<void>(
            builder: (_) => const AppShell(initialTab: AppSection.report),
            settings: settings,
          );
        }
        if (settings.name == '/test') {
          return MaterialPageRoute<void>(
            builder: (_) => const AppShell(initialTab: AppSection.test),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
