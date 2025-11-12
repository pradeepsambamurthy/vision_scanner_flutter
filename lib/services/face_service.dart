import 'dart:io';

class FaceSummary {
  final int? age;
  final String? gender;
  final bool? wearingGlasses;
  FaceSummary({this.age, this.gender, this.wearingGlasses});
}

class FaceService {
  FaceService._();
  static final instance = FaceService._();

  Future<FaceSummary?> analyze(File image) async {
    // TODO: real model preprocessing/inference
    return null; // return FaceSummary(...) when you wire the model
  }
}
