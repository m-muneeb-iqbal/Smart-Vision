import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import './utils/permissions.dart';
import './services/yolo_services.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  List<Detection> _detections = [];
  int _currentCameraIndex = 0;
  final YoloService _yoloService = YoloService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndInitialize();
  }

  Future<void> _requestPermissionAndInitialize() async {
    final hasPermission = await PermissionHelper.requestCameraPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
    
    if (hasPermission) {
      await _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![_currentCameraIndex],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras != null && _cameras!.length > 1) {
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
      await _cameraController?.dispose();
      setState(() {
        _isCameraInitialized = false;
      });
      await _initializeCamera();
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final image = await _cameraController!.takePicture();
        
        // Process captured image for detection
        final bytes = await image.readAsBytes();
        final detections = await _yoloService.detectObjects(bytes);
        
        setState(() {
          _detections = detections;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found ${detections.length} objects')),
        );
      } catch (e) {
        print('Error capturing image: $e');
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _yoloService.dispose();
    super.dispose();
  }

  void _toggleDetection() {
    setState(() {
      _isDetecting = !_isDetecting;
      if (!_isDetecting) {
        _detections.clear();
        _cameraController?.stopImageStream();
      } else {
        _startDetection();
      }
    });
  }

  void _startDetection() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      _cameraController!.startImageStream((CameraImage image) {
        if (_isDetecting && !_isProcessing) {
          _processImage(image);
        }
      });
    }
  }

  Future<void> _processImage(CameraImage cameraImage) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final detections = await _yoloService.detectFromCameraImage(cameraImage);
      
      if (mounted && _isDetecting) {
        setState(() {
          _detections = detections;
        });
      }
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
      
      // Add delay to prevent overwhelming the processor
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: GlassmorphicContainer(
                        width: 50,
                        height: 50,
                        borderRadius: 25,
                        blur: 20,
                        alignment: Alignment.center,
                        border: 2,
                        linearGradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        borderGradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.5),
                            Colors.white.withOpacity(0.2),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      'Object Detection',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms),

              // Camera Preview
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: !_hasPermission
                        ? Container(
                            color: Colors.black,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.white, size: 64),
                                  SizedBox(height: 16),
                                  Text(
                                    'Camera permission required',
                                    style: TextStyle(color: Colors.white, fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _isCameraInitialized
                            ? Stack(
                                children: [
                                  CameraPreview(_cameraController!),
                                  if (_isDetecting)
                                    CustomPaint(
                                      painter: BoundingBoxPainter(_detections),
                                      size: Size.infinite,
                                    ),
                                  if (_isDetecting && _isProcessing)
                                    Positioned(
                                      top: 16,
                                      left: 16,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Detecting...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  // Camera controls overlay
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: GestureDetector(
                                      onTap: _switchCamera,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Icon(
                                          Icons.flip_camera_ios,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                color: Colors.black,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(color: Colors.white),
                                      SizedBox(height: 16),
                                      Text(
                                        'Initializing Camera...',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                  ),
                ),
              ).animate().scale(delay: 300.ms, duration: 800.ms),

              const SizedBox(height: 20),

              // Detection Results
              if (_detections.isNotEmpty)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassmorphicContainer(
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 20,
                      blur: 20,
                      alignment: Alignment.topLeft,
                      border: 2,
                      linearGradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderGradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.5),
                          Colors.white.withOpacity(0.2),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Detected Objects:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_detections.length}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _detections.length,
                                itemBuilder: (context, index) {
                                  final detection = _detections[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _getColorForClass(detection.classId),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            detection.className,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${(detection.confidence * 100).toInt()}%',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().slideY(begin: 1, delay: 600.ms, duration: 800.ms),

              // Control Buttons
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: _toggleDetection,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isDetecting
                                ? [Colors.red, Colors.redAccent]
                                : [Colors.green, Colors.greenAccent],
                          ),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: (_isDetecting ? Colors.red : Colors.green)
                                  .withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isDetecting ? Icons.stop : Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _captureImage,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 1, delay: 800.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForClass(int classId) {
    final colors = [
      Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple,
      Colors.cyan, Colors.pink, Colors.yellow, Colors.indigo, Colors.teal,
    ];
    return colors[classId % colors.length];
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;

  BoundingBoxPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final detection in detections) {
      final box = detection.boundingBox;
      
      // Scale bounding box to canvas size
      final rect = Rect.fromLTWH(
        box.x * size.width / 640, // Assuming input size is 640
        box.y * size.height / 640,
        box.width * size.width / 640,
        box.height * size.height / 640,
      );

      // Draw bounding box
      paint.color = _getColorForClass(detection.classId);
      canvas.drawRect(rect, paint);

      // Draw label background
      final label = '${detection.className} ${(detection.confidence * 100).toInt()}%';
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      final labelRect = Rect.fromLTWH(
        rect.left,
        rect.top - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      );

      canvas.drawRect(labelRect, Paint()..color = paint.color);
      textPainter.paint(canvas, Offset(rect.left + 4, rect.top - textPainter.height - 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  Color _getColorForClass(int classId) {
    final colors = [
      Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple,
      Colors.cyan, Colors.pink, Colors.yellow, Colors.indigo, Colors.teal,
    ];
    return colors[classId % colors.length];
  }
}