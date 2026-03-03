import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ScannerInitial extends StatefulWidget {
  const ScannerInitial({super.key});

  @override
  State<ScannerInitial> createState() => _ScannerInitialState();
}

class _ScannerInitialState extends State<ScannerInitial> {
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  bool _isDetecting = false;

  FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableContours: false,
      enableLandmarks: false,
    ),
  );

  String? recognizedStudent;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(
      _cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();

    _controller!.startImageStream((image) {
      if (!_isDetecting) {
        _isDetecting = true;
        _processCameraImage(image);
      }
    });

    setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final inputImage = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);

      // if (faces.isNotEmpty) {
      //   // For simplicity, take the first detected face
      //   recognizedStudent =
      //       await _sendFaceToApi(image, faces.first.boundingBox);
      // }

      print("Faces detected: ${faces.length}");
      print(faces);

      setState(() {});
    } catch (e) {
      print("Error detecting face: $e");
    } finally {
      _isDetecting = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Scanner")),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          if (recognizedStudent != null)
            Positioned(
              bottom: 50,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black54,
                child: Text(
                  "Student: $recognizedStudent",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
