// lib/components/object_search_panel.dart

import 'package:flutter/material.dart';
import 'package:perceptexx/services/object_search_service.dart';

class ObjectSearchPanel extends StatelessWidget {
  final ObjectSearchResult result;
  final ObjectSearchService service;
  final bool isVoicePlaying;
  final VoidCallback onPlayPauseVoice;
  final VoidCallback onStopVoice;
  final DateTime? lastDetectionTime;

  const ObjectSearchPanel({
    Key? key,
    required this.result,
    required this.service,
    required this.isVoicePlaying,
    required this.onPlayPauseVoice,
    required this.onStopVoice,
    this.lastDetectionTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detection Time
          if (lastDetectionTime != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Detected at ${lastDetectionTime!.hour}:${lastDetectionTime!.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.grey),
              ),
            ),

          // Main Object Title
          Text(
            result.mainObject,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF16A085),
                ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            result.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),

          // Voice Controls
          Row(
            children: [
              IconButton(
                icon: Icon(isVoicePlaying ? Icons.pause : Icons.play_arrow),
                onPressed: onPlayPauseVoice,
                color: const Color(0xFF16A085),
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: onStopVoice,
                color: const Color(0xFF16A085),
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                onPressed: () {
                  // Implement share functionality
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF16A085),
                ),
              ),
            ],
          ),
          const Divider(),

          // Suggested Searches
          Text(
            'Suggested Searches',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...result.suggestedQueries.map((query) => ActionChip(
                    label: Text(query),
                    onPressed: () => service.searchGoogle(query),
                    backgroundColor: const Color(0xFFE8F6F3),
                    labelStyle: const TextStyle(color: Color(0xFF16A085)),
                  )),
            ],
          ),
          const SizedBox(height: 16),

          // Search Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Search on Google'),
              onPressed: () => service.searchGoogle(
                '${result.mainObject} ${result.searchKeywords.join(' ')}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A085),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
