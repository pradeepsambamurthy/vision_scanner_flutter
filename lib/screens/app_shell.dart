// lib/screens/app_shell.dart
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// PDF / printing
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

// App services
import 'package:eyesight_flutter/services/report_service.dart'
    show ReportService;

// Screens / widgets
import 'acuity_test_screen.dart';
import 'report_screen.dart'; // defines ReportBody (content-only)
import 'login_screen.dart'; // must export LoginFormEmbedded

enum AppSection { home, howto, about, test, report }

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab});
  final AppSection? initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
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

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user != null && _showLogin) {
        setState(() => _showLogin = false);
        if (_pendingTabAfterLogin != null) {
          _tab.animateTo(_pendingTabAfterLogin!);
          _pendingTabAfterLogin = null;
        }
      } else {
        setState(() {}); // refresh header account state
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _goHome() => _tab.animateTo(0);

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
        centerTitle: false,
        backgroundColor: const Color(0xFF1E60E6),
        foregroundColor: Colors.white,
        elevation: 0,
        title: _BrandTitle(onTap: _goHome),
        actions: [
          if (user == null)
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
                tooltip: user.email ?? 'Account',
                icon: const Icon(Icons.account_circle, color: Colors.white),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'email',
                    enabled: false,
                    child: Text(user.email ?? 'Signed in'),
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
                    _goHome();
                  }
                },
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xFF2F7AF7),
            child: TabBar(
              controller: _tab,
              onTap: (i) {
                // Gate the Test tab (index 3) behind login
                if (i == 3 && FirebaseAuth.instance.currentUser == null) {
                  _openLoginInline(goToTabAfter: 3);
                  _tab.animateTo(_tab.index); // keep current until login
                } else {
                  _tab.animateTo(i);
                }
              },
              indicator: BoxDecoration(
                color: const Color(0xFF1E60E6),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.92),
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
          // 2) Soft wash for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0.18),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
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
                const _TestGate(), // <- gate now asks for Name/Age first
                _ReportTab(onDownloadPdf: _downloadReportPdf),
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
                                    fontSize: 18,
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
        color: const Color(0xFF1E60E6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '© Vision Screener',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              Text('v1.0.0', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- PDF download ----------------
  Future<void> _downloadReportPdf() async {
    try {
      final data = ReportService.instance.current;

      String show(dynamic v) => v == null ? '—' : v.toString();

      pw.Widget h1(String t) => pw.Text(
        t,
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
      );
      pw.Widget h2(String t) => pw.Text(
        t,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      );
      pw.Widget kv(String k, String v) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(k),
          pw.SizedBox(width: 12),
          pw.Expanded(child: pw.Text(v, textAlign: pw.TextAlign.right)),
        ],
      );
      pw.Widget block(String title, List<pw.Widget> children) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          h2(title),
          pw.SizedBox(height: 6),
          ...children,
          pw.SizedBox(height: 10),
        ],
      );

      final doc = pw.Document();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              h1('Vision Screener Report'),
              pw.SizedBox(height: 4),
              pw.Text('Generated: ${DateTime.now().toIso8601String()}'),
              pw.Divider(),
              pw.SizedBox(height: 8),

              block('Profile', [
                kv('Name', data.name ?? '—'),
                kv('Age', (data.age ?? data.face?.age)?.toString() ?? '—'),
                kv('Gender', data.gender ?? data.face?.gender ?? '—'),
                if (data.face?.wearingGlasses != null)
                  kv(
                    'Wearing Glasses',
                    data.face!.wearingGlasses! ? 'Yes' : 'No',
                  ),
              ]),

              block('Summary', [
                kv('Overall', data.overallLabel),
                kv('Assessment', data.assessment),
                kv('Age Group', data.ageGroupLabel ?? '—'),
              ]),

              block('Distance Acuity', [
                kv('Right', show(data.distanceRight)),
                kv('Left', show(data.distanceLeft)),
              ]),

              block('Near Acuity', [
                kv('Right', show(data.nearRight)),
                kv('Left', show(data.nearLeft)),
              ]),

              block('Assessment & Guidance', [
                kv('Age-adjusted verdict', data.ageAdjustedVerdict ?? '—'),
                kv('Refractive hint', data.refractiveHint ?? '—'),
                kv('Warning', data.warning ?? '—'),
              ]),

              pw.SizedBox(height: 12),
              pw.Text(
                'Disclaimer: Screening only. Not a diagnosis. See an eye care professional for concerns.',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'VisionScreener_Report.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not create PDF: $e')));
    }
  }
}

// ================== Small widgets ==================
class _BrandTitle extends StatelessWidget {
  const _BrandTitle({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      mouseCursor: SystemMouseCursors.click,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.visibility, color: Colors.white),
          SizedBox(width: 10),
          Text(
            'Vision Screener',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ---------------- Home ----------------
class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.onStartTest});
  final VoidCallback onStartTest;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final titleStyle = text.headlineMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );
    final bodyStyle = text.bodyLarge?.copyWith(
      color: Colors.white.withOpacity(0.92),
      fontWeight: FontWeight.w600,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Welcome', style: titleStyle),
            const SizedBox(height: 12),
            Text(
              'Use this app to quickly screen visual acuity at distance and near. '
              'While this is not a medical diagnosis, it helps flag potential issues '
              '(e.g., myopia, presbyopia, large inter-eye differences).',
              style: bodyStyle,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 280,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Test'),
                  onPressed: onStartTest,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- How to ----------------
class _HowToContent extends StatelessWidget {
  const _HowToContent({required this.onGoTest});
  final VoidCallback onGoTest;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final titleStyle = text.headlineMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );
    final bodyStyle = text.bodyLarge?.copyWith(
      color: Colors.white.withOpacity(0.92),
      fontWeight: FontWeight.w600,
    );

    Widget dot(String s) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: Colors.white)),
          Expanded(child: Text(s, style: bodyStyle)),
        ],
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('How to Use This Test', style: titleStyle),
            const SizedBox(height: 12),
            dot('Best with a helper at ~10 ft (3 m).'),
            dot('Test one eye at a time; cover the other without pressure.'),
            dot('Read the smallest line you can; the helper records results.'),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Go to Test'),
              onPressed: onGoTest,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- About ----------------
class _AboutContent extends StatelessWidget {
  const _AboutContent();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final titleStyle = text.headlineMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );
    final bodyStyle = text.bodyLarge?.copyWith(
      color: Colors.white.withOpacity(0.92),
      fontWeight: FontWeight.w600,
    );

    Widget info(String title, String body, IconData icon) => Card(
      color: Colors.white.withOpacity(0.18),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(body, style: bodyStyle),
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('About the App', style: titleStyle),
            const SizedBox(height: 12),
            info(
              'Distance & Near Acuity',
              'We map how small you can read to Snellen/logMAR labels.',
              Icons.format_size,
            ),
            info(
              'Age-Adjusted Hints',
              'We compare with age thresholds for patterns like myopia/presbyopia.',
              Icons.rule,
            ),
            info(
              'Inter-Eye Differences',
              'Large differences between eyes are flagged.',
              Icons.compare_arrows,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Test Gate ----------------
// If signed in but Name/Age missing, show demographics form before the test.
class _TestGate extends StatefulWidget {
  const _TestGate();

  @override
  State<_TestGate> createState() => _TestGateState();
}

class _TestGateState extends State<_TestGate> {
  bool _needsDemo() {
    final r = ReportService.instance.current;
    return (r.name == null || r.name!.trim().isEmpty) || (r.age == null);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snap.data;
        if (user == null) return const _LoginRequiredCard();

        if (_needsDemo()) {
          return _DemographicsCard(
            onSaved: (name, age) {
              ReportService.instance.setDemographics(name: name, age: age);
              setState(() {}); // refresh; next build will show test
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saved. You can start the test now.'),
                ),
              );
            },
          );
        }

        return const _TestContent();
      },
    );
  }
}

class _DemographicsCard extends StatefulWidget {
  const _DemographicsCard({required this.onSaved});
  final void Function(String name, int age) onSaved;

  @override
  State<_DemographicsCard> createState() => _DemographicsCardState();
}

class _DemographicsCardState extends State<_DemographicsCard> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            color: Colors.white,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Before we begin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please enter your name and age for the report.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _age,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n <= 0 || n > 120) {
                          return 'Enter a valid age';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Save & Start Test'),
                      onPressed: () {
                        if (_form.currentState?.validate() != true) return;
                        widget.onSaved(
                          _name.text.trim(),
                          int.parse(_age.text.trim()),
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
    );
  }
}

class _TestContent extends StatelessWidget {
  const _TestContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color: Colors.white.withOpacity(0.12),
            elevation: 0,
            margin: const EdgeInsets.all(8),
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

class _LoginRequiredCard extends StatelessWidget {
  const _LoginRequiredCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            color: Colors.white.withOpacity(0.18),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Sign in required. Use the “Sign in” button in the top bar to log in and begin the test.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Report Tab ----------------
class _ReportTab extends StatelessWidget {
  const _ReportTab({required this.onDownloadPdf});
  final Future<void> Function() onDownloadPdf;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Colors.white.withOpacity(0.12),
            elevation: 0,
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Your Report', style: titleStyle),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: ReportBody(), // your existing content-only widget
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Download Report'),
                      onPressed: onDownloadPdf,
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
