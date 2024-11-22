import 'package:flutter/material.dart';
import 'package:perceptexx/features/home/feature_detector.dart';
import 'package:perceptexx/features/home/widgets/feature_card.dart';
import 'package:perceptexx/features/home/widgets/greeting_section.dart';
import 'package:perceptexx/features/home/widgets/home_screen_background.dart';
import 'package:perceptexx/features/home/widgets/perceptex_appBar.dart';
import 'package:perceptexx/features/settings/settings_screen.dart';
import 'package:perceptexx/features/tutorial/tutorial_screen.dart';

import '../../utils/feature_type.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

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

  void _navigateToFeature(BuildContext context, FeatureType feature) {
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

  void _navigateToTutorial(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TutorialScreen(
          onClose: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }
}
