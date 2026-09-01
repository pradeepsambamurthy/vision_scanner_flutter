// lib/screens/app_shell.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'acuity_test_screen.dart';
import 'report_screen.dart';
import 'color_blindness_screen.dart';

enum AppSection { home, howto, about, color, test, report, contact }

// ================== Brand ==================

class _Brand {
  static const teal = Color(0xFF00CEC9);
  static const purple = Color(0xFF6C5CE7);

  static const name = 'PeekVision';

  static const tagline =
      'Free online vision screening and visual acuity check.';
}

// ================== APP SHELL ==================

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab});

  final AppSection? initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with TickerProviderStateMixin {
  late final TabController _tab;

  int _currentTab = 0;

  String _pageTitle(int index) {
    switch (index) {
      case 0:
        return 'Free Online Eye Test & Vision Screening | PeekVision.io';

      case 1:
        return 'How to Use the Online Vision Test | PeekVision.io';

      case 2:
        return 'About PeekVision | Free Online Vision Screening';

      case 3:
        return 'Free Online Color Vision Test | PeekVision.io';

      case 4:
        return 'Free Online Visual Acuity Test | PeekVision.io';

      case 5:
        return 'Vision Screening Results | PeekVision.io';

      case 6:
        return 'Contact PeekVision | Feedback & Support';

      default:
        return 'PeekVision.io';
    }
  }

  @override
  void initState() {
    super.initState();

    _tab = TabController(
      length: 7,
      vsync: this,
    );

    if (widget.initialTab != null) {
      _tab.index = widget.initialTab!.index;
      _currentTab = widget.initialTab!.index;
    }

    _tab.addListener(() {
      if (!_tab.indexIsChanging &&
          mounted &&
          _currentTab != _tab.index) {
        setState(() {
          _currentTab = _tab.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _go(int index) {
    _tab.animateTo(index);

    setState(() {
      _currentTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      title: _pageTitle(_currentTab),
      color: const Color(0xFF174BAE),

      child: Scaffold(
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
                colors: [
                  Color(0xFF0B1B3B),
                  Color(0xFF174BAE),
                ],
              ),
            ),
          ),

          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(14),
            ),
          ),

          foregroundColor: Colors.white,
          titleSpacing: 12,

          title: const _BrandTitle(),

          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),

            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                12,
              ),

              child: Container(
                height: 56,

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.14),
                  ),
                ),

                child: TabBar(
                  controller: _tab,

                  onTap: (i) {
                    _tab.animateTo(i);

                    setState(() {
                      _currentTab = i;
                    });
                  },

                  dividerColor: Colors.transparent,

                  indicator: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(24),

                    border: Border.all(
                      color: Colors.white.withOpacity(0.22),
                    ),

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

                  unselectedLabelColor:
                      Colors.white.withOpacity(0.90),

                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),

                  tabs: const [
                    Tooltip(
                      message: 'Home',
                      child: Tab(
                        icon: Icon(Icons.home_outlined, size: 18),
                        text: 'Home',
                      ),
                    ),

                    Tooltip(
                      message: 'How to Use',
                      child: Tab(
                        icon: Icon(Icons.menu_book_outlined, size: 18),
                        text: 'How to Use',
                      ),
                    ),

                    Tooltip(
                      message: 'About',
                      child: Tab(
                        icon: Icon(Icons.info_outline, size: 18),
                        text: 'About',
                      ),
                    ),

                    Tooltip(
                      message: 'Color Vision',
                      child: Tab(
                        icon: Icon(Icons.palette_outlined, size: 18),
                        text: 'Color Vision',
                      ),
                    ),

                    Tooltip(
                      message: 'Test',
                      child: Tab(
                        icon: Icon(Icons.visibility_outlined, size: 18),
                        text: 'Test',
                      ),
                    ),

                    Tooltip(
                      message: 'Report',
                      child: Tab(
                        icon: Icon(Icons.description_outlined, size: 18),
                        text: 'Report',
                      ),
                    ),

                    Tooltip(
                      message: 'Contact',
                      child: Tab(
                        icon: Icon(Icons.contact_mail_outlined, size: 18),
                        text: 'Contact',
                      ),
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
                      filter: ImageFilter.blur(
                        sigmaX: 1.0,
                        sigmaY: 1.0,
                      ),
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

                          stops: const [
                            0.0,
                            0.35,
                            1.0,
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(
                            0.2,
                            -0.1,
                          ),

                          radius: 1.2,

                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.22),
                          ],

                          stops: const [
                            0.6,
                            1.0,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pages

            Positioned.fill(
              child: TabBarView(
                controller: _tab,

                physics:
                    const NeverScrollableScrollPhysics(),

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

              colors: [
                Color(0xFF0B1B3B),
                Color(0xFF174BAE),
              ],
            ),
          ),

          child: const SafeArea(
            top: false,

            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),

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
      ),
    );
  }
}

// ================== BRAND TITLE ==================

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    final double bannerH =
        w >= 1200 ? 64 : (w >= 900 ? 60 : 56);

    final double bannerW =
        w >= 1200 ? 380 : (w >= 900 ? 180 : 150);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),

        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.42),

            borderRadius: BorderRadius.circular(14),

            border: Border.all(
              color: Colors.white.withOpacity(0.18),
            ),

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

// ================== GLASS ==================

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
      borderRadius:
          BorderRadius.circular(borderRadius),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
        ),

        child: Container(
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(opacity),

            border: Border.all(
              color:
                  Colors.white.withOpacity(0.20),
            ),

            borderRadius:
                BorderRadius.circular(borderRadius),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.20),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),

          child: Padding(
            padding: padding,
            child: child,
          ),
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
    final text =
        Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxWidth: 1100,
        ),

        child: ListView(
          padding:
              const EdgeInsets.all(24),

          children: [
            Text(
              'Free Online Eye Test & Vision Screening',

              style:
                  text.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight:
                    FontWeight.w800,
                fontSize: 26,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              _Brand.tagline,

              style:
                  text.titleMedium?.copyWith(
                color: _Brand.teal,
                fontWeight:
                    FontWeight.w700,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Check your distance and near visual acuity online using PeekVision. '
              'You can also perform a color vision screening using Ishihara-style plates. '
              'PeekVision provides preliminary vision screening only and does not replace a comprehensive eye examination or medical diagnosis.',

              style:
                  text.titleMedium?.copyWith(
                color: Colors.white
                    .withOpacity(0.97),

                fontWeight:
                    FontWeight.w600,

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

                  child:
                      FilledButton.icon(
                    icon: const Icon(
                      Icons
                          .visibility_outlined,
                    ),

                    label: const Text(
                      'Start Free Vision Test',
                    ),

                    onPressed:
                        onStartVisionTest,
                  ),
                ),

                SizedBox(
                  width: 260,

                  child:
                      FilledButton.icon(
                    icon: const Icon(
                      Icons
                          .palette_outlined,
                    ),

                    label: const Text(
                      'Start Color Vision Test',
                    ),

                    onPressed:
                        onStartColorVision,
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

                  title:
                      'Online Vision Screening',

                  body:
                      'Follow step-by-step guidance to check distance and near vision and review your screening results.',
                ),

                _InfoCard(
                  icon:
                      Icons.compare_arrows,

                  title:
                      'Compare Both Eyes',

                  body:
                      'Screen each eye separately to identify differences in visual acuity that may deserve professional follow-up.',
                ),

                _InfoCard(
                  icon: Icons.palette,

                  title:
                      'Color Vision Screening',

                  body:
                      'Use Ishihara-style plates for a preliminary screen of possible red-green color vision differences.',
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

// ================== INFO CARD ==================

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
      constraints:
          const BoxConstraints(
        minWidth: 260,
        maxWidth: 360,
      ),

      child: Glass(
        padding:
            const EdgeInsets.all(14),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Icon(
              icon,
              color: Colors.white,
            ),

            const SizedBox(height: 8),

            Text(
              title,

              style:
                  const TextStyle(
                color: Colors.white,

                fontWeight:
                    FontWeight.w600,

                fontSize: 20,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              body,

              style: TextStyle(
                color: Colors.white
                    .withOpacity(0.95),

                fontWeight:
                    FontWeight.w600,

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

// ================== DISCLAIMER ==================

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return const Glass(
      padding:
          EdgeInsets.all(12),

      child: Text(
        'Disclaimer: PeekVision provides preliminary vision screening only and is not a medical diagnosis. '
        'It does not replace a comprehensive eye examination. '
        'If you have sudden vision changes, eye pain, eye injury, or other concerns, consult a qualified eye-care professional.',

        style: TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
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

  Widget _step({
    required int n,
    required String title,
    required String body,
  }) {
    return Glass(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Colors.white.withOpacity(0.22),

          foregroundColor:
              Colors.white,

          child: Text(
            '$n',

            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        title: Text(
          title,

          style:
              const TextStyle(
            color: Colors.white,

            fontWeight:
                FontWeight.w600,

            fontSize: 20,
          ),
        ),

        subtitle: Padding(
          padding:
              const EdgeInsets.only(
            top: 6,
          ),

          child: Text(
            body,

            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.95),

              fontWeight:
                  FontWeight.w600,

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
        constraints:
            const BoxConstraints(
          maxWidth: 1000,
        ),

        child: ListView(
          padding:
              const EdgeInsets.all(24),

          children: [
            Text(
              'How to Use the PeekVision Online Eye Test',

              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(
                color: Colors.white,

                fontWeight:
                    FontWeight.w800,

                fontSize: 28,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Follow these steps to prepare your screen, viewing distance, lighting, glasses, and eye position before starting your preliminary vision screening.',

              style: TextStyle(
                color: Colors.white
                    .withOpacity(0.95),

                fontSize: 18,

                fontWeight:
                    FontWeight.w600,

                height: 1.35,
              ),
            ),

            const SizedBox(height: 18),

            Wrap(
              spacing: 12,
              runSpacing: 12,

              children: [
                SizedBox(
                  width: 220,

                  child:
                      FilledButton.icon(
                    icon: const Icon(
                      Icons
                          .palette_outlined,
                    ),

                    label: const Text(
                      'Go to Color Vision',
                    ),

                    onPressed:
                        onGoColorVision,
                  ),
                ),

                SizedBox(
                  width: 220,

                  child:
                      FilledButton.icon(
                    icon: const Icon(
                      Icons
                          .visibility_outlined,
                    ),

                    label: const Text(
                      'Go to Vision Test',
                    ),

                    onPressed:
                        onGoVisionTest,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _step(
              n: 1,

              title:
                  'Prepare the space',

              body:
                  'Choose a well-lit room, reduce glare, and keep the screen at roughly eye level.',
            ),

            _step(
              n: 2,

              title:
                  'Vision tests (Distance/Near)',

              body:
                  'Distance screening checks how clearly you can see at approximately 3 m / 10 ft. '
                  'Near screening checks near visual acuity at approximately 40 cm / 16 in. '
                  'These screening results do not diagnose myopia, hyperopia, or presbyopia.',
            ),

            _step(
              n: 3,

              title:
                  'Cover the opposite eye (Vision)',

              body:
                  'Testing RIGHT eye → cover LEFT. Testing LEFT → cover RIGHT. Avoid pressing on the covered eye.',
            ),

            _step(
              n: 4,

              title:
                  'Color Vision Screening (Ishihara)',

              body:
                  'Sit approximately 30–50 cm from the screen. View each plate for about 3–5 seconds and enter the first number you see. Type "Nothing" if you do not see a number.',
            ),

            _step(
              n: 5,

              title:
                  'Glasses / Contacts guidance',

              body:
                  'If you normally wear prescription glasses or contacts for daily vision, keep them on. Remove sunglasses and tinted or blue-light filtering glasses that may alter colors.',
            ),

            _step(
              n: 6,

              title:
                  'View your report',

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
    final t =
        Theme.of(context).textTheme;

    Widget section(
      String title,
      String body,
    ) {
      return Glass(
        child: Padding(
          padding:
              const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style:
                    t.titleLarge?.copyWith(
                  color: Colors.white,

                  fontWeight:
                      FontWeight.w800,

                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                body,

                style: TextStyle(
                  color: Colors.white
                      .withOpacity(0.95),

                  fontSize: 20,

                  fontWeight:
                      FontWeight.w600,

                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxWidth: 1000,
        ),

        child: ListView(
          padding:
              const EdgeInsets.all(24),

          children: [
            Text(
              'About PeekVision',

              style:
                  t.headlineLarge?.copyWith(
                color: Colors.white,

                fontWeight:
                    FontWeight.w800,

                fontSize: 30,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'PeekVision is a free online preliminary vision screening tool designed to make basic distance, near, and color vision checks easier to access.',

              style: TextStyle(
                color: Colors.white
                    .withOpacity(0.95),

                fontSize: 19,

                fontWeight:
                    FontWeight.w600,

                height: 1.35,
              ),
            ),

            const SizedBox(height: 18),

            section(
              'What is PeekVision?',

              'PeekVision is a free online preliminary vision screening tool for checking distance and near visual acuity. '
              'It also includes a color vision screening using Ishihara-style plates. '
              'No account is required to begin a screening.',
            ),

            const SizedBox(height: 12),

            section(
              'What PeekVision Can and Cannot Do',

              'PeekVision is designed for preliminary vision screening and does not provide a medical diagnosis. '
              'Online screening cannot replace a comprehensive eye examination performed by a qualified eye-care professional.',
            ),

            const SizedBox(height: 12),

            section(
              'Why PeekVision Was Created',

              'PeekVision was created to make basic preliminary vision screening easy to access from a computer. '
              'The goal is to provide a simple first check that can help users understand when professional eye care may be appropriate.',
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// TEST TAB
// ======================================================================

class TestContent extends StatelessWidget {
  const TestContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxWidth: 1100,
        ),

        child: const Padding(
          padding:
              EdgeInsets.all(8.0),

          child: Glass(
            child: Padding(
              padding:
                  EdgeInsets.all(8.0),

              child:
                  AcuityTestScreen(),
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// REPORT TAB
// ======================================================================

class _ReportTab extends StatelessWidget {
  const _ReportTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxWidth: 1100,
        ),

        child: const Padding(
          padding:
              EdgeInsets.all(8),

          child: Glass(
            child: Padding(
              padding:
                  EdgeInsets.all(12),

              child: ReportBody(),
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// CONTACT TAB
// ======================================================================

class _ContactTab extends StatelessWidget {
  const _ContactTab();

  Future<void> _openEmail() async {
    final Uri emailUri =
        Uri.parse(
      'mailto:pradeepkumar.sambamurthy@gmail.com'
      '?subject=PeekVision%20Feedback'
      '&body=Hello%20PeekVision%20Team,%0A%0A',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(
        emailUri,
        mode:
            LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t =
        Theme.of(context).textTheme;

    Widget row({
      required IconData icon,
      required String label,
      required String value,
    }) {
      return Glass(
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Icon(
              icon,
              color: _Brand.teal,
              size: 28,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    label,

                    style:
                        t.titleMedium?.copyWith(
                      color: Colors.white,

                      fontWeight:
                          FontWeight.w800,

                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 6),

                  SelectableText(
                    value,

                    style: TextStyle(
                      color: Colors.white
                          .withOpacity(0.95),

                      fontSize: 18,

                      fontWeight:
                          FontWeight.w600,

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

    Widget emailRow() {
      return Glass(
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Icon(
              Icons.email_outlined,
              color: _Brand.teal,
              size: 28,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    'Email',

                    style:
                        t.titleMedium?.copyWith(
                      color: Colors.white,

                      fontWeight:
                          FontWeight.w800,

                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 6),

                  TextButton.icon(
                    style:
                        TextButton.styleFrom(
                      padding:
                          EdgeInsets.zero,

                      foregroundColor:
                          _Brand.teal,

                      alignment:
                          Alignment.centerLeft,
                    ),

                    icon: const Icon(
                      Icons.mail_outline,
                    ),

                    label: const Text(
                      'pradeepkumar.sambamurthy@gmail.com',

                      style:
                          TextStyle(
                        fontSize: 18,

                        fontWeight:
                            FontWeight.w800,

                        decoration:
                            TextDecoration
                                .underline,
                      ),
                    ),

                    onPressed:
                        _openEmail,
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
        constraints:
            const BoxConstraints(
          maxWidth: 1000,
        ),

        child: ListView(
          padding:
              const EdgeInsets.all(24),

          children: [
            Text(
              'Contact PeekVision',

              style:
                  t.headlineLarge?.copyWith(
                color: Colors.white,

                fontWeight:
                    FontWeight.w800,

                fontSize: 30,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'For feedback, support, or questions about PeekVision, please contact us.',

              style:
                  t.titleMedium?.copyWith(
                color: Colors.white
                    .withOpacity(0.95),

                fontSize: 20,

                fontWeight:
                    FontWeight.w600,

                height: 1.35,
              ),
            ),

            const SizedBox(height: 18),

            emailRow(),

            const SizedBox(height: 12),

            row(
              icon:
                  Icons.language_outlined,

              label: 'Website',

              value:
                  'https://www.peekvision.io',
            ),

            const SizedBox(height: 12),

            row(
              icon:
                  Icons.medical_information_outlined,

              label:
                  'Medical disclaimer',

              value:
                  'PeekVision provides preliminary vision screening only and is not a medical diagnosis. '
                  'It does not replace a comprehensive eye examination. '
                  'If you have symptoms, sudden vision changes, eye pain, eye injury, or concerns about your vision, please consult a qualified eye-care professional.',
            ),
          ],
        ),
      ),
    );
  }
}