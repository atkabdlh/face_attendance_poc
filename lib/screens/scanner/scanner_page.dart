import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:face_attendance_poc/models/deepmin_result_model.dart';
import 'package:face_attendance_poc/services/repositories/deepmin_repositories.dart';
import 'package:face_attendance_poc/utils/conversions.dart';
import 'package:face_attendance_poc/utils/custom_dialog.dart';
import 'package:face_attendance_poc/widgets/face_boundbox.dart';

enum ScannerMode {
  enrollment,
  recognition,
}
// ENROLLMENT FLOW
// Start Camera Stream
// Detect face
// Stop stream
// TakePicture
// Convert image → base64
// Show dialog → enter name
// Generate embedding
// Save embedding + student
// Show success
// Wait 5s
// Restart stream

// RECOGNITION FLOW
// Start Camera Stream
// Detect face
// Capture frame
// Convert → base64
// Generate attendance embedding
// Find closest match
// Show student name
// Mark attendance
// Show success
// Cooldown (3–5s)
// Continue scanning

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, required this.mode});

  final ScannerMode mode;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CustomDialog customDialog = CustomDialog();
  late List<CameraDescription> _cameras;
  late CameraDescription _currentCamera;
  CameraController? _controller;
  bool _isDetecting = false;

  DeepminRepository deepminRepository = DeepminRepository();

  FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableLandmarks: false,
    ),
  );

  String? streamCaption;
  String? recognizedStudent;
  bool _isStreamPaused = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _currentCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(
      _currentCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();

    if (widget.mode == ScannerMode.enrollment) {
      await _controller!.startImageStream(_enrollmentProcess);
    } else if (widget.mode == ScannerMode.recognition) {
      await _controller!.startImageStream(_recognitionProcess);
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _enrollmentProcess(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final inputImage = InputImage.fromBytes(
        bytes: concatenatePlanes(image.planes),
        metadata: InputImageMetadata(
          size: Size(
            image.width.toDouble(),
            image.height.toDouble(),
          ),
          rotation: _getImageRotation(),
          format: Platform.isAndroid
              ? InputImageFormat.nv21
              : InputImageFormat.bgra8888,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      print("${faces.length} Faces detected: $faces");

      if (faces.length == 1) {
        await _controller?.stopImageStream();

        setState(() {
          streamCaption = 'Hold still and look at the camera';
        });

        await Future.delayed(const Duration(seconds: 2));

        setState(() {
          streamCaption = 'Taking a picture...';
        });

        final XFile? file = await _controller?.takePicture();
        final Uint8List? bytes = await file?.readAsBytes();

        if (bytes == null) {
          setState(() {
            streamCaption = 'Failed to read picture bytes, trying again...';
          });
        } else {
          if (file != null) {
            setState(() {
              streamCaption = 'Picture taken! Creating embedding...';
            });
            if (mounted) {
              final name = await customDialog.nameModalDialog(context, file);
              if (name != null) {
                final base64Image = base64Encode(bytes);

                DeepminResultModel result =
                    await deepminRepository.registerFace(name, base64Image);

                final embedding = result.data?['embedding'];

                print("Embedding: $embedding");

                if (result.status == DeepminResultStatus.success) {
                  setState(() {
                    streamCaption = 'Embedding created! Next student?';
                  });
                } else {
                  setState(() {
                    streamCaption = 'Failed to create embedding!';
                  });
                }
              }
            }
          } else {
            setState(() {
              streamCaption = 'Failed to save picture! Try again.';
            });
          }
        }

        await Future.delayed(const Duration(seconds: 3));

        await _controller?.startImageStream(_enrollmentProcess);
      } else if (faces.length > 1) {
        setState(() {
          streamCaption = 'Multiple faces detected! Please wait for your turn.';
        });
      } else {
        setState(() {
          streamCaption = 'No face detected! Please try again.';
        });
      }
    } catch (e) {
      print("Face detection error: $e");
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _recognitionProcess(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final inputImage = InputImage.fromBytes(
        bytes: concatenatePlanes(image.planes),
        metadata: InputImageMetadata(
          size: Size(
            image.width.toDouble(),
            image.height.toDouble(),
          ),
          rotation: _getImageRotation(),
          format: Platform.isAndroid
              ? InputImageFormat.nv21
              : InputImageFormat.bgra8888,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      print("${faces.length} Faces detected: $faces");

      if (faces.length == 1) {
        await _controller?.stopImageStream();

        setState(() {
          streamCaption = 'Hold still and look at the camera';
        });

        await Future.delayed(const Duration(milliseconds: 500));

        final XFile? file = await _controller?.takePicture();
        final Uint8List? bytes = await file?.readAsBytes();

        if (bytes == null) {
          setState(() {
            streamCaption = 'Failed to read picture bytes, trying again...';
          });
        } else {
          if (file != null) {
            setState(() {
              streamCaption = 'Finding matches...';
            });
            final base64Image = base64Encode(bytes);

            DeepminResultModel result =
                await deepminRepository.recognizeFace(base64Image);
            print('deepminrepo recognizeFace result: $result');
            final jobId = result.jobId;

            if (jobId != null) {
              setState(() {
                streamCaption = 'Loading match result...';
              });

              await Future.delayed(const Duration(seconds: 2));

              final jobResult = await deepminRepository.getJobResult(jobId);

              final matchName = jobResult.matchName;

              print("matchName: $matchName");

              if (jobResult.status == DeepminResultStatus.success) {
                setState(() {
                  streamCaption = 'Match found! Upload and Next Student?';
                  recognizedStudent = matchName;
                });
              } else {
                setState(() {
                  streamCaption = 'Failed to recognize face!';
                });
              }
            }
          } else {
            setState(() {
              streamCaption = 'Failed to find match! Try again.';
            });
          }
        }
      } else if (faces.length > 1) {
        setState(() {
          streamCaption = 'Multiple faces detected! Please wait for your turn.';
        });
      } else {
        setState(() {
          streamCaption = 'No face detected! Please try again.';
        });
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

  Future<void> switchCamera() async {
    await _controller?.dispose();
    _currentCamera =
        _currentCamera == _cameras.first ? _cameras.last : _cameras.first;
    _controller = CameraController(
      _currentCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _controller!.initialize();

    if (widget.mode == ScannerMode.enrollment) {
      await _controller!.startImageStream(_enrollmentProcess);
    } else if (widget.mode == ScannerMode.recognition) {
      await _controller!.startImageStream(_recognitionProcess);
    }
    setState(() {});
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
              await switchCamera();
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
                bottom: 32,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  height: MediaQuery.of(context).size.height * 0.2,
                  width: MediaQuery.of(context).size.width * 0.9,
                  color: Colors.black54,
                  child: Column(
                    children: [
                      Text(
                        streamCaption ?? '',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      if (widget.mode == ScannerMode.recognition) ...[
                        Text(
                          recognizedStudent ?? '',
                          style: const TextStyle(
                              color: Colors.greenAccent, fontSize: 24),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _controller?.startImageStream(_recognitionProcess);
                          },
                          child: const Text("Upload Attendance"),
                        ),
                      ],
                      IconButton(
                        icon: Icon(
                            _isStreamPaused ? Icons.play_arrow : Icons.pause,
                            color: Colors.white),
                        onPressed: () {
                          // TODO: pause stream
                          _controller?.stopImageStream();
                          setState(() {
                            _isStreamPaused = !_isStreamPaused;
                            _isDetecting = false;
                            streamCaption = 'Stream Paused';
                          });
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
