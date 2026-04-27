// lib/screens/app_shell.dart
import 'dart:ui';
import 'package:flutter/material.dart';

// Screens / widgets
import 'acuity_test_screen.dart';
import 'report_screen.dart'; // must export ReportBody (content-only)
import 'color_blindness_screen.dart';

enum AppSection { home, howto, about, color, test, report, contact }

// ================== Brand ==================
class _Brand {
  // PeekVision palette
  static const teal = Color(0xFF00CEC9);
  static const purple = Color(0xFF6C5CE7);

  static const name = 'PeekVision';
  static const tagline = 'A quick peek at your eye health.';
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab});
  final AppSection? initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 7, vsync: this);
    if (widget.initialTab != null) _tab.index = widget.initialTab!.index;
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _go(int index) => _tab.animateTo(index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ================== HEADER ==================
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 68,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1B3B), Color(0xFF174BAE)], // navy → blue
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
        ),
        foregroundColor: Colors.white,
        titleSpacing: 12,
        title: const _BrandTitle(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              child: TabBar(
                controller: _tab,
                onTap: (i) => _tab.animateTo(i),
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.90),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(icon: Icon(Icons.home_outlined, size: 18), text: 'Home'),
                  Tab(
                    icon: Icon(Icons.menu_book_outlined, size: 18),
                    text: 'How to Use',
                  ),
                  Tab(icon: Icon(Icons.info_outline, size: 18), text: 'About'),
                  Tab(
                    icon: Icon(Icons.palette_outlined, size: 18),
                    text: 'Color Vision',
                  ),
                  Tab(
                    icon: Icon(Icons.visibility_outlined, size: 18),
                    text: 'Test',
                  ),
                  Tab(
                    icon: Icon(Icons.description_outlined, size: 18),
                    text: 'Report',
                  ),
                  Tab(
                    icon: Icon(Icons.contact_mail_outlined, size: 18),
                    text: 'Contact',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ================== BODY ==================
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/eye_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          // Readability wash
          Positioned.fill(
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
                    child: const SizedBox(),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.62),
                          Colors.black.withOpacity(0.48),
                          Colors.black.withOpacity(0.40),
                        ],
                        stops: const [0.0, 0.35, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.2, -0.1),
                        radius: 1.2,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.22),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pages (MUST be exactly 7 children)
          Positioned.fill(
            child: TabBarView(
              controller: _tab,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _HomeContent(
                  onStartVisionTest: () => _go(4),
                  onStartColorVision: () => _go(3),
                ),
                _HowToContent(
                  onGoVisionTest: () => _go(4),
                  onGoColorVision: () => _go(3),
                ),
                const _AboutContent(),
                const ColorBlindnessScreen(),
                const TestContent(),
                const _ReportTab(),
                const _ContactTab(),
              ],
            ),
          ),
        ],
      ),

      // ================== FOOTER ==================
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF0B1B3B), Color(0xFF174BAE)],
          ),
        ),
        child: const SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '© PeekVision',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================== Small widgets ==================
class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    final double bannerH = w >= 1200 ? 64 : (w >= 900 ? 60 : 56);
    final double bannerW = w >= 1200 ? 380 : (w >= 900 ? 180 : 150);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.42),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox(
            width: bannerW,
            height: bannerH,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo_peekvision.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.opacity = 0.12,
    this.blur = 12,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double opacity;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            border: Border.all(color: Colors.white.withOpacity(0.20)),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

// ======================================================================
// HOME
// ======================================================================
class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.onStartVisionTest,
    required this.onStartColorVision,
  });

  final VoidCallback onStartVisionTest;
  final VoidCallback onStartColorVision;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Welcome to ${_Brand.name}',
              style: text.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _Brand.tagline,
              style: text.titleMedium?.copyWith(
                color: _Brand.teal,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Screen your vision quickly — for both distance and near — just like a traditional eye chart. '
              'You can also do a Color Vision screening using Ishihara-style plates. '
              'Remember: this is a screening tool, not a medical diagnosis.',
              style: text.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.97),
                fontWeight: FontWeight.w600,
                fontSize: 20,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 260,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Start Vision Test'),
                    onPressed: onStartVisionTest,
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('Start Color Vision'),
                    onPressed: onStartColorVision,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoCard(
                  icon: Icons.rule,
                  title: 'Screening guidance',
                  body:
                      'We guide you step-by-step and save results in a simple report you can share.',
                ),
                _InfoCard(
                  icon: Icons.compare_arrows,
                  title: 'Between-eye differences',
                  body:
                      'If one eye is much clearer than the other, we’ll flag it so you can follow up.',
                ),
                _InfoCard(
                  icon: Icons.palette,
                  title: 'Color Vision screening',
                  body:
                      'Ishihara-style plates help indicate possible red-green color vision deficiency.',
                ),
              ],
            ),

            const SizedBox(height: 12),
            const _DisclaimerCard(),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
      child: Glass(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontWeight: FontWeight.w600,
                fontSize: 20,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding: EdgeInsets.all(12),
      child: Text(
        'Disclaimer: Screening only — not a diagnosis. If you have symptoms, eye strain, or concerns about your vision, please consult an eye-care professional.',
        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ======================================================================
// HOW TO USE
// ======================================================================
class _HowToContent extends StatelessWidget {
  const _HowToContent({
    required this.onGoVisionTest,
    required this.onGoColorVision,
  });

  final VoidCallback onGoVisionTest;
  final VoidCallback onGoColorVision;

  Widget _step({required int n, required String title, required String body}) {
    return Glass(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.22),
          foregroundColor: Colors.white,
          child: Text(
            '$n',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            body,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w600,
              height: 1.35,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('Go to Color Vision'),
                    onPressed: onGoColorVision,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Go to Vision Test'),
                    onPressed: onGoVisionTest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _step(
              n: 1,
              title: 'Prepare the space',
              body:
                  'Choose a well-lit room, reduce glare, and keep the screen at roughly eye level.',
            ),
            _step(
              n: 2,
              title: 'Vision tests (Distance/Near)',
              body:
                  'Distance (~3 m / 10 ft) screens nearsightedness. Near (~40 cm / 16″) screens reading difficulty (hyperopia/presbyopia).',
            ),
            _step(
              n: 3,
              title: 'Cover the opposite eye (Vision)',
              body:
                  'Testing RIGHT eye → cover LEFT. Testing LEFT → cover RIGHT. Avoid pressing on the covered eye.',
            ),
            _step(
              n: 4,
              title: 'Color Vision screening (Ishihara)',
              body:
                  'Sit ~30–50 cm from the screen. View each plate for ~3–5 seconds and enter the first number you see (type “Nothing” if none).',
            ),
            _step(
              n: 5,
              title: 'Glasses / Contacts guidance',
              body:
                  'If you normally wear prescription glasses or contacts for daily vision, KEEP them on. Remove sunglasses and any tinted/blue-light filter glasses that change colors.',
            ),
            _step(
              n: 6,
              title: 'View your report',
              body:
                  'After you finish a test, results are saved and shown in the Report tab with next-step guidance.',
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// ABOUT
// ======================================================================
class _AboutContent extends StatelessWidget {
  const _AboutContent();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    Widget section(String title, String body) => Glass(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: t.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            section(
              'What is PeekVision?',
              'PeekVision is a simple vision screening app. It helps you do a quick check for Distance and Near vision (eye-chart style), and it includes a Color Vision screening using Ishihara-style plates.',
            ),
            const SizedBox(height: 12),
            section(
              'What it is (and is not)',
              'PeekVision is for screening only — not a medical diagnosis. It can help you notice possible issues early and decide whether to see an eye-care professional.',
            ),
            const SizedBox(height: 12),
            section(
              'Why we built it',
              'Many people delay eye exams. PeekVision makes it easy to do a quick self-check at home and keep a simple report over time.',
            ),
          ],
        ),
      ),
    );
  }
}

// ================== TEST TAB ==================
class TestContent extends StatelessWidget {
  const TestContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Glass(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: AcuityTestScreen(),
            ),
          ),
        ),
      ),
    );
  }
}

// ================== REPORT TAB ==================
class _ReportTab extends StatelessWidget {
  const _ReportTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Glass(
            child: Padding(padding: EdgeInsets.all(12), child: ReportBody()),
          ),
        ),
      ),
    );
  }
}

// ================== CONTACT TAB ==================
class _ContactTab extends StatelessWidget {
  const _ContactTab();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    Widget row({
      required IconData icon,
      required String label,
      required String value,
    }) {
      return Glass(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _Brand.teal, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: t.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    value,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Contact PeekVision',
              style: t.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Questions, feedback, support, partnerships, or collaboration inquiries.',
              style: t.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.95),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            row(
              icon: Icons.email_outlined,
              label: 'Email',
              value: 'pradeepkumar.sambamurthy@gmail.com',
            ),
            const SizedBox(height: 12),
            row(
              icon: Icons.language_outlined,
              label: 'Website',
              value: 'https://peekvision.io',
            ),
            const SizedBox(height: 12),
            row(
              icon: Icons.medical_information_outlined,
              label: 'Medical disclaimer',
              value:
                  'PeekVision is a screening tool only and is not a medical diagnosis. If you have symptoms, sudden vision changes, eye pain, eye injury, or concerns about your vision, please consult a licensed eye-care professional.',
            ),
          ],
        ),
      ),
    );
  }
}
