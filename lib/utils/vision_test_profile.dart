import 'package:flutter/material.dart';

import '../services/display_calibration_service.dart';

enum VisionDeviceClass {
  phone,
  tablet,
  desktop,
}

class VisionTestProfile {
  const VisionTestProfile({
    required this.deviceClass,
    required this.distanceCm,
    required this.isNearTest,
  });

  final VisionDeviceClass deviceClass;
  final double distanceCm;
  final bool isNearTest;

  static VisionDeviceClass deviceClassFor(
    BuildContext context,
  ) {
    final width =
        MediaQuery.sizeOf(context).width;

    if (width < 600) {
      return VisionDeviceClass.phone;
    }

    if (width < 1024) {
      return VisionDeviceClass.tablet;
    }

    return VisionDeviceClass.desktop;
  }

  /// Distance test.
  ///
  /// largestLogMar:
  /// Standard test = 0.4 (20/50)
  /// Accessible test = 1.3 (20/400)
  factory VisionTestProfile.distance({
    required BuildContext context,
    required double largestLogMar,
  }) {
    final width =
        MediaQuery.sizeOf(context).width;

    final availableWidth =
        width * 0.88;

    final rawDistance =
        DisplayCalibrationService.instance
            .maximumDistanceForLineCm(
      availableWidthPx:
          availableWidth,
      largestLogMar:
          largestLogMar,
      lettersPerLine: 5,
      maximumDistanceCm: 300,
    );

    // Round DOWN so the line still fits.
    var roundedDistance =
        (rawDistance / 5).floor() *
            5.0;

    if (roundedDistance < 25) {
      roundedDistance = 25;
    }

    return VisionTestProfile(
      deviceClass:
          deviceClassFor(context),
      distanceCm:
          roundedDistance,
      isNearTest: false,
    );
  }

  factory VisionTestProfile.near(
    BuildContext context,
  ) {
    return VisionTestProfile(
      deviceClass:
          deviceClassFor(context),
      distanceCm: 40,
      isNearTest: true,
    );
  }

  String get deviceLabel {
    switch (deviceClass) {
      case VisionDeviceClass.phone:
        return 'Phone';

      case VisionDeviceClass.tablet:
        return 'Tablet / iPad';

      case VisionDeviceClass.desktop:
        return 'Laptop / Desktop';
    }
  }

  String get distanceLabel {
    if (distanceCm < 100) {
      final inches =
          distanceCm / 2.54;

      return '${distanceCm.round()} cm / '
          '${inches.toStringAsFixed(1)} in';
    }

    final meters =
        distanceCm / 100.0;

    final feet =
        distanceCm / 30.48;

    return '${meters.toStringAsFixed(1)} m / '
        '${feet.toStringAsFixed(1)} ft';
  }

  String get spokenDistance {
    if (distanceCm < 100) {
      return 'approximately '
          '${distanceCm.round()} centimeters';
    }

    final meters =
        distanceCm / 100.0;

    return 'approximately '
        '${meters.toStringAsFixed(1)} meters';
  }
}