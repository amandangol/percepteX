import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GreetingSection extends StatefulWidget {
  const GreetingSection({Key? key}) : super(key: key);

  @override
  _GreetingSectionState createState() => _GreetingSectionState();
}

class _GreetingSectionState extends State<GreetingSection>
    with SingleTickerProviderStateMixin {
  late FlutterTts flutterTts;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _hasPlayedInitialGreeting = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
    initializeTts();
    checkInitialGreeting();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMuted = _prefs.getBool('greeting_muted') ?? false;
    });
  }

  void initializeTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage('en-US');
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);

    flutterTts.setCompletionHandler(() {
      setState(() {
        _isPlaying = false;
      });
    });
  }

  void checkInitialGreeting() async {
    final currentDate = DateTime.now().toIso8601String().split('T')[0];
    final lastLaunchDate = _prefs.getString('last_launch_date');

    if (lastLaunchDate == null || lastLaunchDate != currentDate) {
      await _prefs.setString('last_launch_date', currentDate);
      if (!_isMuted) {
        _playInitialGreeting();
      }
    }
  }

  void _toggleGreetingAction() async {
    if (_isMuted) {
      // If muted, unmute
      setState(() {
        _isMuted = false;
      });
      await _prefs.setBool('greeting_muted', false);
    } else {
      // If not muted and not playing, play greeting
      if (!_isPlaying) {
        setState(() {
          _isPlaying = true;
        });
        await flutterTts.speak(_generateGreeting());
      } else {
        // If playing, mute and stop
        await flutterTts.stop();
        setState(() {
          _isPlaying = false;
          _isMuted = true;
        });
        await _prefs.setBool('greeting_muted', true);
      }
    }
  }

  void _playInitialGreeting() async {
    if (!_hasPlayedInitialGreeting && !_isMuted) {
      setState(() {
        _isPlaying = true;
        _hasPlayedInitialGreeting = true;
      });
      await flutterTts.speak(_generateGreeting());
    }
  }

  String _generateGreeting() {
    final hour = DateTime.now().hour;
    String timeOfDayGreeting = hour < 12
        ? 'Good Morning'
        : hour < 18
            ? 'Good Afternoon'
            : 'Good Evening';

    return '$timeOfDayGreeting! I am PercepteX, your AI vision companion. '
        'I can help you detect objects, recognize text, describe scenes, and search for items. '
        'Let\'s explore what you can do today!';
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = hour < 12
        ? 'Good Morning'
        : hour < 18
            ? 'Good Afternoon'
            : 'Good Evening';

    return FadeTransition(
      opacity: _animation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2C3E50).withOpacity(0.7),
              Color(0xFF34495E).withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your AI Vision Companion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _toggleGreetingAction,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isMuted
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _isMuted
                          ? Icons.volume_off
                          : (_isPlaying ? Icons.pause : Icons.play_arrow),
                      color: _isMuted
                          ? Colors.white.withOpacity(0.4)
                          : Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Today is ${_formatDate()}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}
