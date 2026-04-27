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

  int get denominator {
    return (20 * math.pow(10, logMAR)).round();
  }

  @override
  String toString() => snellen;
}

class ReportFace {
  final int? age;
  final String? gender;
  final bool? wearingGlasses;

  const ReportFace({this.age, this.gender, this.wearingGlasses});

  Map<String, dynamic> toMap() =>
      {'age': age, 'gender': gender, 'wearingGlasses': wearingGlasses}
        ..removeWhere((_, v) => v == null);
}

class ReportData {
  String? name;
  int? age;
  String? gender;

  ReportFace? face;

  _PseudoAcuity? right;
  _PseudoAcuity? left;
  _PseudoAcuity? both;

  _PseudoAcuity? distanceRight;
  _PseudoAcuity? distanceLeft;
  _PseudoAcuity? distanceBoth;

  _PseudoAcuity? nearRight;
  _PseudoAcuity? nearLeft;
  _PseudoAcuity? nearBoth;

  String? warning;
  String? ageGroupLabel;
  String? ageAdjustedVerdict;
  String? refractiveHint;

  Map<String, dynamic>? colorBlindness;

  bool get hasDistance =>
      distanceRight != null || distanceLeft != null || distanceBoth != null;

  bool get hasNear => nearRight != null || nearLeft != null || nearBoth != null;

  String get overallLabel => _worst?.snellen ?? '—';

  String get assessment {
    return 'Right eye: ${right?.snellen ?? '—'} | '
        'Left eye: ${left?.snellen ?? '—'} | '
        'Both eyes: ${both?.snellen ?? '—'}';
  }

  _PseudoAcuity? get _worst {
    final values = <_PseudoAcuity>[
      if (right != null) right!,
      if (left != null) left!,
      if (both != null) both!,
    ];

    if (values.isEmpty) return null;

    values.sort((a, b) => b.logMAR.compareTo(a.logMAR));
    return values.first;
  }

  Map<String, dynamic> toMapForStorage() => {
    'name': name,
    'age': age ?? face?.age,
    'gender': gender ?? face?.gender,
    'face': face?.toMap(),
    'distanceRight': distanceRight?.snellen,
    'distanceLeft': distanceLeft?.snellen,
    'distanceBoth': distanceBoth?.snellen,
    'nearRight': nearRight?.snellen,
    'nearLeft': nearLeft?.snellen,
    'nearBoth': nearBoth?.snellen,
    'warning': warning,
    'ageGroup': ageGroupLabel,
    'ageVerdict': ageAdjustedVerdict,
    'refractiveHint': refractiveHint,
    'colorBlindness': colorBlindness,
  }..removeWhere((_, v) => v == null);
}

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  final ReportData current = ReportData();

  void setDemographics({String? name, int? age, String? gender}) {
    current.name = (name == null || name.trim().isEmpty) ? null : name.trim();
    current.age = age;
    current.gender = gender;
  }

  String? get currentGender => current.gender;
  String? get currentName => current.name;
  int? get currentAge => current.age;

  void updateName(String? v) =>
      current.name = (v == null || v.trim().isEmpty) ? null : v.trim();

  void updateAge(int? v) => current.age = v;

  void updateGender(String? v) => current.gender = v;

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
      if (g is String && g.trim().isNotEmpty) gender = g.trim();
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

  void setColorBlindnessResult({
    required int total,
    required int correct,
    required double accuracy,
    required String diagnosis,
    required Map<String, String> answers,
  }) {
    current.colorBlindness = {
      'total': total,
      'correct': correct,
      'accuracy': accuracy,
      'diagnosis': diagnosis,
      'answers': answers,
    };
  }

  void updateAcuity(vm.AcuityResult right, vm.AcuityResult left) {
    updateAcuityModeAware(mode: vm.TestMode.distance, right: right, left: left);
  }

  void updateAcuityModeAware({
    required vm.TestMode mode,
    required vm.AcuityResult right,
    required vm.AcuityResult left,
    vm.AcuityResult? both,
  }) {
    final r = _PseudoAcuity(right.logMAR);
    final l = _PseudoAcuity(left.logMAR);
    final b = both == null ? null : _PseudoAcuity(both.logMAR);

    if (mode == vm.TestMode.distance) {
      current.distanceRight = r;
      current.distanceLeft = l;
      current.distanceBoth = b;
    } else {
      current.nearRight = r;
      current.nearLeft = l;
      current.nearBoth = b;
    }

    if (current.distanceRight != null ||
        current.distanceLeft != null ||
        current.distanceBoth != null) {
      current.right = current.distanceRight;
      current.left = current.distanceLeft;
      current.both = current.distanceBoth;
    } else {
      current.right = current.nearRight;
      current.left = current.nearLeft;
      current.both = current.nearBoth;
    }

    _recomputeAssessments();
  }

  static ReportData normalize(ReportData r) => r;

  void resetAll() {
    current
      ..name = null
      ..age = null
      ..gender = null
      ..face = null
      ..right = null
      ..left = null
      ..both = null
      ..distanceRight = null
      ..distanceLeft = null
      ..distanceBoth = null
      ..nearRight = null
      ..nearLeft = null
      ..nearBoth = null
      ..warning = null
      ..ageGroupLabel = null
      ..ageAdjustedVerdict = null
      ..refractiveHint = null
      ..colorBlindness = null;
  }

  void _recomputeAssessments() {
    final age = current.age ?? current.face?.age;
    final ageInfo = _ageClassAndThreshold(age);
    current.ageGroupLabel = ageInfo.label;

    final worstDist = _maxNonNull([
      current.distanceRight?.logMAR,
      current.distanceLeft?.logMAR,
      current.distanceBoth?.logMAR,
    ]);

    final worstNear = _maxNonNull([
      current.nearRight?.logMAR,
      current.nearLeft?.logMAR,
      current.nearBoth?.logMAR,
    ]);

    final diffDist = _absDiffOrNull(
      current.distanceRight?.logMAR,
      current.distanceLeft?.logMAR,
    );

    final diffNear = _absDiffOrNull(
      current.nearRight?.logMAR,
      current.nearLeft?.logMAR,
    );

    current.warning = _buildWarningCombined(
      rDist: current.distanceRight?.logMAR,
      lDist: current.distanceLeft?.logMAR,
      rNear: current.nearRight?.logMAR,
      lNear: current.nearLeft?.logMAR,
    );

    final overallWorst = _maxNonNull([worstDist, worstNear]);

    if (overallWorst != null && overallWorst <= ageInfo.passThresholdLogMAR) {
      current.ageAdjustedVerdict =
          'Your vision screening result appears to be within the expected range for your age group.';
    } else {
      current.ageAdjustedVerdict =
          'Your vision screening result may be below the expected range for your age group.';
    }

    current.refractiveHint = _refractiveHintCombined(
      worstDistance: worstDist,
      worstNear: worstNear,
      interEyeDiffDistance: diffDist,
      interEyeDiffNear: diffNear,
      age: age,
    );
  }

  String _buildWarningCombined({
    double? rDist,
    double? lDist,
    double? rNear,
    double? lNear,
  }) {
    const double consultThreshold = 0.30;
    const double eyeDifferenceGap = 0.20;

    bool reducedVision = false;
    bool eyeDifference = false;

    if (rDist != null && rDist >= consultThreshold) reducedVision = true;
    if (lDist != null && lDist >= consultThreshold) reducedVision = true;
    if (rNear != null && rNear >= consultThreshold) reducedVision = true;
    if (lNear != null && lNear >= consultThreshold) reducedVision = true;

    if (rDist != null &&
        lDist != null &&
        (rDist - lDist).abs() >= eyeDifferenceGap) {
      eyeDifference = true;
    }

    if (rNear != null &&
        lNear != null &&
        (rNear - lNear).abs() >= eyeDifferenceGap) {
      eyeDifference = true;
    }

    if (reducedVision) {
      return 'One or both eyes may have some difficulty seeing clearly. Please consider a professional eye exam.';
    }

    if (eyeDifference) {
      return 'There is a noticeable difference between your right and left eye. If this happens again, consider a professional eye exam.';
    }

    return 'No major concern was detected in this screening.';
  }

  _AgeInfo _ageClassAndThreshold(int? age) {
    if (age == null) return const _AgeInfo('Adult', 0.20);
    if (age <= 5) return const _AgeInfo('Child under 6', 0.20);
    if (age <= 12) return const _AgeInfo('Child', 0.18);
    if (age <= 17) return const _AgeInfo('Teen', 0.20);
    if (age <= 39) return const _AgeInfo('Adult', 0.20);
    if (age <= 59) return const _AgeInfo('Adult 40–59', 0.20);
    return const _AgeInfo('Older adult 60+', 0.30);
  }

  String _refractiveHintCombined({
    required double? worstDistance,
    required double? worstNear,
    required double? interEyeDiffDistance,
    required double? interEyeDiffNear,
    required int? age,
  }) {
    const double okCut = 0.20;
    const double reducedCut = 0.30;
    const double bigGap = 0.20;

    final a = age ?? 0;

    final gapBig =
        (interEyeDiffDistance != null && interEyeDiffDistance >= bigGap) ||
        (interEyeDiffNear != null && interEyeDiffNear >= bigGap);

    if (gapBig) {
      return 'Your right and left eye results are different. This can happen because of tiredness, lighting, screen distance, glasses, or an actual difference between the eyes.';
    }

    if (worstDistance != null && worstNear == null) {
      if (worstDistance >= reducedCut) {
        return 'Your distance vision may need attention. This can happen with nearsightedness or other vision issues.';
      }
      return 'Your distance vision appears clear in this screening.';
    }

    if (worstNear != null && worstDistance == null) {
      if (worstNear > okCut) {
        return a >= 40
            ? 'Your near vision may be reduced. This is common with age-related reading difficulty.'
            : 'Your near vision may need attention.';
      }
      return 'Your near vision appears clear in this screening.';
    }

    final distReduced = (worstDistance ?? 0) > okCut;
    final nearReduced = (worstNear ?? 0) > okCut;

    if (distReduced && !nearReduced) {
      return 'Your distance vision may be weaker than your near vision.';
    }

    if (!distReduced && nearReduced) {
      return a >= 40
          ? 'Your near vision may be weaker. This can happen with age-related reading difficulty.'
          : 'Your near vision may need attention.';
    }

    if (distReduced && nearReduced) {
      return 'Your vision may be reduced for both distance and near tasks. Please consider a full eye exam.';
    }

    return 'Your vision appears within the expected range in this screening.';
  }

  double? _maxNonNull(List<double?> xs) {
    double? result;
    for (final x in xs) {
      if (x == null) continue;
      if (result == null || x > result) result = x;
    }
    return result;
  }

  double? _absDiffOrNull(double? a, double? b) {
    if (a == null || b == null) return null;
    return (a - b).abs();
  }
}

class _AgeInfo {
  final String label;
  final double passThresholdLogMAR;
  const _AgeInfo(this.label, this.passThresholdLogMAR);
}
