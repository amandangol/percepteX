import 'package:flutter/material.dart';
import 'package:perceptexx/utils/feature_type.dart';

class CustomControlButton extends StatelessWidget {
  final FeatureType feature;
  final bool isPaused;
  final bool isTextRecognitionRunning;
  final bool isImageDescriptionRunning;
  final bool showTextOutput;
  final VoidCallback onPressed;

  const CustomControlButton({
    Key? key,
    required this.feature,
    required this.isPaused,
    required this.isTextRecognitionRunning,
    required this.isImageDescriptionRunning,
    required this.showTextOutput,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Destructure button properties based on feature and current state
    final buttonProps = _getButtonProperties();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonProps.color,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        icon: Icon(buttonProps.icon, color: Colors.white),
        label: Text(
          buttonProps.label,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Extracted method to handle button properties
  _ButtonProperties _getButtonProperties() {
    switch (feature) {
      case FeatureType.objectDetection:
        return _ButtonProperties(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          label: isPaused ? 'Start' : 'Pause',
          color: isPaused ? Colors.green : Colors.orange,
        );

      case FeatureType.textRecognition:
        final isProcessing = isTextRecognitionRunning;
        return _ButtonProperties(
          icon: isProcessing ? Icons.stop : Icons.text_fields,
          label: isProcessing
              ? 'Stop'
              : (showTextOutput ? 'New Scan' : 'Read Text'),
          color: isProcessing ? Colors.red : Colors.purple,
        );

      case FeatureType.sceneDescription:
        final isProcessing = isImageDescriptionRunning;
        return _ButtonProperties(
          icon: isProcessing ? Icons.stop : Icons.image,
          label: isProcessing
              ? 'Stop'
              : (showTextOutput ? 'New Description' : 'Describe Scene'),
          color: isProcessing ? Colors.red : Colors.orange,
        );
      case FeatureType.objectSearch:
        final isProcessing = isImageDescriptionRunning;
        return _ButtonProperties(
          icon: isProcessing ? Icons.stop : Icons.camera_alt,
          label: isProcessing
              ? 'Stop'
              : (showTextOutput ? 'New Search' : 'Search Objects'),
          color: isProcessing ? Colors.red : Colors.yellow.withOpacity(0.5),
        );
    }
  }
}

// Helper class to encapsulate button properties
class _ButtonProperties {
  final IconData icon;
  final String label;
  final Color color;

  const _ButtonProperties(
      {required this.icon, required this.label, required this.color});
}
