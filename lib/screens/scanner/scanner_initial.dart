import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart';
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
  late CameraDescription _currentCamera;
  CameraController? _controller;
  bool _isDetecting = false;

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
    printJobs();
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

    await _controller!.startImageStream(_processCameraImage);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    // Enrollment Flow
    // → Detect face
    // → Stop stream
    // → TakePicture
    // → Convert to base64
    // → Show dialog (enter name)
    // → API create embedding
    // → Success
    // → Wait 5s
    // → Restart stream

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

      if (faces.length == 1) {
        print("Face detected! ${faces.length}");

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
                print("Name entered: $name");

                final base64Image = base64Encode(bytes!);

                print("Base64 Image: $base64Image");

                final embedding = await createSingleEmbedding(
                  name,
                  base64Image,
                );

                print("Embedding: $embedding");

                if (embedding != null) {
                  // if (embedding['status']
                  //         .toString()
                  //         .toLowerCase()
                  //         .contains('success') ||
                  //     embedding['status'].toString().contains('ok')) {
                  //   setState(() {
                  //     streamCaption = 'Embedding created! Next student?';
                  //   });
                  // } else {
                  //   setState(() {
                  //     streamCaption = 'Failed to create embedding!';
                  //   });
                  // }
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

        await _controller?.startImageStream(_processCameraImage);
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
    await _controller!.startImageStream(_processCameraImage);
    setState(() {});
  }

  Future<Response> post(String endpoint, Map<String, dynamic>? body) async {
    print('post endpoint: $endpoint');
    print('post body: $body');
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final response = await Client()
        .post(
      // Uri.parse('https://face-attendance-api-fkz4.onrender.com/$endpoint'),
      Uri.parse('http://159.89.197.111:5000/$endpoint'),
      headers: headers,
      body: body != null ? json.encode(body) : null,
    )
        .timeout(Duration(seconds: 30), onTimeout: () {
      throw Exception('Request timed out after 30 seconds');
    });
    print('post response: $response');
    if (response.statusCode == 200) {
      return response;
    } else {
      Map<String, dynamic> responseBody = json.decode(response.body);
      print('error response body: ${response.body}');
      // throw Exception('API Error: ${response.statusCode} - ${response.body}');
      throw Exception(responseBody['errors'] != null
          ? responseBody['errors']['message'][0]
          : responseBody['message'] ??
              'API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> printJobs() async {
    final response = await Client().get(
      // Uri.parse('https://face-attendance-api-fkz4.onrender.com/list-jobs'),
      Uri.parse('http://159.89.197.111:5000/list-jobs'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jobs = jsonDecode(response.body) as List<dynamic>;
      for (var job in jobs) {
        String jobId = job['job_id'];
        String status = job['status'];
        print("Job $jobId - ${job['name']}: ${job['status']}");
      }
    } else {
      print("Failed to fetch jobs: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>?> createSingleEmbedding(
    String name,
    String imageBase64,
  ) async {
    String createSingleEmbeddingUrl = 'register-student';

    Response response = await post(createSingleEmbeddingUrl, {
      "name": name,
      "image": imageBase64,
    });

    print('createSingleEmbedding response: $response');
    var decodedBody = utf8.decode(response.bodyBytes);
    var result = json.decode(decodedBody);
    var statusCode = response.statusCode;

    print('createSingleEmbedding statusCode: $statusCode');
    print('createSingleEmbedding result: $result');

    return result;
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
        leading: BackButton(
            color: Colors.white,
            onPressed: () {
              printJobs();
              Navigator.pop(context);
            }),
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
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        recognizedStudent ?? '',
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
