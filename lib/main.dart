// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/app_shell.dart';
import 'screens/capture_screen.dart';
import 'screens/acuity_test_screen.dart';

// NOTE: Do NOT import 'report_screen.dart' here — the Report UI is shown inside AppShell’s Report tab
// NOTE: We also don’t need to import login_screen.dart here (it’s used inside AppShell’s overlay)

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
      // keep these non-const unless constructors are const
      home: AppShell(),
      routes: {
        '/start': (_) => CaptureScreen(),
        '/test': (_) => AcuityTestScreen(),
        '/app': (_) => AppShell(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/report') {
          return MaterialPageRoute<void>(
            builder: (_) => AppShell(initialTab: AppSection.report),
          );
        }
        return null;
      },
    );
  }
}