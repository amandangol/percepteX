import 'package:flutter/material.dart';
import 'package:perceptexx/utils/feature_type.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:translator/translator.dart';

class CustomSlidingPanel extends StatefulWidget {
  final PanelController panelController;
  final double minHeight;
  final double maxHeight;
  final FeatureType feature;
  final String? recognizedTextOutput;
  final String? sceneDescriptionOutput;
  final DateTime? lastDetectionTime;
  final Function(String) onCopy;
  final Function(String) onShare;
  final Function(String)? onTranslate;
  final bool isVoicePlaying;
  final VoidCallback onPlayPauseVoice;
  final VoidCallback onStopVoice;
  const CustomSlidingPanel({
    Key? key,
    required this.panelController,
    required this.minHeight,
    required this.maxHeight,
    required this.feature,
    this.recognizedTextOutput,
    this.sceneDescriptionOutput,
    this.lastDetectionTime,
    required this.onCopy,
    required this.onShare,
    this.onTranslate,
    required this.isVoicePlaying,
    required this.onPlayPauseVoice,
    required this.onStopVoice,
  }) : super(key: key);

  @override
  _CustomSlidingPanelState createState() => _CustomSlidingPanelState();
}

class _CustomSlidingPanelState extends State<CustomSlidingPanel> {
  final translator = GoogleTranslator();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return SlidingUpPanel(
      controller: widget.panelController,
      minHeight: widget.minHeight,
      maxHeight: widget.maxHeight,
      panel: _buildPanelContent(),
      collapsed: _buildCollapsedPanel(),
      body: Container(),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 15,
          spreadRadius: 2,
          offset: const Offset(0, -3),
        ),
      ],
      onPanelSlide: (position) {
        setState(() {
          _isExpanded = position > 0.5;
        });
      },
    );
  }

  Widget _buildCollapsedPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelContent() {
    final featureConfig = _getFeatureConfig();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: featureConfig.accentColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(featureConfig.icon,
                        color: featureConfig.accentColor, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      featureConfig.title,
                      style: TextStyle(
                        color: featureConfig.accentColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (_isExpanded)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => widget.panelController.close(),
                  ),
              ],
            ),
          ),
          if (widget.lastDetectionTime != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Last updated: ${_formatDateTime(widget.lastDetectionTime!)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  featureConfig.displayText,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),
          _buildActionButtons(featureConfig),
        ],
      ),
    );
  }

  Widget _buildActionButtons(FeatureConfig featureConfig) {
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
              widget.isVoicePlaying ? Icons.pause : Icons.play_arrow,
              color: featureConfig.accentColor,
              size: 30,
            ),
            onPressed: widget.onPlayPauseVoice,
          ),
          IconButton(
            icon: Icon(
              Icons.stop,
              color: featureConfig.accentColor,
              size: 30,
            ),
            onPressed: widget.onStopVoice,
          ),
          _buildActionButton(
            icon: Icons.copy,
            label: 'Copy',
            color: featureConfig.accentColor,
            onPressed: () => widget.onCopy(featureConfig.displayText),
          ),
          _buildActionButton(
            icon: Icons.share,
            label: 'Share',
            color: featureConfig.accentColor,
            onPressed: () => widget.onShare(featureConfig.displayText),
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  FeatureConfig _getFeatureConfig() {
    switch (widget.feature) {
      case FeatureType.textRecognition:
        return FeatureConfig(
          title: 'Recognized Text',
          icon: Icons.text_fields,
          accentColor: Colors.purple,
          displayText: widget.recognizedTextOutput ?? 'No text recognized',
        );
      case FeatureType.sceneDescription:
        return FeatureConfig(
          title: 'Scene Description',
          icon: Icons.image,
          accentColor: Colors.orange,
          displayText: widget.sceneDescriptionOutput ?? 'No scene described',
        );
      default:
        return const FeatureConfig(
          title: 'Unknown',
          icon: Icons.help,
          accentColor: Colors.grey,
          displayText: 'No data available',
        );
    }
  }
}

class FeatureConfig {
  final String title;
  final IconData icon;
  final Color accentColor;
  final String displayText;

  const FeatureConfig({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.displayText,
  });
}
