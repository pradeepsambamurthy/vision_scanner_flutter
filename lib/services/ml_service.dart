import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

/// Minimal helpers to run .tflite models on an eye image.
/// IMPORTANT: Set the correct [inputShape] and [meanStd] for YOUR models.
class MLService {
  /// Generic runner for an image-classification style model.
  static Future<List<double>> _runModelOnImage({
    required String modelAsset, // e.g., 'models/dr_mobilenetv2_fp16.tflite'
    required String imagePath, // file path from camera/gallery
    required List<int> inputShape, // e.g., [1, 224, 224, 3]
    required List<double> meanStd, // e.g., [127.5, 127.5] or [0.0, 255.0]
  }) async {
    final interpreter = await tfl.Interpreter.fromAsset(modelAsset);

    final h = inputShape[1], w = inputShape[2];

    // Decode and resize
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes)!;
    final resized = img.copyResize(decoded, height: h, width: w);

    // Build input tensor [1, H, W, 3] using the Pixel API (image v4)
    final mean = meanStd[0], std = meanStd[1]; // (value - mean) / std
    final input = List.generate(
      1,
      (_) => List.generate(
        h,
        (y) => List.generate(w, (x) {
          final px = resized.getPixel(x, y); // img.Pixel
          final r = px.r.toDouble();
          final g = px.g.toDouble();
          final b = px.b.toDouble();
          return [(r - mean) / std, (g - mean) / std, (b - mean) / std];
        }),
      ),
    );

    // Prepare output buffer based on output tensor 0 shape
    final outTensor = interpreter.getOutputTensor(0);
    final outShape = outTensor.shape; // e.g., [1, 5]
    final out = _zeros(outShape);

    interpreter.run(input, out);

    // Flatten to List<double>
    return _flatten(out).cast<double>();
  }

  /// Diabetic Retinopathy classifier (5 classes) — adjust to your model.
  static Future<Map<String, dynamic>> runDR(String imagePath) async {
    // TODO: set YOUR model’s true input shape & scaling
    final probs = await _runModelOnImage(
      modelAsset: 'models/dr_mobilenetv2_fp16.tflite',
      imagePath: imagePath,
      inputShape: [1, 224, 224, 3], // <-- confirm
      meanStd: [127.5, 127.5], // <-- confirm ([-1,1] scaling)
    );

    // Replace with your own labels if different
    final labels = ['No DR', 'Mild', 'Moderate', 'Severe', 'Proliferative DR'];

    var maxI = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[maxI]) maxI = i;
    }
    return {
      'label': labels[maxI],
      'index': maxI,
      'confidence': probs[maxI],
      'probs': probs,
    };
  }

  /// Glasses yes/no classifier (binary) — adjust to your model.
  static Future<Map<String, dynamic>> runGlasses(String imagePath) async {
    final probs = await _runModelOnImage(
      modelAsset: 'models/glasses_classifier.tflite',
      imagePath: imagePath,
      inputShape: [1, 224, 224, 3], // <-- confirm
      meanStd: [127.5, 127.5], // <-- confirm
    );

    // Assume output [no, yes] OR single-logit
    bool hasGlasses;
    double conf;
    if (probs.length == 2) {
      hasGlasses = probs[1] >= probs[0];
      conf = hasGlasses ? probs[1] : probs[0];
    } else {
      hasGlasses = probs.first >= 0.5;
      conf = probs.first;
    }
    return {'glasses': hasGlasses, 'confidence': conf};
  }

  /// Age/Gender head — replace with your model’s exact decoding.
  static Future<Map<String, dynamic>> runAgeGender(String imagePath) async {
    final probs = await _runModelOnImage(
      modelAsset: 'models/age_gender.tflite',
      imagePath: imagePath,
      inputShape: [1, 224, 224, 3], // <-- confirm
      meanStd: [127.5, 127.5], // <-- confirm
    );

    // Placeholder decode: replace with your model’s output schema
    final gender = (probs.isNotEmpty && probs.first > 0.5) ? 'female' : 'male';
    final age = 30; // TODO: compute from model outputs if supported
    return {'age': age, 'gender': gender, 'raw': probs};
  }

  // -------- helpers --------
  static List _zeros(List<int> shape) {
    List build(int dim) {
      if (dim == shape.length - 1) return List.filled(shape[dim], 0.0);
      return List.generate(shape[dim], (_) => build(dim + 1));
    }

    return build(0);
  }

  static List _flatten(dynamic x) {
    if (x is! List) return [x];
    return x.expand((e) => _flatten(e)).toList();
  }
}
