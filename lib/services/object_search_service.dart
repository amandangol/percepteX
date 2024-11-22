import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;
import 'package:perceptexx/config/app_config.dart';

class ObjectSearchService {
  late final GenerativeModel _model;
  static final ObjectSearchService _instance = ObjectSearchService._internal();

  factory ObjectSearchService() {
    return _instance;
  }

  ObjectSearchService._internal() {
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

      final resizedImage = img.copyResize(
        originalImage,
        width: maxWidth,
        height: maxHeight,
        interpolation: img.Interpolation.linear,
      );

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

  Future<Map<String, dynamic>> detectAndAnalyzeObject(File imageFile) async {
    try {
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
              "Analyze this image and provide the following in JSON format: "
              "1. main_object: The primary object or subject in the image "
              "2. description: A brief description of the object "
              "3. search_keywords: Relevant keywords for searching about this object "
              "4. suggested_queries: 3-4 specific search queries that would be helpful to learn more about this object"),
          DataPart(mimeType, imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      await resizedImage
          .delete()
          // ignore: invalid_return_type_for_catch_error
          .catchError((e) => print('Error deleting temp file: $e'));

      if (response.text != null) {
        return _parseJsonResponse(response.text!);
      } else {
        throw Exception('No response received from API');
      }
    } catch (e) {
      throw Exception('Failed to analyze object: $e');
    }
  }

  Map<String, dynamic> _parseJsonResponse(String jsonText) {
    try {
      final cleanJson =
          jsonText.replaceAll('```json', '').replaceAll('```', '').trim();
      return json.decode(cleanJson);
    } catch (e) {
      return {
        'main_object': 'Unknown object',
        'description': 'Could not analyze the image',
        'search_keywords': ['object', 'item'],
        'suggested_queries': ['What is this object?']
      };
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
