// lib/main.dart
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
      tabBarTheme: const TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EyeSight',
      theme: theme,
      home: const AppShell(), // Tabs live here (Test tab includes the gate)
      routes: {
        '/start': (_) =>
            const CaptureScreen(), // profile form screen (also saves gender)
        '/app': (_) => const AppShell(),
      },
      // Use onGenerateRoute to jump to specific tabs
      onGenerateRoute: (settings) {
        if (settings.name == '/report') {
          return MaterialPageRoute<void>(
            builder: (_) => AppShell(initialTab: AppSection.report),
            settings: settings,
          );
        }
        if (settings.name == '/test') {
          return MaterialPageRoute<void>(
            builder: (_) => AppShell(initialTab: AppSection.test),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
