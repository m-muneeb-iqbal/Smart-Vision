import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../services/yolo_services.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  CameraController? _cameraController;
  final YoloService _yoloService = YoloService();
  bool _isDetecting = false;
  List<Detection> _detections = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _yoloService.loadModel();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    setState(() {});
  }

  Future<void> _startDetection() async {
    if (_cameraController == null) return;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;

      final results = await _yoloService.detectFromCameraImage(image);
      setState(() => _detections = results);

      _isDetecting = false;
    });
  }

  Future<void> _stopDetection() async {
    await _cameraController?.stopImageStream();
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {
        final results = await _yoloService.detectFromImage(decodedImage);
        setState(() => _detections = results);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found ${results.length} objects')),
        );
      }
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("YOLOv8 Object Detection")),
      body: Column(
        children: [
          if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            Expanded(
              child: Stack(
                children: [
                  CameraPreview(_cameraController!),
                  CustomPaint(
                    painter: BoundingBoxPainter(_detections),
                    child: Container(),
                  ),
                ],
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),
          ElevatedButton(
            onPressed: _startDetection,
            child: const Text("Start Detection"),
          ),
          ElevatedButton(
            onPressed: _stopDetection,
            child: const Text("Stop Detection"),
          ),
          ElevatedButton(
            onPressed: _captureImage,
            child: const Text("Capture Image"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _detections.length,
              itemBuilder: (context, i) {
                final d = _detections[i];
                final box = d.boundingBox;

                return ListTile(
                  title: Text(
                    "${d.className} - ${(d.confidence * 100).toStringAsFixed(1)}%",
                  ),
                  subtitle: Text(
                    "x:${box.x.toStringAsFixed(1)}, y:${box.y.toStringAsFixed(1)}, w:${box.width.toStringAsFixed(1)}, h:${box.height.toStringAsFixed(1)}",
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;

  BoundingBoxPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var d in detections) {
      final box = d.boundingBox;
      final rect = Rect.fromLTWH(box.x, box.y, box.width, box.height);
      canvas.drawRect(rect, paint);

      final label =
          "${d.className} ${(d.confidence * 100).toStringAsFixed(0)}%";
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.red, fontSize: 14),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(box.x, box.y - 15));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
