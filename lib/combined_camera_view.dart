import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CombinedCameraView extends StatefulWidget {
  @override
  _CombinedCameraViewState createState() => _CombinedCameraViewState();
}

class _CombinedCameraViewState extends State<CombinedCameraView> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  bool isCameraFront = true; // Biến để theo dõi camera hiện tại
  FaceDetector? faceDetector;
  List<Rect> faceRects = []; // Danh sách các khung mặt nhận từ API

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
    controller = CameraController(cameras![isCameraFront ? 0 : 1], ResolutionPreset.high);
    await controller!.initialize();
    setState(() {});
  }

  // Thêm phương thức switchCamera
  Future<void> switchCamera() async {
    isCameraFront = !isCameraFront;  // Đảo giá trị isCameraFront
    await controller!.dispose();  // Giải phóng camera cũ trước khi khởi tạo camera mới
    controller = CameraController(cameras![isCameraFront ? 0 : 1], ResolutionPreset.high);
    await controller!.initialize();
    setState(() {});  // Cập nhật UI sau khi khởi tạo camera mới
  }

  // Phương thức gọi API DeepFace để nhận diện khuôn mặt
  Future<void> _detectFace(String imagePath) async {
    var request = http.MultipartRequest('POST', Uri.parse('http://localhost:5005/'));
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      // Làm trống danh sách các khung chữ nhật cũ
      faceRects.clear();

      // Giả định rằng API trả về danh sách các khuôn mặt với tọa độ
      for (var face in jsonResponse['faces']) {
        double x = face['x'].toDouble();
        double y = face['y'].toDouble();
        double width = face['width'].toDouble();
        double height = face['height'].toDouble();

        // Thêm tọa độ của khuôn mặt vào danh sách
        faceRects.add(Rect.fromLTWH(x, y, width, height));
      }

      // Cập nhật giao diện để hiển thị khung khuôn mặt
      setState(() {});
    } else {
      print('Error: ${response.statusCode}');
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

          // CustomPaint để vẽ khung chữ nhật
          CustomPaint(
            painter: FacePainter(faceRects),  // Vẽ các khung khuôn mặt
            child: Container(),
          ),

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
                  onPressed: () async {
                    if (controller != null && controller!.value.isInitialized) {
                      final image = await controller!.takePicture();
                      await _detectFace(image.path); // Gọi API nhận diện khuôn mặt
                    }
                  },
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

// Class để vẽ khung chữ nhật quanh khuôn mặt
class FacePainter extends CustomPainter {
  final List<Rect> faceRects;
  FacePainter(this.faceRects);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red  // Màu của khung chữ nhật
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Vẽ từng khung chữ nhật
    for (Rect rect in faceRects) {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
