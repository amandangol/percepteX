import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CustomCameraPreview extends StatelessWidget {
  final CameraController cameraController;

  const CustomCameraPreview({Key? key, required this.cameraController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var previewSize = cameraController.value.previewSize!;
    var screenAspectRatio = screenSize.width / screenSize.height;
    var previewAspectRatio = previewSize.height / previewSize.width;

    return OverflowBox(
      maxHeight: screenAspectRatio > previewAspectRatio
          ? screenSize.height
          : screenSize.width / previewAspectRatio,
      maxWidth: screenAspectRatio > previewAspectRatio
          ? screenSize.height * previewAspectRatio
          : screenSize.width,
      child: CameraPreview(cameraController),
    );
  }
}
