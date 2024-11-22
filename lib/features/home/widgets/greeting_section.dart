import 'package:flutter/material.dart';

class GreetingSection extends StatelessWidget {
  const GreetingSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = hour < 12
        ? 'Good Morning'
        : hour < 18
            ? 'Good Afternoon'
            : 'Good Evening';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: greeting,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        letterSpacing: 1.2,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [
                              Colors.blueAccent,
                              Color.fromARGB(255, 182, 171, 184)
                            ],
                          ).createShader(
                              const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                      ),
                    ),
                    TextSpan(
                      text: ' 👋',
                      style: TextStyle(
                        fontSize: 36,
                        color: Colors.yellow.shade300,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your AI Vision Companion',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 0.6,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Today is ${_formatDate()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
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
