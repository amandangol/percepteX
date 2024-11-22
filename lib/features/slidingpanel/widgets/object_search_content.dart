import 'package:flutter/material.dart';
import 'package:perceptexx/components/analyzing_loader.dart';

class ObjectSearchContent extends StatelessWidget {
  final Map<String, dynamic>? objectSearchResult;
  final Function(String) onGoogleSearch;
  final Function(String, {bool isImageSearch}) onImageSearch;
  final bool isAnalyzing;
  final Color accentColor;

  const ObjectSearchContent({
    Key? key,
    required this.objectSearchResult,
    required this.onGoogleSearch,
    required this.onImageSearch,
    required this.isAnalyzing,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isAnalyzing) {
      return AnalyzingLoader(
        message: 'Analyzing object...',
        accentColor: accentColor,
      );
    }
    if (objectSearchResult == null) {
      return const Text(
        'No object analysis available',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      );
    }

    final mainObject = objectSearchResult!['main_object'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Main Object: $mainObject',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          objectSearchResult!['description'],
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _buildSearchButtons(mainObject),
        const SizedBox(height: 24),
        if (objectSearchResult!['search_keywords']?.isNotEmpty == true)
          _buildKeywords(),
        if (objectSearchResult!['suggested_queries']?.isNotEmpty == true)
          _buildSuggestedQueries(),
      ],
    );
  }

  Widget _buildSearchButtons(String searchQuery) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => onGoogleSearch(searchQuery),
          icon: const Icon(Icons.search),
          label: const Text('Search on Google'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => onImageSearch(searchQuery, isImageSearch: true),
          icon: const Icon(Icons.image_search),
          label: const Text('Image Search'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeywords() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Related Keywords:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (objectSearchResult!['search_keywords'] as List)
              .map((keyword) => ActionChip(
                    label: Text(keyword),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    onPressed: () => onGoogleSearch(keyword),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestedQueries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Suggested Searches:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...objectSearchResult!['suggested_queries']
            .map<Widget>((query) => ListTile(
                  leading: const Icon(Icons.search),
                  title: Text(query),
                  onTap: () => onGoogleSearch(query),
                ))
            .toList(),
      ],
    );
  }
}
