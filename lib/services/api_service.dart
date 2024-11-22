import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;
import 'package:perceptexx/config/app_config.dart';

class ApiService {
  late final GenerativeModel _model;
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _initializeModel();
  }

  void _initializeModel() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: AppConfig.apiKey,
    );
  }

  Future<File> resizeImage(File file, int maxWidth, int maxHeight) async {
    try {
      final originalImage = img.decodeImage(await file.readAsBytes());
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      final resizedImage = img.copyResize(originalImage,
          width: maxWidth,
          height: maxHeight,
          interpolation: img.Interpolation.linear);

      final tempDir = Directory.systemTemp;
      final tempPath =
          '${tempDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final resizedFile = File(tempPath)
        ..writeAsBytesSync(img.encodeJpg(resizedImage, quality: 85));

      return resizedFile;
    } catch (e) {
      throw Exception('Error resizing image: $e');
    }
  }

  Future<String> describeImage(File imageFile) async {
    try {
      // Validate file exists and is an image
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final String mimeType = _getMimeType(imageFile.path);
      if (!_isValidImageType(mimeType)) {
        throw Exception('Invalid image type: $mimeType');
      }

      final resizedImage = await resizeImage(imageFile, 800, 800);
      final imageBytes = await resizedImage.readAsBytes();

      final content = [
        Content.multi([
          TextPart(
              "Describe this image in detail, including any notable objects, people, text, or activities visible. Just describe, don't break it down into points."),
          DataPart(mimeType, imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);

      // Clean up temporary resized file
      await resizedImage
          .delete()
          // ignore: invalid_return_type_for_catch_error
          .catchError((e) => print('Error deleting temp file: $e'));

      if (response.text != null) {
        return response.text!;
      } else {
        throw Exception('No text response received from API');
      }
    } catch (e) {
      throw Exception('Failed to describe image: $e');
    }
  }

  String _getMimeType(String filepath) {
    final extension = filepath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  bool _isValidImageType(String mimeType) {
    return [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
    ].contains(mimeType);
  }
}
