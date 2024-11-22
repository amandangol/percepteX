import 'package:flutter/material.dart';
import 'package:perceptexx/features/slidingpanel/widgets/feature_config.dart';
import 'package:perceptexx/features/slidingpanel/widgets/panel_content.dart';
import 'package:perceptexx/utils/feature_type.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomSlidingPanel extends StatefulWidget {
  final PanelController panelController;
  final double minHeight;
  final double maxHeight;
  final FeatureType feature;
  final String? recognizedTextOutput;
  final String? sceneDescriptionOutput;
  final Map<String, dynamic>? objectSearchResult;
  final Function(String) onCopy;
  final Function(String) onShare;
  final bool isAnalyzing;

  const CustomSlidingPanel({
    Key? key,
    required this.panelController,
    required this.minHeight,
    required this.maxHeight,
    required this.feature,
    this.recognizedTextOutput,
    this.sceneDescriptionOutput,
    this.objectSearchResult,
    required this.onCopy,
    required this.onShare,
    this.isAnalyzing = false,
  }) : super(key: key);

  @override
  _CustomSlidingPanelState createState() => _CustomSlidingPanelState();
}

class _CustomSlidingPanelState extends State<CustomSlidingPanel> {
  double _slideProgress = 0.0;

  FeatureConfig _getFeatureConfig() {
    switch (widget.feature) {
      case FeatureType.textRecognition:
        return FeatureConfig.textRecognition(
            recognizedText: widget.recognizedTextOutput);
      case FeatureType.sceneDescription:
        return FeatureConfig.sceneDescription(
            description: widget.sceneDescriptionOutput);
      case FeatureType.objectSearch:
        return FeatureConfig.objectSearch(
            description: widget.objectSearchResult?['description']);
      default:
        return FeatureConfig.defaultConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    final featureConfig = _getFeatureConfig();

    return SlidingUpPanel(
      controller: widget.panelController,
      minHeight: widget.minHeight,
      maxHeight: widget.maxHeight,
      body: Container(),
      panel: PanelContent(
        featureConfig: featureConfig,
        slideProgress: _slideProgress,
        onClose: () => widget.panelController.close(),
        isAnalyzing: widget.isAnalyzing,
        contentText: featureConfig.displayText,
        feature: widget.feature,
        objectSearchResult: widget.objectSearchResult,
      ),
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
          _slideProgress = position;
        });
      },
    );
  }
}
