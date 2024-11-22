import 'package:flutter/material.dart';

class AnalyzingLoader extends StatelessWidget {
  final String message;
  final Color accentColor;

  const AnalyzingLoader({
    Key? key,
    this.message = 'Analyzing...',
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              backgroundColor: accentColor.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}
