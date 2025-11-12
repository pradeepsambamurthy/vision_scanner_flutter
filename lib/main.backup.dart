import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

void main() => runApp(const EyeSightApp());

class EyeSightApp extends StatelessWidget {
  const EyeSightApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'AI EyeSight',
      home: AnalyzerPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AnalyzerPage extends StatefulWidget {
  const AnalyzerPage({super.key});
  @override
  State<AnalyzerPage> createState() => _AnalyzerPageState();
}

class _AnalyzerPageState extends State<AnalyzerPage> {
  tfl.Interpreter? _interpreter;
  List<String> _labels = [];
  Uint8List? _imgBytes;
  String? _result;
  bool _busy = false;

  // Make sure this matches your training input size
  static const int inputSize = 224;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      // IMPORTANT: paths must include "assets/"
      _interpreter = await tfl.Interpreter.fromAsset(
          'assets/model/dr_mobilenetv2_fp16.tflite');
      // Some builds auto-allocate; this is safe either way
      _interpreter!.allocateTensors();

      _labels = (await rootBundle
              .loadString('assets/model/labels.txt'))
          .trim()
          .split('\n');
      setState(() => _result = 'Model ready');
    } catch (e) {
      setState(() => _result = 'Model load error: $e');
    }
  }

  Future<void> _pick(ImageSource src) async {
    final picked = await ImagePicker()
        .pickImage(source: src, maxWidth: 2048, maxHeight: 2048);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imgBytes = bytes;
      _result = null;
    });
    await _infer(bytes);
  }

  /// Decode -> resize -> RGB float (0..1) -> pack into [1,H,W,3]
  List _preprocess4D(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Decode failed');
    }
    final resized =
        img.copyResize(decoded, width: inputSize, height: inputSize);

    // Get raw bytes in RGB order
    final rgbBytes = resized.getBytes(order: img.ChannelOrder.rgb);

    // Pack into [1, H, W, 3] as doubles (TFLite Flutter accepts num/double)
    int idx = 0;
    final batch = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final r = rgbBytes[idx++] / 255.0;
            final g = rgbBytes[idx++] / 255.0;
            final b = rgbBytes[idx++] / 255.0;
            return [r, g, b];
          },
        ),
      ),
    );
    return batch;
  }

  Future<void> _infer(Uint8List imgBytes) async {
    if (_interpreter == null) {
      setState(() => _result = 'Interpreter not ready');
      return;
    }
    setState(() => _busy = true);
    try {
      final input4d = _preprocess4D(imgBytes);

      // Output shape [1, numClasses]
      final numClasses = _labels.isEmpty ? 5 : _labels.length;
      final output = List.generate(1, (_) => List.filled(numClasses, 0.0));

      _interpreter!.run(input4d, output);

      // Extract probabilities
      final probs = List<double>.from(
          (output[0] as List).map((e) => (e as num).toDouble()));

      // Argmax
      int best = 0;
      double bestP = probs[0];
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > bestP) {
          best = i;
          bestP = probs[i];
        }
      }
      final label =
          (best >= 0 && best < _labels.length) ? _labels[best] : 'Class $best';

      final details = List.generate(
              probs.length,
              (i) =>
                  '${i < _labels.length ? _labels[i] : "C$i"}: ${(probs[i] * 100).toStringAsFixed(1)}%')
          .join('   ');

      setState(() {
        _result = '$label  (${(bestP * 100).toStringAsFixed(1)}%)\n$details';
      });
    } catch (e) {
      setState(() => _result = 'Inference error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _interpreter != null && !_busy;
    return Scaffold(
      appBar: AppBar(title: const Text('AI EyeSight (Demo)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _imgBytes == null
                  ? const Center(child: Text('Pick or capture a retinal photo.'))
                  : Image.memory(_imgBytes!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),
            if (_result != null)
              Text(
                _result!,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: ready ? () => _pick(ImageSource.gallery) : null,
                  icon: const Icon(Icons.photo),
                  label: const Text('Gallery'),
                ),
                ElevatedButton.icon(
                  onPressed: ready ? () => _pick(ImageSource.camera) : null,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Educational demo only — not medical advice.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
