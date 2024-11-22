import 'package:flutter/material.dart';

class CustomFeatureAppBar extends StatelessWidget {
  final String featureTitle;
  final VoidCallback onBack;
  final VoidCallback onHelpPressed;

  const CustomFeatureAppBar({
    Key? key,
    required this.featureTitle,
    required this.onBack,
    required this.onHelpPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
            ),
            Text(
              featureTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.help_outline,
                color: Colors.white,
              ),
              onPressed: onHelpPressed,
            ),
          ],
        ),
      ),
    );
  }
}
