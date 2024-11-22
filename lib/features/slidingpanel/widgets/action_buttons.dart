import 'package:flutter/material.dart';
import 'package:perceptexx/features/slidingpanel/widgets/feature_config.dart';

class ActionButtons extends StatelessWidget {
  final FeatureConfig featureConfig;
  final bool isVoicePlaying;
  final VoidCallback onPlayPauseVoice;
  final VoidCallback onStopVoice;
  final Function(String) onCopy;
  final Function(String) onShare;

  const ActionButtons({
    Key? key,
    required this.featureConfig,
    required this.isVoicePlaying,
    required this.onPlayPauseVoice,
    required this.onStopVoice,
    required this.onCopy,
    required this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              isVoicePlaying ? Icons.pause : Icons.play_arrow,
              color: featureConfig.accentColor,
              size: 30,
            ),
            onPressed: onPlayPauseVoice,
          ),
          IconButton(
            icon: Icon(
              Icons.stop,
              color: featureConfig.accentColor,
              size: 30,
            ),
            onPressed: onStopVoice,
          ),
          _buildActionButton(
            icon: Icons.copy,
            label: 'Copy',
            color: featureConfig.accentColor,
            onPressed: () => onCopy(featureConfig.displayText),
          ),
          _buildActionButton(
            icon: Icons.share,
            label: 'Share',
            color: featureConfig.accentColor,
            onPressed: () => onShare(featureConfig.displayText),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}
