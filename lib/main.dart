import 'package:flutter/material.dart';
import 'combined_camera_view.dart'; // Thay đổi để import tệp mới

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CombinedCameraView(), // Thay đổi để sử dụng CombinedCameraView
    );
  }
}
