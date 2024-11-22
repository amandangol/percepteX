import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TutorialScreen extends StatelessWidget {
  final VoidCallback onClose;

  const TutorialScreen({Key? key, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C3E50),
              Color(0xFF34495E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildTutorialItems(context),
                ),
              ),
              const SizedBox(height: 24),
              _buildFooter(),
            ],
          ),
        ).animate().scale(
              duration: 400.ms,
              curve: Curves.easeOut,
            ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'How to Use PerceptEx',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: onClose,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.yellow),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap any feature card to learn more about its capabilities!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialItems(BuildContext context) {
    return Column(
      children: [
        _TutorialItem(
          icon: Icons.visibility,
          title: 'Object Detection',
          description:
              'Point your camera at any object to identify it in real-time',
          color: const Color(0xFF16A085),
          onTap: () => _showTutorialDetail(
            context,
            'Object Detection',
            'Get instant identification of objects in your surroundings. Perfect for learning about your environment or assistance with identifying items.',
          ),
        ),
        const SizedBox(height: 16),
        _TutorialItem(
          icon: Icons.text_fields,
          title: 'Text Recognition',
          description: 'Convert any text in images to readable format',
          color: const Color(0xFF8E44AD),
          onTap: () => _showTutorialDetail(
            context,
            'Text Recognition',
            'Simply point your camera at any text to have it recognized and read aloud. Great for signs, documents, or any written content.',
          ),
        ),
        const SizedBox(height: 16),
        _TutorialItem(
          icon: Icons.image,
          title: 'Scene Description',
          description: 'Get detailed descriptions of your surroundings',
          color: const Color(0xFFD35400),
          onTap: () => _showTutorialDetail(
            context,
            'Scene Description',
            'Capture and understand your surroundings with AI-powered scene description. Perfect for navigation and environmental awareness.',
          ),
        ),
      ],
    );
  }

  void _showTutorialDetail(
      BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF2C3E50),
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20.0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().scale(
              duration: 300.ms,
              curve: Curves.easeOut,
            );
      },
    );
  }
}

class _TutorialItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _TutorialItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 400.ms, delay: 100.ms).slideX(
          begin: 0.2,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOut,
          delay: 100.ms,
        );
  }
}
