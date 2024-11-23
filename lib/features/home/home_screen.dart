import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Add flutter_tts package to pubspec.yaml
import 'package:perceptexx/features/home/feature_detector.dart';
import 'package:perceptexx/features/home/widgets/feature_card.dart';
import 'package:perceptexx/features/home/widgets/greeting_section.dart';
import 'package:perceptexx/features/home/widgets/home_screen_background.dart';
import 'package:perceptexx/features/home/widgets/perceptex_appBar.dart';
import 'package:perceptexx/features/settings/settings_screen.dart';
import 'package:perceptexx/features/tutorial/tutorial_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/feature_type.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late FlutterTts flutterTts;
  bool isFirstLaunch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkFirstLaunch();
  }

  void checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    isFirstLaunch = !(prefs.getBool('has_launched') ?? false);
    if (isFirstLaunch) {
      await prefs.setBool('has_launched', true);
      initializeTts();
    }
  }

  void initializeTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);

    if (isFirstLaunch) {
      final hour = DateTime.now().hour;
      String timeOfDayGreeting = hour < 12
          ? 'Good Morning'
          : hour < 18
              ? 'Good Afternoon'
              : 'Good Evening';

      String greeting =
          '$timeOfDayGreeting! I am PercepteX, your AI vision companion. '
          'I can help you detect objects, recognize text, describe scenes, and search for items. '
          'Let\'s explore what you can do today!';

      await flutterTts.speak(greeting);
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          HomeScreenBackground(
            child: Column(
              children: [
                PerceptexAppBar(
                  onSettingsPressed: () => _navigateToSettings(context),
                ),
                Expanded(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const GreetingSection(),
                          const SizedBox(height: 16),
                          Expanded(child: _buildFeatureGrid(context)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              child: FloatingActionButton(
                onPressed: () => _navigateToTutorial(context),
                backgroundColor: const Color(0xFFE74C3C),
                elevation: 8,
                child: const Icon(Icons.help_outline),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Existing methods remain the same as in the previous implementation
  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      {
        'title': 'Object Detection',
        'icon': Icons.search_outlined,
        'description': 'Identify objects in real-time',
        'colors': [const Color(0xFF16A085), const Color(0xFF1ABC9C)],
        'feature': FeatureType.objectDetection,
      },
      {
        'title': 'Text Recognition',
        'icon': Icons.text_fields_outlined,
        'description': 'Read text from images',
        'colors': [const Color(0xFF8E44AD), const Color(0xFF9B59B6)],
        'feature': FeatureType.textRecognition,
      },
      {
        'title': 'Scene Description',
        'icon': Icons.landscape_outlined,
        'description': 'Get detailed scene descriptions',
        'colors': [const Color(0xFFD35400), const Color(0xFFE67E22)],
        'feature': FeatureType.sceneDescription,
      },
      {
        'title': 'Object Search',
        'icon': Icons.camera_alt,
        'description': 'Search objects with Google',
        'colors': [const Color(0xFF2980B), Color.fromARGB(255, 188, 219, 52)],
        'feature': FeatureType.objectSearch,
      },
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 3 / 4,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return FeatureCard(
          title: feature['title'] as String,
          icon: feature['icon'] as IconData,
          description: feature['description'] as String,
          gradientColors: feature['colors'] as List<Color>,
          onTap: () => _navigateToFeature(
            context,
            feature['feature'] as FeatureType,
          ),
        );
      },
    );
  }

  void _navigateToFeature(BuildContext context, FeatureType feature) async {
    await flutterTts.stop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeatureDetector(
          feature: feature,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _navigateToTutorial(BuildContext context) async {
    await flutterTts.stop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TutorialScreen(
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) async {
    await flutterTts.stop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }
}
