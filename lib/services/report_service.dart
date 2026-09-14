// lib/services/report_service.dart

import '../models/vision_models.dart' as vm;

// ================================================================
// REPORT TEST METHOD
// ================================================================

enum VisionTestMethod {
  standard,
  accessible,
}

extension VisionTestMethodLabel on VisionTestMethod {
  String get label {
    switch (this) {
      case VisionTestMethod.standard:
        return 'Standard Vision Test';

      case VisionTestMethod.accessible:
        return 'Accessible / Voice-Assisted Vision Test';
    }
  }
}

// ================================================================
// RESPONSE METHOD
// ================================================================

enum VisionResponseMethod {
  manual,
  voiceAssisted,
}

extension VisionResponseMethodLabel on VisionResponseMethod {
  String get label {
    switch (this) {
      case VisionResponseMethod.manual:
        return 'Manual response';

      case VisionResponseMethod.voiceAssisted:
        return 'Voice recognition with large-button fallback';
    }
  }
}

// ================================================================
// FACE SUMMARY
// ================================================================

class ReportFace {
  final int? age;
  final String? gender;
  final bool? wearingGlasses;

  const ReportFace({
    this.age,
    this.gender,
    this.wearingGlasses,
  });

  Map<String, dynamic> toMap() => {
        'age': age,
        'gender': gender,
        'wearingGlasses': wearingGlasses,
      }..removeWhere(
          (_, value) => value == null,
        );
}

// ================================================================
// REPORT DATA
// ================================================================

class ReportData {
  String? name;
  int? age;
  String? gender;

  ReportFace? face;

  // ================================================================
  // DISTANCE VISUAL ACUITY
  // ================================================================

  vm.AcuityResult? distanceRight;
  vm.AcuityResult? distanceLeft;
  vm.AcuityResult? distanceBoth;

  VisionTestMethod? distanceTestMethod;
  VisionResponseMethod? distanceResponseMethod;

  // ================================================================
  // NEAR VISUAL ACUITY
  // ================================================================

  vm.AcuityResult? nearRight;
  vm.AcuityResult? nearLeft;
  vm.AcuityResult? nearBoth;

  VisionTestMethod? nearTestMethod;
  VisionResponseMethod? nearResponseMethod;

  // ================================================================
  // LEGACY / GENERAL REFERENCES
  // ================================================================

  vm.AcuityResult? right;
  vm.AcuityResult? left;
  vm.AcuityResult? both;

  // ================================================================
  // REPORT TEXT
  // ================================================================

  String? warning;
  String? ageGroupLabel;
  String? ageAdjustedVerdict;
  String? refractiveHint;

  Map<String, dynamic>? colorBlindness;

  // ================================================================
  // AVAILABILITY
  // ================================================================

  bool get hasDistance =>
      distanceRight != null ||
      distanceLeft != null ||
      distanceBoth != null;

  bool get hasNear =>
      nearRight != null ||
      nearLeft != null ||
      nearBoth != null;

  bool get hasColorVision =>
      colorBlindness != null;

  bool get hasAnyReport =>
      hasDistance ||
      hasNear ||
      hasColorVision;

  // ================================================================
  // REPORT LABELS
  // ================================================================

  String get distanceTestMethodLabel =>
      (distanceTestMethod ??
              VisionTestMethod.standard)
          .label;

  String get distanceResponseMethodLabel =>
      (distanceResponseMethod ??
              VisionResponseMethod.manual)
          .label;

  String get nearTestMethodLabel =>
      (nearTestMethod ??
              VisionTestMethod.standard)
          .label;

  String get nearResponseMethodLabel =>
      (nearResponseMethod ??
              VisionResponseMethod.manual)
          .label;

  // ================================================================
  // SIMPLE SUMMARY
  // ================================================================

  String get overallLabel {
    final worst = _worstResult;

    if (worst == null) {
      return '—';
    }

    return worst.screeningLevel;
  }

  String get assessment {
    return 'Right eye: ${right?.screeningLevel ?? '—'} | '
        'Left eye: ${left?.screeningLevel ?? '—'} | '
        'Both eyes: ${both?.screeningLevel ?? '—'}';
  }

  vm.AcuityResult? get _worstResult {
    final results =
        <vm.AcuityResult>[
      if (right != null) right!,
      if (left != null) left!,
      if (both != null) both!,
    ];

    if (results.isEmpty) {
      return null;
    }

    results.sort(
      (a, b) =>
          b.logMAR.compareTo(
        a.logMAR,
      ),
    );

    return results.first;
  }

  // ================================================================
  // STORAGE
  // ================================================================

  Map<String, dynamic> _acuityToMap(
    vm.AcuityResult? result,
  ) {
    if (result == null) {
      return {};
    }

    return {
      'logMAR': result.logMAR,
      'snellen': result.snellen,
      'screeningLevel':
          result.screeningLevel,
      'eye': result.eye.name,
      'belowRange':
          result.belowRange,
      'correction':
          result.correction.name,
      'correctionLabel':
          result.correction.label,
      'testDistanceCm':
          result.testDistanceCm,
      'testDistanceLabel':
          result.testDistanceLabel,
    };
  }

  Map<String, dynamic>
      toMapForStorage() {
    final map =
        <String, dynamic>{
      'name': name,
      'age': age ?? face?.age,
      'gender':
          gender ?? face?.gender,
      'face': face?.toMap(),

      'distanceRight':
          distanceRight == null
              ? null
              : _acuityToMap(
                  distanceRight,
                ),

      'distanceLeft':
          distanceLeft == null
              ? null
              : _acuityToMap(
                  distanceLeft,
                ),

      'distanceBoth':
          distanceBoth == null
              ? null
              : _acuityToMap(
                  distanceBoth,
                ),

      'distanceTestMethod':
          distanceTestMethod?.name,

      'distanceTestMethodLabel':
          distanceTestMethod?.label,

      'distanceResponseMethod':
          distanceResponseMethod
              ?.name,

      'distanceResponseMethodLabel':
          distanceResponseMethod
              ?.label,

      'nearRight':
          nearRight == null
              ? null
              : _acuityToMap(
                  nearRight,
                ),

      'nearLeft':
          nearLeft == null
              ? null
              : _acuityToMap(
                  nearLeft,
                ),

      'nearBoth':
          nearBoth == null
              ? null
              : _acuityToMap(
                  nearBoth,
                ),

      'nearTestMethod':
          nearTestMethod?.name,

      'nearTestMethodLabel':
          nearTestMethod?.label,

      'nearResponseMethod':
          nearResponseMethod
              ?.name,

      'nearResponseMethodLabel':
          nearResponseMethod
              ?.label,

      'warning': warning,
      'ageGroup':
          ageGroupLabel,
      'ageVerdict':
          ageAdjustedVerdict,
      'refractiveHint':
          refractiveHint,
      'colorBlindness':
          colorBlindness,
    };

    map.removeWhere(
      (_, value) =>
          value == null,
    );

    return map;
  }
}

// ================================================================
// REPORT SERVICE
// ================================================================

class ReportService {
  ReportService._();

  static final ReportService instance =
      ReportService._();

  final ReportData current =
      ReportData();

  // ================================================================
  // DEMOGRAPHICS
  // ================================================================

  void setDemographics({
    String? name,
    int? age,
    String? gender,
  }) {
    current.name =
        (name == null ||
                name.trim().isEmpty)
            ? null
            : name.trim();

    current.age = age;
    current.gender = gender;

    _recomputeAssessments();
  }

  String? get currentGender =>
      current.gender;

  String? get currentName =>
      current.name;

  int? get currentAge =>
      current.age;

  void updateName(
    String? value,
  ) {
    current.name =
        (value == null ||
                value.trim().isEmpty)
            ? null
            : value.trim();
  }

  void updateAge(
    int? value,
  ) {
    current.age = value;

    _recomputeAssessments();
  }

  void updateGender(
    String? value,
  ) {
    current.gender =
        value;
  }

  // ================================================================
  // FACE SUMMARY
  // ================================================================

  void updateFaceSummary(
    dynamic face,
  ) {
    int? age;
    String? gender;
    bool? glasses;

    try {
      final value =
          face?.age ??
              face?.estimatedAge ??
              face?.ageYears;

      if (value is num) {
        age =
            value.toInt();
      }
    } catch (_) {}

    try {
      final value =
          face?.gender ??
              face?.sex;

      if (value is String &&
          value.trim().isNotEmpty) {
        gender =
            value.trim();
      }
    } catch (_) {}

    try {
      final value =
          face?.wearingGlasses ??
              face?.glasses ??
              face?.hasGlasses;

      if (value is bool) {
        glasses =
            value;
      }
    } catch (_) {}

    current.face =
        ReportFace(
      age: age,
      gender: gender,
      wearingGlasses:
          glasses,
    );

    _recomputeAssessments();
  }

  // ================================================================
  // COLOR VISION
  // ================================================================

  void setColorBlindnessResult({
    required int total,
    required int correct,
    required double accuracy,
    required String diagnosis,
    required Map<String, String>
        answers,
  }) {
    current.colorBlindness = {
      'total': total,
      'correct': correct,
      'accuracy': accuracy,
      'diagnosis':
          diagnosis,
      'answers':
          answers,
    };
  }

  // ================================================================
  // VISUAL ACUITY
  // ================================================================

  void updateAcuity(
    vm.AcuityResult right,
    vm.AcuityResult left,
  ) {
    updateAcuityModeAware(
      mode:
          vm.TestMode.distance,
      right:
          right,
      left:
          left,
      testMethod:
          VisionTestMethod.standard,
      responseMethod:
          VisionResponseMethod.manual,
    );
  }

  void updateAcuityModeAware({
    required vm.TestMode mode,
    required vm.AcuityResult right,
    required vm.AcuityResult left,
    vm.AcuityResult? both,

    VisionTestMethod testMethod =
        VisionTestMethod.standard,

    VisionResponseMethod responseMethod =
        VisionResponseMethod.manual,
  }) {
    if (mode ==
        vm.TestMode.distance) {
      current.distanceRight =
          right;

      current.distanceLeft =
          left;

      current.distanceBoth =
          both;

      current.distanceTestMethod =
          testMethod;

      current.distanceResponseMethod =
          responseMethod;
    } else if (mode ==
        vm.TestMode.near) {
      current.nearRight =
          right;

      current.nearLeft =
          left;

      current.nearBoth =
          both;

      current.nearTestMethod =
          testMethod;

      current.nearResponseMethod =
          responseMethod;
    } else {
      current.right =
          right;

      current.left =
          left;

      current.both =
          both;
    }

    /*
      Keep the older general fields available.

      Distance results are preferred when present.
    */
    if (current.hasDistance) {
      current.right =
          current.distanceRight;

      current.left =
          current.distanceLeft;

      current.both =
          current.distanceBoth;
    } else if (current.hasNear) {
      current.right =
          current.nearRight;

      current.left =
          current.nearLeft;

      current.both =
          current.nearBoth;
    }

    _recomputeAssessments();
  }

  // ================================================================
  // NORMALIZATION
  // ================================================================

  static ReportData normalize(
    ReportData report,
  ) {
    return report;
  }

  // ================================================================
  // RESET
  // ================================================================

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

      ..distanceTestMethod =
          null
      ..distanceResponseMethod =
          null

      ..nearRight = null
      ..nearLeft = null
      ..nearBoth = null

      ..nearTestMethod =
          null
      ..nearResponseMethod =
          null

      ..warning = null
      ..ageGroupLabel =
          null
      ..ageAdjustedVerdict =
          null
      ..refractiveHint =
          null

      ..colorBlindness =
          null;
  }

  // ================================================================
  // ASSESSMENTS
  // ================================================================

  void _recomputeAssessments() {
    final age =
        current.age ??
            current.face?.age;

    current.ageGroupLabel =
        _ageGroupLabel(
      age,
    );

    final worstDistance =
        _worstLogMAR([
      current.distanceRight,
      current.distanceLeft,
      current.distanceBoth,
    ]);

    final worstNear =
        _worstLogMAR([
      current.nearRight,
      current.nearLeft,
      current.nearBoth,
    ]);

    final distanceDifference =
        _eyeDifference(
      current.distanceRight,
      current.distanceLeft,
    );

    final nearDifference =
        _eyeDifference(
      current.nearRight,
      current.nearLeft,
    );

    current.warning =
        _buildWarning(
      worstDistance:
          worstDistance,
      worstNear:
          worstNear,
      distanceDifference:
          distanceDifference,
      nearDifference:
          nearDifference,
    );

    current.ageAdjustedVerdict =
        _buildOverallVerdict(
      worstDistance:
          worstDistance,
      worstNear:
          worstNear,
    );

    current.refractiveHint =
        _buildPlainLanguageSummary(
      worstDistance:
          worstDistance,
      worstNear:
          worstNear,
      distanceDifference:
          distanceDifference,
      nearDifference:
          nearDifference,
    );
  }

  // ================================================================
  // OVERALL VERDICT
  // ================================================================

  String _buildOverallVerdict({
    required double?
        worstDistance,
    required double?
        worstNear,
  }) {
    if (worstDistance ==
            null &&
        worstNear ==
            null) {
      return 'No visual acuity screening result is available.';
    }

    final worst =
        _maxNonNull([
      worstDistance,
      worstNear,
    ]);

    if (worst == null) {
      return 'No visual acuity screening result is available.';
    }

    if (worst <= 0.0) {
      return 'The completed visual acuity screening reached the normal 20/20 reference level or better.';
    }

    if (worst <= 0.10) {
      return 'The completed visual acuity screening was slightly below the normal 20/20 reference level.';
    }

    if (worst <= 0.30) {
      return 'The completed visual acuity screening showed some reduction compared with the normal 20/20 reference level.';
    }

    if (worst <= 0.50) {
      return 'The completed visual acuity screening showed a moderate reduction compared with the normal 20/20 reference level.';
    }

    return 'The completed visual acuity screening showed a noticeable reduction compared with the normal 20/20 reference level.';
  }

  // ================================================================
  // WARNING
  // ================================================================

  String _buildWarning({
    required double?
        worstDistance,
    required double?
        worstNear,
    required double?
        distanceDifference,
    required double?
        nearDifference,
  }) {
    const significantEyeDifference =
        0.20;

    final eyeDifference =
        (distanceDifference !=
                    null &&
                distanceDifference >=
                    significantEyeDifference) ||
            (nearDifference !=
                    null &&
                nearDifference >=
                    significantEyeDifference);

    if (eyeDifference) {
      return 'The right and left eyes produced noticeably different screening levels. '
          'Repeat the screening under the recommended conditions. '
          'If the difference remains, consider a comprehensive eye examination.';
    }

    final worst =
        _maxNonNull([
      worstDistance,
      worstNear,
    ]);

    if (worst != null &&
        worst >= 0.30) {
      return 'One or more screening results were below the normal 20/20 reference level. '
          'Consider repeating the screening and seeking a comprehensive eye examination '
          'if the result remains similar.';
    }

    return 'No obvious difference requiring follow-up was identified from the available screening results.';
  }

  // ================================================================
  // PLAIN LANGUAGE SUMMARY
  // ================================================================

  String
      _buildPlainLanguageSummary({
    required double?
        worstDistance,
    required double?
        worstNear,
    required double?
        distanceDifference,
    required double?
        nearDifference,
  }) {
    const eyeDifferenceThreshold =
        0.20;

    if ((distanceDifference !=
                null &&
            distanceDifference >=
                eyeDifferenceThreshold) ||
        (nearDifference !=
                null &&
            nearDifference >=
                eyeDifferenceThreshold)) {
      return 'One eye performed differently from the other during the screening. '
          'The final report shows the right-eye, left-eye, and both-eyes results '
          'separately for easier comparison.';
    }

    if (worstDistance !=
            null &&
        worstNear ==
            null) {
      if (worstDistance <=
          0.0) {
        return 'Distance vision reached the normal 20/20 screening reference level or better.';
      }

      if (worstDistance <=
          0.30) {
        return 'Distance vision was below the normal 20/20 reference in one or more tested eyes.';
      }

      return 'Distance vision showed a noticeable reduction compared with the normal 20/20 reference.';
    }

    if (worstNear !=
            null &&
        worstDistance ==
            null) {
      if (worstNear <=
          0.0) {
        return 'Near vision reached the normal screening reference level or better.';
      }

      if (worstNear <=
          0.30) {
        return 'Near vision was below the normal screening reference in one or more tested eyes.';
      }

      return 'Near vision showed a noticeable reduction during this screening.';
    }

    if (worstDistance !=
            null &&
        worstNear !=
            null) {
      final distanceGood =
          worstDistance <=
              0.0;

      final nearGood =
          worstNear <=
              0.0;

      if (distanceGood &&
          nearGood) {
        return 'Both distance and near visual acuity reached the normal screening reference level or better.';
      }

      if (!distanceGood &&
          nearGood) {
        return 'Distance visual acuity was weaker than near visual acuity in this screening.';
      }

      if (distanceGood &&
          !nearGood) {
        return 'Near visual acuity was weaker than distance visual acuity in this screening.';
      }

      return 'Both distance and near visual acuity were below the normal screening reference in one or more tested eyes.';
    }

    return 'Your screening results are available below.';
  }

  // ================================================================
  // AGE LABEL
  // ================================================================

  String _ageGroupLabel(
    int? age,
  ) {
    if (age == null) {
      return 'Adult';
    }

    if (age <= 5) {
      return 'Child under 6';
    }

    if (age <= 12) {
      return 'Child';
    }

    if (age <= 17) {
      return 'Teen';
    }

    if (age <= 39) {
      return 'Adult';
    }

    if (age <= 59) {
      return 'Adult 40–59';
    }

    return 'Older adult 60+';
  }

  // ================================================================
  // MATH HELPERS
  // ================================================================

  double? _worstLogMAR(
    List<vm.AcuityResult?>
        results,
  ) {
    double? worst;

    for (final result
        in results) {
      if (result == null) {
        continue;
      }

      final value =
          result.belowRange
              ? result.logMAR +
                  0.10
              : result.logMAR;

      if (worst == null ||
          value > worst) {
        worst = value;
      }
    }

    return worst;
  }

  double? _eyeDifference(
    vm.AcuityResult? right,
    vm.AcuityResult? left,
  ) {
    if (right == null ||
        left == null) {
      return null;
    }

    return (right.logMAR -
            left.logMAR)
        .abs();
  }

  double? _maxNonNull(
    List<double?> values,
  ) {
    double? result;

    for (final value
        in values) {
      if (value == null) {
        continue;
      }

      if (result == null ||
          value > result) {
        result = value;
      }
    }

    return result;
  }
}