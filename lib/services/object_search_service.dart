// lib/services/object_search_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:perceptexx/config/app_config.dart';

class ObjectSearchResult {
  final String mainObject;
  final String description;
  final List<String> searchKeywords;
  final List<String> suggestedQueries;
  final String voiceDescription;

  ObjectSearchResult({
    required this.mainObject,
    required this.description,
    required this.searchKeywords,
    required this.suggestedQueries,
    required this.voiceDescription,
  });

  factory ObjectSearchResult.fromJson(Map<String, dynamic> json) {
    return ObjectSearchResult(
      mainObject: json['main_object'] ?? 'Unknown object',
      description: json['description'] ?? 'No description available',
      searchKeywords: List<String>.from(json['search_keywords'] ?? []),
      suggestedQueries: List<String>.from(json['suggested_queries'] ?? []),
      voiceDescription: json['voice_description'] ?? 'No description available',
    );
  }
}

class ObjectSearchService {
  final GenerativeModel _model;
  final FlutterTts _flutterTts;
  bool _isSpeaking = false;

  ObjectSearchService()
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: AppConfig.apiKey,
        ),
        _flutterTts = FlutterTts() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<File> _resizeImage(File file) async {
    try {
      final originalImage = img.decodeImage(await file.readAsBytes());
      if (originalImage == null) throw Exception('Failed to decode image');

      final resizedImage = img.copyResize(
        originalImage,
        width: 800,
        height: 800,
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

  Future<ObjectSearchResult> analyzeImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final resizedImage = await _resizeImage(imageFile);
      final imageBytes = await resizedImage.readAsBytes();
      final mimeType = 'image/jpeg';

      final prompt = '''
        Analyze this image and provide the following information in JSON format:
        {
          "main_object": "Primary object or subject in the image",
          "description": "Detailed description of what you see",
          "search_keywords": ["relevant", "search", "keywords"],
          "suggested_queries": ["3-4 specific", "search queries", "for more info"],
          "voice_description": "A natural, conversational description for voice output"
        }
      ''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      await resizedImage.delete();

      if (response.text == null) {
        throw Exception('No response received from API');
      }

      final jsonResponse = _parseJsonResponse(response.text!);
      return ObjectSearchResult.fromJson(jsonResponse);
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
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
        'suggested_queries': ['What is this object?'],
        'voice_description': 'I could not properly analyze this image.',
      };
    }
  }

  Future<void> speakDescription(String text) async {
    if (_isSpeaking) {
      await stopSpeaking();
    }
    _isSpeaking = true;
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    _isSpeaking = false;
    await _flutterTts.stop();
  }

  Future<void> pauseSpeaking() async {
    _isSpeaking = false;
    await _flutterTts.pause();
  }

  Future<void> searchGoogle(String query) async {
    final Uri url =
        Uri.parse('https://www.google.com/search?q=${Uri.encodeFull(query)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch search');
    }
  }

  void dispose() {
    _flutterTts.stop();
  }
}
