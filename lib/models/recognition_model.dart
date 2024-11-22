import 'package:flutter/material.dart';
import 'package:perceptexx/models/screen_params_model.dart';

class Recognition {
  final int _id;
  final String _label;
  final double _score;
  final Rect _location;

  // Add color generation as a method
  final Color color;

  Recognition(
    int i,
    String label,
    double score, {
    required int id,
    required Rect location,
  })  : _id = id,
        _label = label,
        _score = score,
        _location = location,
        color = _generateColor(label, id);

  int get id => _id;
  String get label => _label;
  double get score => _score;
  Rect get location => _location;

  // Enhanced color generation method
  static Color _generateColor(String label, int id) {
    final colorSeed = label.length + label.codeUnitAt(0) + id;
    return Colors.primaries[colorSeed % Colors.primaries.length]
        .withOpacity(0.7);
  }

  Rect get renderLocation {
    final double scaleX = ScreenParams.screenPreviewSize.width / 300;
    final double scaleY = ScreenParams.screenPreviewSize.height / 300;

    final double reversedLeft = ScreenParams.screenPreviewSize.width -
        (location.left * scaleX + location.width * scaleX);
    final double reversedTop = ScreenParams.screenPreviewSize.height -
        (location.top * scaleY + location.height * scaleY);

    return Rect.fromLTWH(
      reversedLeft,
      reversedTop,
      location.width * scaleX,
      location.height * scaleY,
    );
  }

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score, location: $location)';
  }
}
