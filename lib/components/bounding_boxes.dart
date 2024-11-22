import 'package:flutter/material.dart';
import 'package:perceptexx/models/recognition_model.dart';
import 'package:perceptexx/ui/box_widget.dart';

class CustomBoundingBoxes extends StatelessWidget {
  final List<Recognition>? results;
  final double confidenceThreshold;
  final int? maxBoxes;

  const CustomBoundingBoxes(
      {Key? key, this.results, this.confidenceThreshold = 0.5, this.maxBoxes})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (results == null || results!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter and sort results
    final filteredResults = results!
        .where((box) => box.score >= confidenceThreshold)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // Limit number of boxes if specified
    final displayResults = maxBoxes != null
        ? filteredResults.take(maxBoxes!).toList()
        : filteredResults;

    return Stack(
      children: displayResults.map((box) => BoxWidget(result: box)).toList(),
    );
  }
}
