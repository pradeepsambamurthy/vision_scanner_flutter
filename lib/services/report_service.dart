// lib/services/report_service.dart
import 'dart:math' as math;
import '../models/vision_models.dart' as vm;

/// Internal, lightweight representation of an eye’s acuity used by the report.
class _PseudoAcuity {
  final double logMAR;
  const _PseudoAcuity(this.logMAR);

  String get snellen {
    final denom = (20 * math.pow(10, logMAR)).round();
    return '20/$denom';
  }

  @override
  String toString() => '$snellen (logMAR ${logMAR.toStringAsFixed(2)})';
}

/// Minimal face summary the report needs (decoupled from any ML service type).
class ReportFace {
  final int? age; // estimated or user-provided
  final String? gender; // "Male"/"Female"/"Other"/"—"
  final bool? wearingGlasses; // detected from photo (optional)

  const ReportFace({this.age, this.gender, this.wearingGlasses});

  Map<String, dynamic> toMap() =>
      {'age': age, 'gender': gender, 'wearingGlasses': wearingGlasses}
        ..removeWhere((_, v) => v == null);
}

class ReportData {
  // Profile (typed-in)
  String? name;
  int? age;
  String? gender;

  // From photo analysis (optional)
  ReportFace? face;

  // ------------------------------------------------------------------
  // Primary section shown in current UI (kept for backward-compat)
  // By default we show the Distance results here if they exist; else Near.
  _PseudoAcuity? right;
  _PseudoAcuity? left;

  // Store results per mode for richer assessment
  _PseudoAcuity? distanceRight;
  _PseudoAcuity? distanceLeft;
  _PseudoAcuity? nearRight;
  _PseudoAcuity? nearLeft;

  // Advisory text (user-facing)
  String? warning;

  // Age classification + age-adjusted assessment + refractive hint
  String? ageGroupLabel; // e.g., "Adult (18–39)"
  String? ageAdjustedVerdict; // e.g., "Within normal range for age"
  String? refractiveHint; // e.g., "Likely short-sight (myopia)"

  // -------- Convenience getters for UI / PDF (string-safe) --------
  String get overallLabel => _worst?.snellen ?? '—';
  String get assessment =>
      'Right: ${right?.snellen ?? '—'}  •  Left: ${left?.snellen ?? '—'}';

  String? get rightSnellen => right?.snellen;
  String? get leftSnellen => left?.snellen;
  String? get distanceRightSnellen => distanceRight?.snellen;
  String? get distanceLeftSnellen => distanceLeft?.snellen;
  String? get nearRightSnellen => nearRight?.snellen;
  String? get nearLeftSnellen => nearLeft?.snellen;

  int? get resolvedAge => age ?? face?.age;
  String get resolvedGender => gender ?? face?.gender ?? '—';
  String get demographicsLine =>
      'Age: ${resolvedAge?.toString() ?? '—'}  •  Gender: $resolvedGender';

  bool get hasDistance => distanceRight != null || distanceLeft != null;
  bool get hasNear => nearRight != null || nearLeft != null;

  _PseudoAcuity? get _worst {
    final r = right;
    final l = left;
    if (r == null && l == null) return null;
    if (l == null) return r;
    if (r == null) return l;
    return r.logMAR >= l.logMAR ? r : l;
  }

  /// For saving/sharing: convert to a simple map (no private types).
  Map<String, dynamic> toMapForStorage() => {
    'name': name,
    'age': resolvedAge,
    'gender': resolvedGender == '—' ? null : resolvedGender,
    'face': face?.toMap(),
    'distanceRight': distanceRight?.snellen,
    'distanceLeft': distanceLeft?.snellen,
    'nearRight': nearRight?.snellen,
    'nearLeft': nearLeft?.snellen,
    'warning': warning,
    'ageGroup': ageGroupLabel,
    'ageVerdict': ageAdjustedVerdict,
    'refractiveHint': refractiveHint,
  }..removeWhere((_, v) => v == null);
}

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  final ReportData current = ReportData();

  // ---------------- Profile / Demographics ----------------

  String? _normalizeGender(String? g) {
    if (g == null) return null;
    final s = g.trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s.startsWith('m')) return 'Male';
    if (s.startsWith('f')) return 'Female';
    const others = {
      'other',
      'nonbinary',
      'non-binary',
      'nb',
      'unspecified',
      'prefer not to say'
    };
    if (others.contains(s)) return 'Other';
    return g.trim()[0].toUpperCase() + g.trim().substring(1);
  }

  /// Called from your capture screen’s text fields.
  void setDemographics({String? name, int? age, String? gender}) {
    current.name = (name == null || name.trim().isEmpty) ? null : name.trim();
    current.age = age;
    current.gender = _normalizeGender(gender);
  }

  /// Backwards-compat setters if you call them separately.
  void updateName(String? v) =>
      current.name = (v == null || v.trim().isEmpty) ? null : v.trim();
  void updateAge(int? v) => current.age = v;
  void updateGender(String? v) => current.gender = _normalizeGender(v);

  /// Accept any “face summary” object and map it to our `ReportFace`.
  void updateFaceSummary(dynamic face) {
    int? age;
    String? gender;
    bool? glasses;

    try {
      final a = face?.age ?? face?.estimatedAge ?? face?.ageYears;
      if (a is num) age = a.toInt();
    } catch (_) {}

    try {
      final g = face?.gender ?? face?.sex;
      if (g is String) gender = _normalizeGender(g);
    } catch (_) {}

    try {
      final w = face?.wearingGlasses ?? face?.glasses ?? face?.hasGlasses;
      if (w is bool) glasses = w;
    } catch (_) {}

    current.face = ReportFace(
      age: age,
      gender: gender,
      wearingGlasses: glasses,
    );
  }

  // ---------------- Acuity results + derived assessments ----------------
  //
  // Legacy (distance-only) entry point: still supported.
  void updateAcuity(vm.AcuityResult right, vm.AcuityResult left) {
    // Treat as Distance if mode not specified.
    updateAcuityModeAware(mode: vm.TestMode.distance, right: right, left: left);
  }

  /// New: Mode-aware update.
  void updateAcuityModeAware({
    required vm.TestMode mode,
    required vm.AcuityResult right,
    required vm.AcuityResult left,
  }) {
    final r = _PseudoAcuity(right.logMAR);
    final l = _PseudoAcuity(left.logMAR);

    if (mode == vm.TestMode.distance) {
      current.distanceRight = r;
      current.distanceLeft = l;
    } else if (mode == vm.TestMode.near) {
      current.nearRight = r;
      current.nearLeft = l;
    } else {
      current.distanceRight = r;
      current.distanceLeft = l;
    }

    // What should the primary section display?
    if (current.distanceRight != null || current.distanceLeft != null) {
      current.right = current.distanceRight;
      current.left = current.distanceLeft;
    } else {
      current.right = current.nearRight;
      current.left = current.nearLeft;
    }

    _recomputeAssessments();
  }

  /// If you ever need to clone/normalize the model for the report screen.
  static ReportData normalize(ReportData r) => r;

  /// Clear everything.
  void resetAll() {
    current
      ..name = null
      ..age = null
      ..gender = null
      ..face = null
      ..right = null
      ..left = null
      ..distanceRight = null
      ..distanceLeft = null
      ..nearRight = null
      ..nearLeft = null
      ..warning = null
      ..ageGroupLabel = null
      ..ageAdjustedVerdict = null
      ..refractiveHint = null;
  }

  // ---------------- Derived assessments ----------------

  void _recomputeAssessments() {
    final age = current.age ?? current.face?.age;
    final ageInfo = _ageClassAndThreshold(age);
    current.ageGroupLabel = ageInfo.label;

    // Worst (higher logMAR = worse) per mode
    double? worstDist, worstNear;
    double? diffDist, diffNear;

    if (current.distanceRight != null || current.distanceLeft != null) {
      final dr = current.distanceRight?.logMAR ?? double.negativeInfinity;
      final dl = current.distanceLeft?.logMAR ?? double.negativeInfinity;
      worstDist = _maxOrNull(dr, dl);
      diffDist = _absDiffOrNull(
        current.distanceRight?.logMAR,
        current.distanceLeft?.logMAR,
      );
    }
    if (current.nearRight != null || current.nearLeft != null) {
      final nr = current.nearRight?.logMAR ?? double.negativeInfinity;
      final nl = current.nearLeft?.logMAR ?? double.negativeInfinity;
      worstNear = _maxOrNull(nr, nl);
      diffNear = _absDiffOrNull(
        current.nearRight?.logMAR,
        current.nearLeft?.logMAR,
      );
    }

    // Warning: consider either test; flag anisometropia if gap large in either mode
    current.warning = _buildWarningCombined(
      rDist: current.distanceRight?.logMAR,
      lDist: current.distanceLeft?.logMAR,
      rNear: current.nearRight?.logMAR,
      lNear: current.nearLeft?.logMAR,
    );

    // Age-adjusted verdict: pass if the worst of either mode is at/above age norms
    final overallWorst = _maxNonNull([worstDist, worstNear]);
    if (overallWorst != null && overallWorst <= ageInfo.passThresholdLogMAR) {
      current.ageAdjustedVerdict = 'Within normal range for age';
    } else {
      current.ageAdjustedVerdict = 'Refer (below age norms)';
    }

    // Refractive hint using BOTH tests when available
    current.refractiveHint = _refractiveHintCombined(
      worstDistance: worstDist,
      worstNear: worstNear,
      interEyeDiffDistance: diffDist,
      interEyeDiffNear: diffNear,
      age: age,
    );
  }

  // ---- Warnings ----

  String _buildWarningCombined({
    double? rDist,
    double? lDist,
    double? rNear,
    double? lNear,
  }) {
    const double consultThreshold = 0.30; // ~20/40
    const double anisometropiaGap = 0.20; // ~2 ETDRS lines

    bool consult = false;
    bool anisometropia = false;

    // Distance flags
    if (rDist != null && rDist >= consultThreshold) consult = true;
    if (lDist != null && lDist >= consultThreshold) consult = true;
    if (rDist != null &&
        lDist != null &&
        (rDist - lDist).abs() >= anisometropiaGap) {
      anisometropia = true;
    }

    // Near flags
    if (rNear != null && rNear >= consultThreshold) consult = true;
    if (lNear != null && lNear >= consultThreshold) consult = true;
    if (rNear != null &&
        lNear != null &&
        (rNear - lNear).abs() >= anisometropiaGap) {
      anisometropia = true;
    }

    if (consult) return 'Consult an eye doctor for a detailed exam.';
    if (anisometropia) {
      return 'Consider a professional eye exam (difference between eyes).';
    }
    return 'Your eyes appear healthy with good vision.';
  }

  // ---- Age classification & thresholds ----

  _AgeInfo _ageClassAndThreshold(int? age) {
    if (age == null) {
      // Use adult defaults if unknown
      return const _AgeInfo('Adult (18–59)', 0.20); // ~20/32
    }
    if (age <= 5) return const _AgeInfo('Under 6 (not supported)', 0.20);
    if (age <= 12) return const _AgeInfo('Child (6–12)', 0.18); // ~20/30
    if (age <= 17) return const _AgeInfo('Teen (13–17)', 0.20); // ~20/32
    if (age <= 39) return const _AgeInfo('Adult (18–39)', 0.20); // ~20/32
    if (age <= 59) return const _AgeInfo('Adult (40–59)', 0.20); // ~20/32
    return const _AgeInfo('Older adult (60+)', 0.30); // ~20/40
  }

  // ---- Refractive pattern hint ----
  String _refractiveHintCombined({
    required double? worstDistance,
    required double? worstNear,
    required double? interEyeDiffDistance,
    required double? interEyeDiffNear,
    required int? age,
  }) {
    const double okCut = 0.20; // ~20/32 or better
    const double myopiaCut = 0.30; // ~20/40 (distance reduced)
    const double bigGap = 0.20; // ~2 ETDRS lines
    final a = age ?? 0;

    final gapBig =
        (interEyeDiffDistance != null && interEyeDiffDistance >= bigGap) ||
            (interEyeDiffNear != null && interEyeDiffNear >= bigGap);

    if (gapBig) {
      return 'Difference between eyes is notable — possible astigmatism or anisometropia.';
    }

    // Legacy-only cases
    if (worstNear == null && worstDistance != null) {
      if (worstDistance >= myopiaCut) {
        return 'Likely short-sight (myopia) — distance vision reduced.';
      }
      if (a >= 45) {
        return 'Distance is OK. If near reading is hard, age-related long-sight (presbyopia) is common.';
      }
      return 'No strong refractive pattern from distance screening alone.';
    }

    if (worstDistance == null && worstNear != null) {
      if (worstNear > okCut) {
        return a >= 40
            ? 'Near vision reduced with age — likely presbyopia.'
            : 'Near vision reduced — possible long-sight (hyperopia).';
      }
      return 'Near vision within expected range.';
    }

    // Both available
    final distBad = (worstDistance ?? 0) > okCut;
    final nearBad = (worstNear ?? 0) > okCut;

    if (distBad && !nearBad) {
      return 'Likely short-sight (myopia) — distance vision reduced.';
    }
    if (!distBad && nearBad) {
      return a >= 40
          ? 'Likely presbyopia (age-related near focus).'
          : 'Possible long-sight (hyperopia) — near vision reduced.';
    }
    if (distBad && nearBad) {
      return 'Reduced vision at both distances — please get a full exam.';
    }
    return 'Within expected range.';
  }

  // ---------------- Utilities ----------------

  double? _maxOrNull(double a, double b) {
    if (a == double.negativeInfinity && b == double.negativeInfinity) {
      return null;
    }
    return a > b ? a : b;
  }

  double? _maxNonNull(List<double?> xs) {
    double? best;
    for (final x in xs) {
      if (x == null) continue;
      if (best == null || x > best) best = x;
    }
    return best;
  }

  double? _absDiffOrNull(double? a, double? b) {
    if (a == null || b == null) return null;
    return (a - b).abs();
  }
}

class _AgeInfo {
  final String label;
  /// Maximum acceptable logMAR (lower/equal is passing).
  final double passThresholdLogMAR;
  const _AgeInfo(this.label, this.passThresholdLogMAR);
}
