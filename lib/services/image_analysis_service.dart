import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;
import 'package:perceptexx/config/app_config.dart';

class ImageAnalysisException implements Exception {
  final String message;
  final String userFriendlyMessage;
  final bool isServerError;

  ImageAnalysisException({
    required this.message,
    required this.userFriendlyMessage,
    this.isServerError = false,
  });

  @override
  String toString() => message;
}

class ImageAnalysisService {
  late final GenerativeModel _model;
  static final ImageAnalysisService _instance =
      ImageAnalysisService._internal();

  factory ImageAnalysisService() {
    return _instance;
  }

  ImageAnalysisService._internal() {
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
        throw ImageAnalysisException(
          message: 'Failed to decode image',
          userFriendlyMessage:
              'Unable to process the image. Please try again with a different image.',
        );
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
      throw ImageAnalysisException(
        message: 'Error resizing image: $e',
        userFriendlyMessage:
            'Unable to prepare the image for analysis. Please try again.',
      );
    }
  }

  Future<String> describeImage(File imageFile) async {
    try {
      await _validateImage(imageFile);

      final resizedImage = await resizeImage(imageFile, 800, 800);
      final imageBytes = await resizedImage.readAsBytes();

      final content = [
        Content.multi([
          TextPart(
              "Describe this image in detail, including any notable objects, people, text, or activities visible. Just describe, don't break it down into points."),
          DataPart(_getMimeType(imageFile.path), imageBytes),
        ])
      ];

      final response = await _model.generateContent(content).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw ImageAnalysisException(
            message: 'Request timed out',
            userFriendlyMessage:
                'The analysis is taking too long. Please try again.',
            isServerError: true,
          );
        },
      );

      await _cleanupTempFile(resizedImage);

      if (response.text != null) {
        return response.text!;
      } else {
        throw ImageAnalysisException(
          message: 'No text response received from API',
          userFriendlyMessage:
              'Unable to generate description. Please try again.',
          isServerError: true,
        );
      }
    } on GenerativeAIException catch (e) {
      throw _handleGenerativeAIException(e);
    } catch (e) {
      if (e is ImageAnalysisException) rethrow;
      throw ImageAnalysisException(
        message: 'Failed to describe image: $e',
        userFriendlyMessage:
            'Unable to analyze the image. Please try again in a moment.',
      );
    }
  }

  Future<Map<String, dynamic>> analyzeObject(File imageFile) async {
    try {
      await _validateImage(imageFile);

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
          DataPart(_getMimeType(imageFile.path), imageBytes),
        ])
      ];

      final response = await _model.generateContent(content).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw ImageAnalysisException(
            message: 'Request timed out',
            userFriendlyMessage:
                'The analysis is taking too long. Please try again.',
            isServerError: true,
          );
        },
      );

      await _cleanupTempFile(resizedImage);

      if (response.text != null) {
        return _parseJsonResponse(response.text!);
      } else {
        throw ImageAnalysisException(
          message: 'No response received from API',
          userFriendlyMessage:
              'Unable to analyze the object. Please try again.',
          isServerError: true,
        );
      }
    } on GenerativeAIException catch (e) {
      throw _handleGenerativeAIException(e);
    } catch (e) {
      if (e is ImageAnalysisException) rethrow;
      throw ImageAnalysisException(
        message: 'Failed to analyze object: $e',
        userFriendlyMessage:
            'Unable to analyze the object. Please try again in a moment.',
      );
    }
  }

  ImageAnalysisException _handleGenerativeAIException(GenerativeAIException e) {
    if (e.message.contains('503')) {
      return ImageAnalysisException(
        message: 'Server is overloaded: $e',
        userFriendlyMessage:
            'The service is currently busy. Please try again in a few moments.',
        isServerError: true,
      );
    } else if (e.message.contains('429')) {
      return ImageAnalysisException(
        message: 'Rate limit exceeded: $e',
        userFriendlyMessage:
            'Too many requests. Please wait a moment before trying again.',
        isServerError: true,
      );
    } else {
      return ImageAnalysisException(
        message: 'API Error: $e',
        userFriendlyMessage: 'Something went wrong. Please try again.',
        isServerError: true,
      );
    }
  }

  Future<void> _validateImage(File imageFile) async {
    if (!await imageFile.exists()) {
      throw ImageAnalysisException(
        message: 'Image file does not exist',
        userFriendlyMessage:
            'The image file could not be found. Please try again.',
      );
    }

    final String mimeType = _getMimeType(imageFile.path);
    if (!_isValidImageType(mimeType)) {
      throw ImageAnalysisException(
        message: 'Invalid image type: $mimeType',
        userFriendlyMessage:
            'This image format is not supported. Please use JPEG, PNG, GIF, or WebP.',
      );
    }
  }

  Future<void> _cleanupTempFile(File file) async {
    await file
        .delete()
        .catchError((e) => print('Error deleting temp file: $e'));
  }

  Map<String, dynamic> _parseJsonResponse(String jsonText) {
    try {
      final cleanJson =
          jsonText.replaceAll('```json', '').replaceAll('```', '').trim();
      return json.decode(cleanJson);
    } catch (e) {
      throw ImageAnalysisException(
        message: 'Failed to parse response: $e',
        userFriendlyMessage:
            'Unable to process the analysis results. Please try again.',
      );
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
