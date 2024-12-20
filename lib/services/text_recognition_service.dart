import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';

class TextRecognitionTTS {
  final TextRecognizer textRecognizer = TextRecognizer();
  final FlutterTts flutterTts = FlutterTts();

  Future<String?> recognizeText(CameraController cameraController) async {
    try {
      final XFile imageFile = await cameraController.takePicture();
      final InputImage inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      if (recognizedText.text.isNotEmpty) {
        await flutterTts.speak("The text says: ${recognizedText.text}");
        return recognizedText.text;
      } else {
        await flutterTts.speak("No text recognized");
        return null;
      }
    } catch (e) {
      await flutterTts.speak("Failed to recognize text");
      return null;
    }
  }

  Future<String?> recognizeTextFromFile(File imageFile) async {
    try {
      final InputImage inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      StringBuffer sb = StringBuffer();
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          sb.writeln(line.text);
        }
      }

      return sb.toString().trim();
    } catch (e) {
      print('Error recognizing text: $e');
      return null;
    }
  }

  void dispose() {
    textRecognizer.close();
  }
}
