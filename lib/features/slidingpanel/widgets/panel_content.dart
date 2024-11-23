import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:perceptexx/components/analyzing_loader.dart';
import 'package:perceptexx/features/slidingpanel/widgets/action_buttons.dart';
import 'package:perceptexx/features/slidingpanel/widgets/feature_config.dart';
import 'package:perceptexx/utils/feature_type.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PanelContent extends StatefulWidget {
  final FeatureConfig featureConfig;
  final double slideProgress;
  final VoidCallback onClose;
  final bool isAnalyzing;
  final String? contentText;
  final FeatureType feature;
  final Map<String, dynamic>? objectSearchResult;

  const PanelContent({
    Key? key,
    required this.featureConfig,
    required this.slideProgress,
    required this.onClose,
    required this.isAnalyzing,
    this.contentText,
    required this.feature,
    this.objectSearchResult,
  }) : super(key: key);

  @override
  _PanelContentState createState() => _PanelContentState();
}

class _PanelContentState extends State<PanelContent> {
  final FlutterTts _flutterTts = FlutterTts();
  TTSState _ttsState = TTSState.stopped;

  @override
  void initState() {
    super.initState();
    _initializeTTS();
  }

  void _initializeTTS() {
    _flutterTts.setCompletionHandler(() => _updateTTSState(TTSState.stopped));
    _flutterTts.setErrorHandler((msg) => _updateTTSState(TTSState.stopped));
  }

  void _updateTTSState(TTSState state) {
    if (mounted) {
      setState(() => _ttsState = state);
    }
  }

  Future<void> _controlTTS() async {
    final text = widget.contentText ?? '';

    switch (_ttsState) {
      case TTSState.stopped:
        await _flutterTts.speak(text);
        _updateTTSState(TTSState.playing);
        break;
      case TTSState.playing:
        await _flutterTts.pause();
        _updateTTSState(TTSState.paused);
        break;
      case TTSState.paused:
        await _flutterTts.speak(text);
        _updateTTSState(TTSState.playing);
        break;
    }
  }

  Future<void> _stopTTS() async {
    await _flutterTts.stop();
    _updateTTSState(TTSState.stopped);
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Copied to clipboard!',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareContent(String text) {
    Share.share(text);
  }

  Future<void> _launchSearch(String query, {bool isImageSearch = false}) async {
    final encodedQuery = Uri.encodeComponent(query);
    final searchUrl = isImageSearch
        ? 'https://www.google.com/search?q=$encodedQuery&tbm=isch'
        : 'https://www.google.com/search?q=$encodedQuery';

    try {
      await launchUrl(Uri.parse(searchUrl),
          mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Search launch error: $e');
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40 + (8 * widget.slideProgress),
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: Color.lerp(
          Colors.grey[300],
          widget.featureConfig.accentColor,
          widget.slideProgress,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Hero(
          tag: 'feature_icon',
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.featureConfig.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.featureConfig.icon,
              color: widget.featureConfig.accentColor,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Hero(
            tag: 'feature_title',
            child: Material(
              color: Colors.transparent,
              child: Text(
                widget.featureConfig.title,
                style: TextStyle(
                  fontSize: 18 + (2 * widget.slideProgress),
                  fontWeight: FontWeight.bold,
                  color: widget.featureConfig.accentColor,
                ),
              ),
            ),
          ),
        ),
        if (widget.slideProgress > 0.5)
          Opacity(
            opacity: (widget.slideProgress - 0.5) * 2,
            child: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: widget.onClose,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (widget.isAnalyzing) {
      return Center(
        child: AnalyzingLoader(
          message: _getLoadingMessage(),
          accentColor: widget.featureConfig.accentColor,
        ),
      );
    }

    return widget.feature == FeatureType.objectSearch
        ? _buildObjectSearchContent()
        : Text(
            widget.contentText ?? '',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14 + (2 * widget.slideProgress),
              height: 1.6,
            ),
          );
  }

  Widget _buildObjectSearchContent() {
    final result = widget.objectSearchResult ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildObjectHeader(result),
        const SizedBox(height: 16),
        _buildSearchButtons(result),
        if (result['search_keywords'] != null) _buildKeywordsSection(result),
        if (result['suggested_queries'] != null) _buildQueriesSection(result),
        if (result['attributes'] != null) _buildAttributesSection(result),
      ],
    );
  }

  Widget _buildObjectHeader(Map<String, dynamic> result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result['main_object'] ?? 'Unknown Object',
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          result['description'] ?? 'No Object Analyzed',
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        if (result['confidence'] != null)
          Text(
            'Confidence: ${(result['confidence'] * 100).toStringAsFixed(2)}%',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  Widget _buildSearchButtons(Map<String, dynamic> result) {
    final mainObject = result['main_object'] ?? '';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: () => _launchSearch(mainObject),
          icon: const Icon(Icons.search, size: 18),
          label: const Text('Google Search'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.featureConfig.accentColor.withOpacity(0.9),
            foregroundColor: Colors.white,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _launchSearch(mainObject, isImageSearch: true),
          icon: const Icon(Icons.image_search, size: 18),
          label: const Text('Image Search'),
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.featureConfig.accentColor,
            side: BorderSide(color: widget.featureConfig.accentColor),
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordsSection(Map<String, dynamic> result) {
    final keywords = result['search_keywords'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Related Keywords:',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keywords
              .map((keyword) => ActionChip(
                    label: Text(keyword),
                    onPressed: () => _launchSearch(keyword),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQueriesSection(Map<String, dynamic> result) {
    final queries = result['suggested_queries'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Suggested Searches:',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...queries
            .map<Widget>((query) => ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.search,
                    color: widget.featureConfig.accentColor,
                  ),
                  title: Text(query),
                  onTap: () => _launchSearch(query),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildAttributesSection(Map<String, dynamic> result) {
    final attributes = result['attributes'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Additional Details:',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...attributes
            .map<Widget>((attribute) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: widget.featureConfig.accentColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          attribute,
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }

  String _getLoadingMessage() {
    return {
          FeatureType.textRecognition: 'Recognizing text...',
          FeatureType.sceneDescription: 'Analyzing scene...',
          FeatureType.objectSearch: 'Analyzing object...',
        }[widget.feature] ??
        'Processing...';
  }

  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10 * widget.slideProgress,
            offset: Offset(0, -2 * widget.slideProgress),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          Expanded(child: _buildScrollableContent()),
          if (!widget.isAnalyzing && widget.contentText != null)
            ActionButtons(
              featureConfig: widget.featureConfig,
              isVoicePlaying: _ttsState == TTSState.playing,
              onPlayPauseVoice: _controlTTS,
              onStopVoice: _stopTTS,
              onCopy: _copyToClipboard,
              onShare: _shareContent,
            ),
        ],
      ),
    );
  }
}

enum TTSState { playing, stopped, paused }
