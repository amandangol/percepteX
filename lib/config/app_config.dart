import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String? _apiKey;

  static String get apiKey {
    if (_apiKey == null) {
      throw StateError('AppConfig must be initialized before accessing apiKey');
    }
    return _apiKey!;
  }

  static Future<void> initialize() async {
    try {
      // Load environment variables from .env file
      await dotenv.load(fileName: ".env");

      // Get API key from environment variables
      _apiKey = _getEnvVariable('GEMINI_API_KEY');
    } catch (e) {
      throw Exception('Failed to initialize AppConfig: $e');
    }
  }

  static String _getEnvVariable(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Environment variable $key not found');
    }
    return value;
  }
}
