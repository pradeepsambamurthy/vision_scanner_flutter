// lib/screens/app_shell.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Screens / widgets
import 'acuity_test_screen.dart';
import 'report_screen.dart'; // must export ReportBody (content-only)
import 'login_screen.dart'; // must export LoginFormEmbedded

enum AppSection { home, howto, about, test, report }

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

Widget heroBanner(BuildContext context) {
  return Container(
    height: 140, // adjust 120–180 to taste
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/peekvision_hero.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        // Optional darken overlay for readability
        // Container(color: Colors.black.withOpacity(0.25)),
      ],
    ),
  );
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  late final TabController _tab;

  bool _showLogin = false; // inline overlay visibility
  int? _pendingTabAfterLogin; // where to go after successful login

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    if (widget.initialTab != null) _tab.index = widget.initialTab!.index;

    // Close login overlay and continue to requested tab after sign in
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user != null && _showLogin) {
        setState(() => _showLogin = false);
        if (_pendingTabAfterLogin != null) {
          _tab.animateTo(_pendingTabAfterLogin!);
          _pendingTabAfterLogin = null;
        }
      } else {
        // Refresh header account state
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _openLoginInline({int? goToTabAfter}) {
    setState(() {
      _pendingTabAfterLogin = goToTabAfter;
      _showLogin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
        title: const _BrandTitle(), // <-- pill sits here
        actions: [
          if (FirebaseAuth.instance.currentUser == null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => _openLoginInline(),
                icon: const Icon(Icons.login),
                label: const Text('Sign in'),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                tooltip: FirebaseAuth.instance.currentUser!.email ?? 'Account',
                icon: const Icon(Icons.account_circle, color: Colors.white),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'email',
                    enabled: false,
                    child: Text(
                      FirebaseAuth.instance.currentUser!.email ?? 'Signed in',
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'signout',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.logout),
                      title: Text('Sign out'),
                    ),
                  ),
                ],
                onSelected: (v) async {
                  if (v == 'signout') {
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Signed out')));
                    _tab.animateTo(0);
                  }
                },
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              child: TabBar(
                controller: _tab,
                onTap: (i) {
                  if (i == 3 && FirebaseAuth.instance.currentUser == null) {
                    _openLoginInline(goToTabAfter: 3);
                    _tab.animateTo(_tab.index);
                  } else {
                    _tab.animateTo(i);
                  }
                },
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
                  Tab(icon: Icon(Icons.home_outlined), text: 'Home'),
                  Tab(icon: Icon(Icons.menu_book_outlined), text: 'How to Use'),
                  Tab(icon: Icon(Icons.info_outline), text: 'About'),
                  Tab(icon: Icon(Icons.visibility_outlined), text: 'Test'),
                  Tab(icon: Icon(Icons.description_outlined), text: 'Report'),
                ],
              ),
            ),
          ),
        ),
      ),

      // ================== BODY ==================
      body: Stack(
        children: [
          // 1) Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/eye_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          // 2) Soft wash for readability (blur + darker scrim + vignette)
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

          // 3) Pages
          Positioned.fill(
            child: TabBarView(
              controller: _tab,
              physics: FirebaseAuth.instance.currentUser == null
                  ? const NeverScrollableScrollPhysics()
                  : null,
              children: [
                _HomeContent(
                  onStartTest: () {
                    if (FirebaseAuth.instance.currentUser == null) {
                      _openLoginInline(goToTabAfter: 3);
                    } else {
                      _tab.animateTo(3);
                    }
                  },
                ),
                _HowToContent(
                  onGoTest: () {
                    if (FirebaseAuth.instance.currentUser == null) {
                      _openLoginInline(goToTabAfter: 3);
                    } else {
                      _tab.animateTo(3);
                    }
                  },
                ),
                const _AboutContent(),
                TestContent(
                  onRequestLogin: () => _openLoginInline(goToTabAfter: 3),
                ),
                const _ReportTab(),
              ],
            ),
          ),

          // 4) Login overlay under header
          if (_showLogin) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showLogin = false),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(color: Colors.black.withOpacity(0.20)),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Sign in / Sign up',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: () =>
                                    setState(() => _showLogin = false),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          LoginFormEmbedded(
                            onSuccess: () {
                              setState(() => _showLogin = false);
                              if (_pendingTabAfterLogin != null) {
                                _tab.animateTo(_pendingTabAfterLogin!);
                                _pendingTabAfterLogin = null;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Signed in successfully'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
    ); // <-- close Scaffold
  }
}

// ================== Small widgets ==================
class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    // Size of the pill in the header
    final double bannerH = w >= 1200
        ? 64
        : w >= 900
        ? 60
        : 56;
    final double bannerW = w >= 1200
        ? 380
        : w >= 900
        ? 100
        : 80;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          // keep the black translucent background + border/shadow
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
          // the image fills the pill completely (no text/row next to it)
          child: SizedBox(
            width: bannerW,
            height: bannerH,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                // put the image you want to fill the pill
                'assets/images/logo_peekvision.png',
                fit: BoxFit.cover, // <— fill the pill area
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
  final double opacity; // background tint opacity
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
  const _HomeContent({required this.onStartTest});
  final VoidCallback onStartTest;

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
              'The app can flag possible issues such as nearsightedness (myopia), farsightedness, or presbyopia, '
              'and it highlights large differences between your eyes. Remember: this is a screening tool, not a medical diagnosis.',
              style: text.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.97),
                fontWeight: FontWeight.w600,
                fontSize: 20,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),

            // Quick actions
            Row(
              children: [
                SizedBox(
                  width: 240,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Test'),
                    onPressed: onStartTest,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),

            const SizedBox(height: 24),

            // Feature cards
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _TwoTestsCard(),
                _InfoCard(
                  icon: Icons.rule,
                  title: 'Age-aware guidance',
                  body:
                      'We compare your result with typical ranges for your age and explain it in plain language.',
                ),
                _InfoCard(
                  icon: Icons.compare_arrows,
                  title: 'Between-eye differences',
                  body:
                      'If one eye is much clearer than the other, we’ll flag it so you can follow up.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            _Section(
              title: 'What you’ll need',
              children: const [
                _Bullet('A quiet, well-lit spot with minimal glare.'),
                _Bullet('A phone, tablet, or laptop with this app open.'),
                _Bullet(
                  'A helper if possible — to hold the device and note answers.',
                ),
                _Bullet(
                  'Wear your usual glasses/contacts if you normally use them.',
                ),
              ],
            ),

            _Section(
              title: 'How it works',
              children: const [
                _Bullet(
                  'Choose Distance (~3 m / 10 ft) or Near (~40 cm / 16″).',
                ),
                _Bullet(
                  'Cover one eye (don’t press on it) and read 5 letters per line.',
                ),
                _Bullet(
                  'Tap “I Can Read” to go smaller, or “I Can’t Read” to switch eyes.',
                ),
                _Bullet(
                  'The app automatically tests both eyes and saves your results.',
                ),
                _Bullet('Find your shareable results under the Report tab.'),
              ],
            ),

            _Section(
              title: 'Tips for accurate results',
              children: const [
                _Bullet(
                  'Keep the required distance steady; avoid screen glare.',
                ),
                _Bullet('Hold the device around eye level.'),
                _Bullet('Use your usual correction if you wear it daily.'),
                _Bullet(
                  'If letters double or distort, consider a full eye exam.',
                ),
              ],
            ),

            _Section(
              title: 'FAQ',
              children: const [
                _FaqItem(
                  q: 'Is this a diagnosis?',
                  a: 'No. This is a screening. If you have symptoms or concerns, see an eye-care professional.',
                ),
                _FaqItem(
                  q: 'What is nearsightedness (myopia)?',
                  a: 'Far objects look blurry while near objects are clearer. The Distance test (~3 m / 10 ft) helps screen for this.',
                ),
                _FaqItem(
                  q: 'What is farsightedness (hyperopia/presbyopia)?',
                  a: 'Far can be clear, but reading up close may be tiring or blurry. The Near test (~40 cm / 16″) helps screen for this.',
                ),
                _FaqItem(
                  q: 'What does “20/20” mean?',
                  a: 'At 20 feet, you can read what a typical person can read at 20 feet. 20/40 means letters must be twice as large; 20/16 is better than average.',
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: Colors.white)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontWeight: FontWeight.w600,
                fontSize: 20,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.q, required this.a});
  final String q;
  final String a;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.white24),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        textColor: Colors.white,
        collapsedTextColor: Colors.white,
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        title: Text(
          q,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                a,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(12),
      child: const Text(
        'Disclaimer: Screening only — not a diagnosis. If you have symptoms, eye strain, or concerns about your vision, please consult an eye-care professional.',
        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TwoTestsCard extends StatelessWidget {
  const _TwoTestsCard();

  @override
  Widget build(BuildContext context) {
    final bodyColor = Colors.white.withOpacity(0.95);
    const titleStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    );

    TextSpan bulletLine({
      required String lead,
      required String mid,
      required Color midColor,
      required String tail,
    }) {
      return TextSpan(
        children: [
          const TextSpan(
            text: '•  ',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          TextSpan(
            text: lead,
            style: TextStyle(
              color: bodyColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: mid,
            style: TextStyle(
              color: midColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: tail,
            style: TextStyle(
              color: bodyColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(text: '\n\n'),
        ],
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
      child: Glass(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.remove_red_eye_outlined, color: Colors.white),
            const SizedBox(height: 8),
            const Text('Two test types', style: titleStyle),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: TextStyle(color: bodyColor, height: 1.35),
                children: [
                  bulletLine(
                    lead: 'Distance test (≈3 m / 10 ft): screens for ',
                    mid: 'nearsightedness',
                    midColor: _Brand.teal,
                    tail:
                        ' (myopia). Near tasks (books/phone) are clearer; far objects (signs/boards) can be blurry.',
                  ),
                  bulletLine(
                    lead: 'Near test (≈40 cm / 16″): screens for ',
                    mid: 'farsightedness/reading difficulty',
                    midColor: _Brand.purple,
                    tail:
                        ' (hyperopia/presbyopia). Far is often clear; reading up close can be tiring or blurry.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// HOW TO USE
// ======================================================================
class _HowToContent extends StatelessWidget {
  const _HowToContent({required this.onGoTest});
  final VoidCallback onGoTest;

  Widget step({required int n, required String title, required String body}) {
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

  Widget bullet(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  ', style: TextStyle(color: Colors.white)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w600,
              height: 1.35,
              fontSize: 20,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 220,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Go to Test'),
                  onPressed: onGoTest,
                ),
              ),
            ),
            const SizedBox(height: 12),

            step(
              n: 1,
              title: 'Prepare the space',
              body:
                  'Choose a well-lit room, reduce glare, and keep the screen at roughly eye level.',
            ),
            step(
              n: 2,
              title: 'Pick a test',
              body:
                  'Distance (~3 m / 10 ft) screens nearsightedness. Near (~40 cm / 16″) screens reading difficulty (hyperopia/presbyopia).',
            ),
            step(
              n: 3,
              title: 'Use a helper for Distance if possible',
              body:
                  'A helper can measure distance, hold the device steady, and record answers for better accuracy.',
            ),
            step(
              n: 4,
              title: 'Cover the opposite eye',
              body:
                  'Testing RIGHT eye → cover LEFT. Testing LEFT → cover RIGHT. Avoid pressing on the covered eye.',
            ),
            step(
              n: 5,
              title: 'Read 5 letters per line',
              body:
                  'Say the letters out loud. Tap “I Can Read” to go smaller; tap “I Can’t Read” to switch eyes or finish and generate your report.',
            ),
            step(
              n: 6,
              title: 'View your results',
              body:
                  'When both eyes are done, your report is generated automatically and available on the Report tab.',
            ),
            const SizedBox(height: 10),

            Glass(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Do & Don’t',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    bullet(
                      'Do keep the distance consistent (3 m for Distance, 40 cm for Near).',
                    ),
                    bullet(
                      'Do wear your usual glasses/contacts if you normally use them.',
                    ),
                    bullet('Don’t squint or lean forward while reading.'),
                    bullet(
                      'Stop if you feel eye strain or see double and consider a full exam.',
                    ),
                  ],
                ),
              ),
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
    final textTheme = Theme.of(context).textTheme;

    Widget section(String title, List<Widget> children) => Glass(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );

    Widget bullet(String s) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          Expanded(
            child: Text(
              s,
              style: textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.95),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            section("Our Approach", [
              bullet(
                'We focus on screening — simulating a step-by-step eye-chart experience, not just prescription renewal.',
              ),
              bullet(
                'We present clear letter lines like a Snellen chart with simple, guided steps.',
              ),
              bullet(
                'We keep the UI accessible with readable text, clear instructions, and helpful hints.',
              ),
              bullet(
                'We generate understandable reports so users know what the result means.',
              ),
              bullet(
                'Available on iOS, Android, and the web for broad access.',
              ),
            ]),
            section("The Future", [
              bullet(
                'Add AI assistance to help pre-screen for common conditions (e.g., diabetic retinopathy, glaucoma).',
              ),
              bullet(
                'Offer community screening features for schools, NGOs, and rural clinics.',
              ),
              bullet(
                'Create a kid-friendly mode with gamified tasks to boost engagement.',
              ),
              bullet(
                'Build provider partnerships to bridge screening and professional care.',
              ),
            ]),
            Glass(
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '✨ We’re building more than an app — we’re building a future where eye health is accessible, proactive, and preventive.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== TEST + REPORT TABS ==================
class TestContent extends StatelessWidget {
  const TestContent({required this.onRequestLogin});
  final VoidCallback onRequestLogin;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Not signed in → block access and show a sign-in card
    if (user == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Glass(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sign in required',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please sign in to run the vision test.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: onRequestLogin,
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in / Sign up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Signed in → show the real test UI
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Glass(
            child: const Padding(
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
// Uses ReportBody from report_screen.dart.
class _ReportTab extends StatelessWidget {
  const _ReportTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Glass(
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: ReportBody(),
            ),
          ),
        ),
      ),
    );
  }
}
