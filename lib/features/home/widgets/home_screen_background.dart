import 'package:flutter/material.dart';

// Extracted Background Decoration Widget
class HomeScreenBackground extends StatelessWidget {
  final Widget child;

  const HomeScreenBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF3498DB),
            Color(0xFF2980B9),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative Circles
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
          child,
        ],
      ),
    );
  }
}
