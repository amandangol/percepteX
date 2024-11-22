import 'package:flutter/material.dart';

class FeatureConfig {
  /// The title of the feature to be displayed in the panel header
  final String title;

  /// The icon representing the feature
  final IconData icon;

  /// The accent color used for styling elements related to this feature
  final Color accentColor;

  /// The main text content to be displayed in the panel
  final String displayText;

  /// Secondary description or subtitle (optional)
  final String? subtitle;

  /// Whether the feature supports voice playback
  final bool supportsVoice;

  /// Whether the feature supports translation
  final bool supportsTranslation;

  /// Maximum number of lines to show in collapsed state
  final int previewLines;

  /// Optional placeholder text when no data is available
  final String placeholderText;

  /// Optional custom actions specific to this feature
  final List<FeatureAction>? actions;

  const FeatureConfig({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.displayText,
    this.subtitle,
    this.supportsVoice = false,
    this.supportsTranslation = false,
    this.previewLines = 2,
    this.placeholderText = 'No data available',
    this.actions,
  });

  /// Creates a copy of this FeatureConfig with the specified fields replaced
  FeatureConfig copyWith({
    String? title,
    IconData? icon,
    Color? accentColor,
    String? displayText,
    String? subtitle,
    bool? supportsVoice,
    bool? supportsTranslation,
    int? previewLines,
    String? placeholderText,
    List<FeatureAction>? actions,
  }) {
    return FeatureConfig(
      title: title ?? this.title,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      displayText: displayText ?? this.displayText,
      subtitle: subtitle ?? this.subtitle,
      supportsVoice: supportsVoice ?? this.supportsVoice,
      supportsTranslation: supportsTranslation ?? this.supportsTranslation,
      previewLines: previewLines ?? this.previewLines,
      placeholderText: placeholderText ?? this.placeholderText,
      actions: actions ?? this.actions,
    );
  }

  /// Creates a default configuration for when feature type is unknown
  factory FeatureConfig.defaultConfig() {
    return const FeatureConfig(
      title: 'Unknown Feature',
      icon: Icons.help_outline,
      accentColor: Colors.grey,
      displayText: 'Feature not configured',
      placeholderText: 'No data available',
    );
  }

  /// Creates a configuration for text recognition feature
  factory FeatureConfig.textRecognition({String? recognizedText}) {
    return FeatureConfig(
      title: 'Recognized Text',
      icon: Icons.text_fields,
      accentColor: Colors.purple,
      displayText: recognizedText ?? 'No text recognized',
      supportsVoice: true,
      supportsTranslation: true,
      previewLines: 3,
      placeholderText: 'Point camera at text to begin recognition',
    );
  }

  /// Creates a configuration for scene description feature
  factory FeatureConfig.sceneDescription({String? description}) {
    return FeatureConfig(
      title: 'Scene Description',
      icon: Icons.image,
      accentColor: Colors.orange,
      displayText: description ?? 'No scene described',
      supportsVoice: true,
      supportsTranslation: false,
      previewLines: 2,
      placeholderText: 'Point camera at a scene to begin analysis',
    );
  }

  /// Creates a configuration for object search feature
  factory FeatureConfig.objectSearch({String? description}) {
    return FeatureConfig(
      title: 'Object Analysis',
      icon: Icons.search,
      accentColor: Colors.blue,
      displayText: description ?? 'No object analyzed',
      supportsVoice: false,
      supportsTranslation: false,
      previewLines: 2,
      placeholderText: 'Point camera at an object to begin analysis',
      actions: [
        FeatureAction(
          icon: Icons.search,
          label: 'Search',
          actionType: ActionType.search,
        ),
        FeatureAction(
          icon: Icons.image_search,
          label: 'Image Search',
          actionType: ActionType.imageSearch,
        ),
      ],
    );
  }
}

/// Represents a custom action that can be performed on the feature
class FeatureAction {
  final IconData icon;
  final String label;
  final ActionType actionType;
  final VoidCallback? onPressed;

  const FeatureAction({
    required this.icon,
    required this.label,
    required this.actionType,
    this.onPressed,
  });
}

/// Defines the types of actions available for features
enum ActionType { search, imageSearch, translate, copy, share, voice, custom }
