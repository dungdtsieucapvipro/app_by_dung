import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CombinedCameraView extends StatefulWidget {
  @override
  _CombinedCameraViewState createState() => _CombinedCameraViewState();
}

class _CombinedCameraViewState extends State<CombinedCameraView> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  bool isCameraFront = true; // Biến để theo dõi camera hiện tại
  FaceDetector? faceDetector;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        minFaceSize: 0.1,
      ),
    );
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    controller = CameraController(cameras![0], ResolutionPreset.high);
    await controller!.initialize();
    setState(() {});
  }

  // Thêm phương thức switchCamera
  Future<void> switchCamera() async {
    isCameraFront = !isCameraFront;
    final cameraIndex = isCameraFront ? 1 : 0; // Chuyển đổi giữa camera trước và sau
    controller = CameraController(cameras![cameraIndex], ResolutionPreset.high);
    await controller!.initialize();
    setState(() {});
  }

  Future<void> _detectFaces() async {
    if (controller != null && controller!.value.isInitialized) {
      final image = await controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final List<Face> faces = await faceDetector!.processImage(inputImage);

      for (Face face in faces) {
        // Xử lý các cảm xúc nhận diện được từ khuôn mặt ở đây
        print('Khuôn mặt đã được nhận diện!');
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Nhận diện cảm xúc'),
      ),
      body: Stack(
        children: [
          CameraPreview(controller!),  // Hiển thị CameraPreview
          Positioned(
            bottom: 20,
            left: 20,
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: switchCamera,  // Gọi phương thức switchCamera
                  child: Text("Đổi Camera"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _detectFaces,
                  child: Text("Nhận Diện Cảm Xúc"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
