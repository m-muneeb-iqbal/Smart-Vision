import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';

class YoloService {
  static const String modelPath = 'assets/models/yolov8m.tflite';
  static const String labelsPath = 'assets/models/yolov8_labels.txt';
  static const double confidenceThreshold = 0.25;
  static const double iouThreshold = 0.45; // for NMS
  static const int inputSize = 640;

  late Interpreter _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;
  final Random _random = Random();

  Future<void> loadModel() async {
    try {
      // Load labels
      final labelsData = await rootBundle.loadString(labelsPath);
      _labels = labelsData.split('\n').where((e) => e.isNotEmpty).toList();

      // Load interpreter
      _interpreter = await Interpreter.fromAsset(
        modelPath,
        options: InterpreterOptions()..threads = 4,
      );
      _isModelLoaded = true;
      print(
        "YOLOv8 TFLite model loaded successfully with ${_labels.length} labels",
      );
    } catch (e) {
      print("Error loading model: $e");
      _isModelLoaded = false;
    }
  }

  // Convert CameraImage to img.Image
  img.Image _convertCameraImage(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      // Android
      final int width = cameraImage.width;
      final int height = cameraImage.height;
      final img.Image imgBuffer = img.Image(width: width, height: height);

      final planeY = cameraImage.planes[0];
      final planeU = cameraImage.planes[1];
      final planeV = cameraImage.planes[2];

      final bytesY = planeY.bytes;
      final bytesU = planeU.bytes;
      final bytesV = planeV.bytes;

      final int strideY = planeY.bytesPerRow;
      final int strideU = planeU.bytesPerRow;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int uvIndex = (y ~/ 2) * strideU + (x ~/ 2);
          final int yValue = bytesY[y * strideY + x];
          final int uValue = bytesU[uvIndex];
          final int vValue = bytesV[uvIndex];

          final double yf = yValue.toDouble();
          final double uf = uValue.toDouble() - 128;
          final double vf = vValue.toDouble() - 128;

          int r = (yf + 1.370705 * vf).round();
          int g = (yf - 0.337633 * uf - 0.698001 * vf).round();
          int b = (yf + 1.732446 * uf).round();

          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          imgBuffer.setPixelRgba(x, y, r, g, b, 255);
        }
      }
      return imgBuffer;
    } else {
      // iOS BGRA
      final plane = cameraImage.planes[0];
      return img.Image.fromBytes(
        width: cameraImage.width,
        height: cameraImage.height,
        bytes: plane.bytes.buffer,
        order: img.ChannelOrder.bgra,
      );
    }
  }

  // Resize & normalize image to Float32List
  Float32List _preprocess(img.Image image) {
    final resized = img.copyResize(image, width: 640, height: 640);

    final input = _imageToByteList(resized); // returns [1,640,640,3]
    int index = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y); // Pixel object
        input[index++] = pixel.r / 255.0;
        input[index++] = pixel.g / 255.0;
        input[index++] = pixel.b / 255.0;
      }
    }

    return input;
  }

  Future<List<Detection>> detectFromImage(img.Image image) async {
    if (!_isModelLoaded) await loadModel();
    if (!_isModelLoaded) return [];

    final Float32List input = _preprocess(image);

    final List output = List.generate(1, (_) => List.filled(25200 * 85, 0.0));
    _interpreter.run(input.reshape([1, inputSize, inputSize, 3]), output);

    final List<Detection> detections = _postProcess(output[0]);
    return detections;
  }

  // Run inference
  Future<List<Detection>> detectFromCameraImage(CameraImage cameraImage) async {
    if (!_isModelLoaded) await loadModel();
    if (!_isModelLoaded) return [];

    try {
      final img.Image image = _convertCameraImage(cameraImage);
      final Float32List input = _preprocess(image);

      final List output = List.generate(1, (_) => List.filled(25200 * 85, 0.0));
      // 25200 = YOLOv8m output (depends on model), 85 = 4 bbox + 1 obj conf + 80 classes

      _interpreter.run(input.reshape([1, inputSize, inputSize, 3]), output);

      final List<Detection> detections = _postProcess(output[0]);
      return detections;
    } catch (e) {
      print("Detection failed: $e");
      return [];
    }
  }

  // Postprocessing (NMS)
  List<Detection> _postProcess(List<double> rawOutput) {
    final List<Detection> boxes = [];

    for (int i = 0; i < rawOutput.length ~/ 85; i++) {
      final double conf = rawOutput[i * 85 + 4];
      if (conf < confidenceThreshold) continue;

      final List<double> classProbs = rawOutput.sublist(
        i * 85 + 5,
        i * 85 + 85,
      );
      final double maxClassProb = classProbs.reduce(max);
      final int classId = classProbs.indexOf(maxClassProb);

      if (conf * maxClassProb < confidenceThreshold) continue;

      final double cx = rawOutput[i * 85 + 0];
      final double cy = rawOutput[i * 85 + 1];
      final double w = rawOutput[i * 85 + 2];
      final double h = rawOutput[i * 85 + 3];

      boxes.add(
        Detection(
          classId: classId,
          className: _labels[classId],
          confidence: conf * maxClassProb,
          boundingBox: BoundingBox(
            x: cx - w / 2,
            y: cy - h / 2,
            width: w,
            height: h,
          ),
        ),
      );
    }

    return _nonMaxSuppression(boxes, iouThreshold);
  }

  // Simple NMS
  List<Detection> _nonMaxSuppression(
    List<Detection> boxes,
    double iouThreshold,
  ) {
    boxes.sort((a, b) => b.confidence.compareTo(a.confidence));
    final List<Detection> selected = [];

    for (final box in boxes) {
      bool keep = true;
      for (final sel in selected) {
        if (_iou(box.boundingBox, sel.boundingBox) > iouThreshold) {
          keep = false;
          break;
        }
      }
      if (keep) selected.add(box);
    }
    return selected;
  }

  double _iou(BoundingBox a, BoundingBox b) {
    final double x1 = max(a.x, b.x);
    final double y1 = max(a.y, b.y);
    final double x2 = min(a.x + a.width, b.x + b.width);
    final double y2 = min(a.y + a.height, b.y + b.height);

    final double interArea = max(0, x2 - x1) * max(0, y2 - y1);
    final double unionArea =
        a.width * a.height + b.width * b.height - interArea;

    return interArea / unionArea;
  }

  void dispose() {
    _interpreter.close();
  }
}

class Detection {
  final int classId;
  final String className;
  final double confidence;
  final BoundingBox boundingBox;

  Detection({
    required this.classId,
    required this.className,
    required this.confidence,
    required this.boundingBox,
  });
}

class BoundingBox {
  final double x, y, width, height;
  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}
