import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mykoku_attendance/utils/custom_dialog.dart';
import 'package:mykoku_attendance/widgets/face_boundbox.dart';

class ScannerInitial extends StatefulWidget {
  const ScannerInitial({super.key});

  @override
  State<ScannerInitial> createState() => _ScannerInitialState();
}

class _ScannerInitialState extends State<ScannerInitial> {
  CustomDialog customDialog = CustomDialog();
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  bool _isDetecting = false;

  FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: true,
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
      _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      ),
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();

    await _controller!.startImageStream(_processCameraImage);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final rotation = _getImageRotation();

      final inputImage = InputImage.fromBytes(
        bytes: _concatenatePlanes(image.planes),
        metadata: InputImageMetadata(
          size: Size(
            image.width.toDouble(),
            image.height.toDouble(),
          ),
          rotation: rotation,
          format: _getImageFormat(image),
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      print("${faces.length} Faces detected: $faces");

      if (faces.isNotEmpty) {
        print("Face detected! ${faces.length}");

        await _controller?.stopImageStream();

        customDialog.snackbarMessage(context, "Face detected!");

        // TODO: call your API here

        await Future.delayed(const Duration(seconds: 5));

        await _controller?.startImageStream(_processCameraImage);
      }
    } catch (e) {
      print("Face detection error: $e");
    } finally {
      _isDetecting = false;
    }
  }

  InputImageRotation _getImageRotation() {
    final sensorOrientation = _controller!.description.sensorOrientation;

    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  InputImageFormat _getImageFormat(CameraImage image) {
    // YUV to nv21 in Android and to bgra8888 in IOS
    if (Platform.isAndroid) {
      return InputImageFormat.nv21;
    } else {
      return InputImageFormat.bgra8888;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        title: const Text(
          'Attendance Scanner',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            onPressed: () async {
              // TODO: add camera flip logic here
              print("Camera flip pressed");
            },
          ),
        ],
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CameraPreview(_controller!),
              Positioned(
                top: 64,
                child: CustomPaint(
                  painter: FaceBoundBoxPainter(
                    color: Colors.greenAccent,
                    strokeWidth: 6,
                    cornerLength: 28,
                  ),
                  size: Size(MediaQuery.of(context).size.width * 0.8,
                      MediaQuery.of(context).size.width),
                ),
              ),
              Positioned(
                bottom: 48,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.black54,
                  child: Column(
                    children: [
                      Text(
                        "Face detected!",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: save student face
                          print("Save student face");
                        },
                        child: const Text("Upload Face"),
                      ),
                      IconButton(
                        icon: const Icon(Icons.pause, color: Colors.white),
                        onPressed: () {
                          // TODO: pause stream
                          print("pause stream");
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
