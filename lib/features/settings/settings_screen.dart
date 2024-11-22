import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _geminiApiKeyController = TextEditingController();

  // TTS-related variables
  FlutterTts? _flutterTts;
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;
  String _selectedLanguage = 'en-US';

  bool _isGeminiKeyObscured = true;
  bool _isLoading = false;
  bool _isTTSInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAll();
  }

  Future<void> _initializeAll() async {
    try {
      // Initialize TTS first
      await _initializeTTS();

      // Then load saved settings
      await _loadSavedSettings();
    } catch (e) {
      _showErrorDialog('Initialization failed: $e');
    }
  }

  Future<void> _initializeTTS() async {
    try {
      _flutterTts = FlutterTts();

      // Add error handling for TTS initialization
      if (_flutterTts == null) {
        throw Exception('Failed to initialize TTS');
      }

      // Configure TTS with default settings
      await _configureTTS();

      setState(() {
        _isTTSInitialized = true;
      });
    } catch (e) {
      print('TTS Initialization Error: $e');
      setState(() {
        _isTTSInitialized = false;
      });
      _showErrorDialog('Text-to-Speech initialization failed: $e');
    }
  }

  Future<void> _configureTTS() async {
    if (_flutterTts == null) return;

    try {
      await _flutterTts!.setLanguage(_selectedLanguage);
      await _flutterTts!.setPitch(_pitch);
      await _flutterTts!.setSpeechRate(_speechRate);
      await _flutterTts!.setVolume(_volume);
    } catch (e) {
      print('TTS Configuration Error: $e');
    }
  }

  Future<void> _loadSavedSettings() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Load Gemini API Key
      String? geminiApiKey = prefs.getString('gemini_api_key') ?? '';

      // Load TTS Settings
      setState(() {
        _geminiApiKeyController.text = geminiApiKey;
        _speechRate = prefs.getDouble('tts_speech_rate') ?? 0.5;
        _pitch = prefs.getDouble('tts_pitch') ?? 1.0;
        _volume = prefs.getDouble('tts_volume') ?? 1.0;
        _selectedLanguage = prefs.getString('tts_language') ?? 'en-US';
      });

      // Apply loaded TTS settings if TTS is initialized
      if (_isTTSInitialized) {
        await _configureTTS();
      }
    } catch (e) {
      _showErrorDialog('Failed to load settings: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    // Check if TTS is initialized before saving
    if (!_isTTSInitialized) {
      _showErrorDialog('TTS not initialized. Cannot save settings.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Save Gemini API Key
      await prefs.setString(
          'gemini_api_key', _geminiApiKeyController.text.trim());

      // Save TTS Settings
      await prefs.setDouble('tts_speech_rate', _speechRate);
      await prefs.setDouble('tts_pitch', _pitch);
      await prefs.setDouble('tts_volume', _volume);
      await prefs.setString('tts_language', _selectedLanguage);

      // Apply TTS settings
      await _configureTTS();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Settings saved successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF16A085),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to save settings: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error', style: TextStyle(color: Colors.black87)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF2980B9))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _geminiApiKeyController.dispose();
    // Safely stop TTS
    if (_flutterTts != null) {
      _flutterTts!.stop();
    }
    super.dispose();
  }

  Widget _buildTTSSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E44AD), Color(0xFF9B59B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E44AD).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.settings_voice,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Text-to-Speech Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTTSCustomizationPanel(),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.2, end: 0, duration: 300.ms);
  }

  Widget _buildTTSCustomizationPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Speech Rate',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        Slider(
          value: _speechRate,
          min: 0.1,
          max: 1.5,
          divisions: 14,
          label: _speechRate.toStringAsFixed(2),
          activeColor: Colors.black45,
          inactiveColor: Colors.white.withOpacity(0.5),
          onChanged: (value) {
            setState(() {
              _speechRate = value;
              _flutterTts?.setSpeechRate(value);
            });
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Pitch',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        Slider(
          value: _pitch,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          label: _pitch.toStringAsFixed(2),
          activeColor: Colors.black45,
          inactiveColor: Colors.white.withOpacity(0.5),
          onChanged: (value) {
            setState(() {
              _pitch = value;
              _flutterTts?.setPitch(value);
            });
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Volume',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        Slider(
          value: _volume,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          label: _volume.toStringAsFixed(2),
          activeColor: Colors.black45,
          inactiveColor: Colors.white.withOpacity(0.5),
          onChanged: (value) {
            setState(() {
              _volume = value;
              _flutterTts?.setVolume(value);
            });
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Language',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<String>(
            value: _selectedLanguage,
            isExpanded: true,
            underline: const SizedBox(),
            items: [
              'en-US',
              'es-ES',
              'fr-FR',
              'de-DE',
              'zh-CN',
              'ja-JP',
              'ko-KR',
              'ar-SA',
              'hi-IN'
            ].map((String language) {
              return DropdownMenuItem(
                value: language,
                child: Text(language),
              );
            }).toList(),
            onChanged: (String? newLanguage) {
              if (newLanguage != null) {
                setState(() {
                  _selectedLanguage = newLanguage;
                  _flutterTts?.setLanguage(newLanguage);
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      _showErrorDialog('Could not launch $url');
    }
  }

  Widget _buildApiKeySection({
    required String title,
    required String description,
    required String url,
    required TextEditingController controller,
    required bool isObscured,
    required VoidCallback onToggleObscure,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD35400), Color(0xFFE67E22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A085).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    title.contains('Gemini') ? Icons.api : Icons.mic,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _launchUrl(url),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Get API Key',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.open_in_new, size: 16, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              obscureText: isObscured,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Enter API Key',
                hintStyle: const TextStyle(color: Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscured ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey[600],
                  ),
                  onPressed: onToggleObscure,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.2, end: 0, duration: 300.ms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C3E50), // Deep blue-gray
              Color(0xFF3498DB), // Bright blue
              Color(0xFF2980B9), // Medium blue
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background circles similar to home view
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            // Custom App Bar
            Column(
              children: [
                _buildCustomAppBar(context),
                Expanded(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildApiKeySection(
                              title: 'Gemini API Key',
                              description:
                                  'Required for image description and AI capabilities.',
                              url: 'https://aistudio.google.com/app/apikey',
                              controller: _geminiApiKeyController,
                              isObscured: _isGeminiKeyObscured,
                              onToggleObscure: () => setState(() =>
                                  _isGeminiKeyObscured = !_isGeminiKeyObscured),
                            ),
                            const SizedBox(height: 16),
                            // New TTS Settings Section
                            _buildTTSSettingsSection(),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveSettings,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE74C3C),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.white),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
