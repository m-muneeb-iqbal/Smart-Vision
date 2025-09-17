import 'dart:math';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

class YoloService {
  static const String labelsPath = 'assets/models/yolov8_labels.txt';
  static const double confidenceThreshold = 0.25;
  
  List<String> _labels = [];
  bool _isModelLoaded = false;
  final Random _random = Random();

  Future<void> loadModel() async {
    try {
      await _loadLabels();
      _isModelLoaded = true;
      print('Mock YOLOv8 model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      _isModelLoaded = false;
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString(labelsPath);
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      print('Loaded ${_labels.length} labels');
    } catch (e) {
      print('Error loading labels: $e');
      _labels = _getDefaultLabels();
    }
  }

  Future<List<Detection>> detectObjects(Uint8List imageBytes) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    if (!_isModelLoaded) {
      return [];
    }

    // Mock detection - simulate finding random objects
    await Future.delayed(const Duration(milliseconds: 100));
    
    List<Detection> detections = [];
    int numDetections = _random.nextInt(4) + 1; // 1-4 detections
    
    for (int i = 0; i < numDetections; i++) {
      int classId = _random.nextInt(_labels.length);
      double confidence = 0.5 + _random.nextDouble() * 0.5; // 0.5-1.0
      
      detections.add(Detection(
        classId: classId,
        className: _labels[classId],
        confidence: confidence,
        boundingBox: BoundingBox(
          x: _random.nextDouble() * 400,
          y: _random.nextDouble() * 300,
          width: 50 + _random.nextDouble() * 100,
          height: 50 + _random.nextDouble() * 100,
        ),
      ));
    }
    
    return detections;
  }

  Future<List<Detection>> detectFromCameraImage(CameraImage cameraImage) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    if (!_isModelLoaded) {
      return [];
    }

    // Mock detection for camera stream
    await Future.delayed(const Duration(milliseconds: 50));
    
    List<Detection> detections = [];
    
    // Simulate common objects that might be detected
    List<String> commonObjects = ['person', 'chair', 'laptop', 'cell phone', 'cup', 'book'];
    int numDetections = _random.nextInt(3) + 1;
    
    for (int i = 0; i < numDetections; i++) {
      String className = commonObjects[_random.nextInt(commonObjects.length)];
      int classId = _labels.indexOf(className);
      if (classId == -1) classId = 0;
      
      double confidence = 0.6 + _random.nextDouble() * 0.4;
      
      detections.add(Detection(
        classId: classId,
        className: className,
        confidence: confidence,
        boundingBox: BoundingBox(
          x: _random.nextDouble() * 500,
          y: _random.nextDouble() * 400,
          width: 80 + _random.nextDouble() * 120,
          height: 80 + _random.nextDouble() * 120,
        ),
      ));
    }
    
    return detections;
  }

  List<String> _getDefaultLabels() {
    return [
      'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck',
      'boat', 'traffic light', 'fire hydrant', 'stop sign', 'parking meter', 'bench',
      'bird', 'cat', 'dog', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra',
      'giraffe', 'backpack', 'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee',
      'skis', 'snowboard', 'sports ball', 'kite', 'baseball bat', 'baseball glove',
      'skateboard', 'surfboard', 'tennis racket', 'bottle', 'wine glass', 'cup',
      'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple', 'sandwich', 'orange',
      'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair', 'couch',
      'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse',
      'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink',
      'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear', 'hair drier',
      'toothbrush'
    ];
  }

  void dispose() {
    // Mock disposal
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
  final double x;
  final double y;
  final double width;
  final double height;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}