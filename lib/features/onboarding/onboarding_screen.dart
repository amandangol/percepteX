import 'package:flutter/material.dart';
import 'package:perceptexx/features/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  FlutterTts? flutterTts;
  int _currentPage = 0;
  bool _isInitialized = false;

  final List<Map<String, dynamic>> _onboardingPages = [
    {
      'icon': Icons.search_outlined,
      'title': 'Object Detection',
      'description':
          'Instantly identify and locate objects in real-time using advanced computer vision.',
      'color': const Color(0xFF16A085),
      'voicePrompt':
          'Welcome to PercepteX! Point your camera at any object to instantly identify it using object detection.',
    },
    {
      'icon': Icons.text_fields_outlined,
      'title': 'Text Recognition',
      'description':
          'Extract and read text from any image with high accuracy and precision.',
      'color': const Color(0xFF8E44AD),
      'voicePrompt':
          'With Text Recognition, you can extract text from any image or document.',
    },
    {
      'icon': Icons.landscape_outlined,
      'title': 'Scene Description',
      'description':
          'Get comprehensive and detailed descriptions of entire scenes in a single glance.',
      'color': const Color(0xFFD35400),
      'voicePrompt':
          'Scene Description helps you understand your surroundings with detailed explanations.',
    },
    {
      'icon': Icons.manage_search_outlined,
      'title': 'Object Search',
      'description':
          'Identify objects and discover detailed information about them with intelligent search capabilities.',
      'color': const Color(0xFF2980B9),
      'voicePrompt':
          'Use Object Search to learn more about anything you see around you.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initializeTts();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _initializeTts() async {
    flutterTts = FlutterTts();
    await flutterTts?.setLanguage('en-US');
    await flutterTts?.setSpeechRate(0.5);
    await flutterTts?.setPitch(1.0);
    _speakPageContent(_currentPage);
  }

  Future<void> _speakPageContent(int pageIndex) async {
    await flutterTts?.stop();
    await flutterTts?.speak(_onboardingPages[pageIndex]['voicePrompt']);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);
  }

  void _navigateToHome() {
    _completeOnboarding();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    flutterTts?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF1C2541),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1C2541),
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackgroundPattern(),
            Column(
              children: [
                _buildSkipButton(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _onboardingPages.length,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                      _speakPageContent(page);
                    },
                    itemBuilder: (context, index) {
                      return _buildOnboardingPage(_onboardingPages[index]);
                    },
                  ),
                ),
                _buildNavigationRow(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: BackgroundPatternPainter(
          color: _onboardingPages[_currentPage]['color'],
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextButton(
          onPressed: _navigateToHome,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
          child: const Text(
            'Skip',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(Map<String, dynamic> page) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFeatureIcon(page),
                  const SizedBox(height: 40),
                  _buildTitle(page),
                  const SizedBox(height: 20),
                  _buildDescription(page),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureIcon(Map<String, dynamic> page) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  page['color'],
                  page['color'].withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: page['color'].withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(35),
            child: Icon(
              page['icon'],
              size: 100,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(Map<String, dynamic> page) {
    return Text(
      page['title'],
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDescription(Map<String, dynamic> page) {
    return Text(
      page['description'],
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        color: Colors.white.withOpacity(0.9),
        height: 1.6,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildNavigationRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavigationButton(
            onPressed: _currentPage > 0
                ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            icon: Icons.arrow_back_ios,
            label: 'Previous',
          ),
          _buildPageIndicators(),
          _buildNavigationButton(
            onPressed: _currentPage < _onboardingPages.length - 1
                ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                : _navigateToHome,
            icon: _currentPage < _onboardingPages.length - 1
                ? Icons.arrow_forward_ios
                : Icons.check_circle_outline,
            label: _currentPage < _onboardingPages.length - 1
                ? 'Next'
                : 'Get Started',
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      children: List.generate(
        _onboardingPages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? _onboardingPages[index]['color']
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  final Color color;

  BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 5; i++) {
      final radius = (size.width / 4) * (i + 1);
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2),
        radius,
        paint,
      );
    }

    for (var i = 0; i < 3; i++) {
      final radius = (size.width / 5) * (i + 1);
      canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.8),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BackgroundPatternPainter oldDelegate) =>
      color != oldDelegate.color;
}
