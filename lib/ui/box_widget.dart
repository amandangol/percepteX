import 'package:flutter/material.dart';
import 'package:perceptexx/models/recognition_model.dart';

class BoxWidget extends StatelessWidget {
  final Recognition result;
  final bool showConfidence;

  const BoxWidget(
      {super.key, required this.result, this.showConfidence = true});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: result.renderLocation.left,
      top: result.renderLocation.top,
      width: result.renderLocation.width,
      height: result.renderLocation.height,
      child: Container(
        decoration: BoxDecoration(
          color: result.color.withOpacity(0.3),
          border: Border.all(
              color: result.color,
              width: 2.5,
              strokeAlign: BorderSide.strokeAlignOutside),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              showConfidence
                  ? '${result.label} (${(result.score * 100).toStringAsFixed(1)}%)'
                  : result.label,
              style: TextStyle(
                color: result.color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.white.withOpacity(0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
