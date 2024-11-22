import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:perceptexx/components/bounding_boxes.dart';
import 'package:perceptexx/components/custom_slidingpanel.dart';
import 'package:perceptexx/components/guide_overlay.dart';
import 'package:perceptexx/models/recognition_model.dart';
import 'package:perceptexx/models/screen_params_model.dart';
import 'package:perceptexx/services/api_service.dart';
import 'package:perceptexx/services/object_detector_service.dart';
import 'package:perceptexx/services/text_recognition_service.dart';
import 'package:perceptexx/shared/control_button_widget.dart';
import 'package:perceptexx/shared/custom_app_bar.dart';
import 'package:perceptexx/utils/feature_type.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../components/camera_preview.dart';

class FeatureDetector extends StatefulWidget {
  final FeatureType feature;
  final VoidCallback onBack;

  const FeatureDetector({
    Key? key,
    required this.feature,
    required this.onBack,
  }) : super(key: key);

  @override
  _FeatureDetectorWidgetState createState() => _FeatureDetectorWidgetState();
}

class _FeatureDetectorWidgetState extends State<FeatureDetector>
    with WidgetsBindingObserver {
  late List<CameraDescription> cameras;
  CameraController? _cameraController;
  get _controller => _cameraController;
  Detector? _detector;
  StreamSubscription? _subscription;
  List<Recognition>? results;
  Map<String, String>? stats;
  final FlutterTts flutterTts = FlutterTts();
  final TextRecognitionTTS textRecognitionTTS = TextRecognitionTTS();
  final ApiService apiService = ApiService();
  final PanelController _panelController = PanelController();
  double _minHeight = 0.0;
  double _maxHeight = 0.0;
  final bool _isPanelOpen = false;
  bool _isInitialized = false;

  bool isDetecting = false;
  bool isSpeaking = false;
  bool isPaused = true;
  bool isTextRecognitionRunning = false;
  bool isImageDescriptionRunning = false;
  bool showGuide = true;
  String? recognizedTextOutput;
  String? sceneDescriptionOutput;
  bool showTextOutput = false;
  bool isTextPanelExpanded = false;
  bool isVoicePlaying = false;

  DateTime? lastDetectionTime;
  final double _fixedExposureOffset = 1.0;
  double panelHeightPercentage = 0.4;

  String get featureTitle {
    switch (widget.feature) {
      case FeatureType.objectDetection:
        return 'Object Detection';
      case FeatureType.textRecognition:
        return 'Text Recognition';
      case FeatureType.sceneDescription:
        return 'Scene Description';
    }
  }

  String get featureGuide {
    switch (widget.feature) {
      case FeatureType.objectDetection:
        return 'This feature detects and identifies objects in real-time.\n\n'
            '• Point your camera at objects around you\n'
            '• The app will identify objects and their locations\n'
            '• Voice feedback will describe what is detected\n'
            '• Use the pause button to freeze detection\n'
            '• Best used in well-lit environments';
      case FeatureType.textRecognition:
        return 'This feature reads text from images.\n\n'
            '• Hold the camera steady pointing at text\n'
            '• Press start to capture and read text\n'
            '• Keep text well-lit and clearly visible\n'
            '• Works best with printed text\n'
            '• Wait for the voice to finish reading';
      case FeatureType.sceneDescription:
        return 'This feature describes the overall scene.\n\n'
            '• Point camera at the scene you want described\n'
            '• Press start to capture and analyze\n'
            '• Hold steady while processing\n'
            '• Best for complex scenes or environments\n'
            '• Wait for the complete description';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'guide_shown_${widget.feature.toString()}';

    bool hasShownGuide = prefs.getBool(key) ?? false;

    setState(() {
      showGuide = !hasShownGuide;
    });
  }

  void _handleGuideClose() {
    _saveGuideShown();
    setState(() {
      showGuide = false;
      if (widget.feature == FeatureType.objectDetection) {
        isPaused = false;
        isDetecting = true;
      }
    });
  }

  Future<void> _saveGuideShown() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'guide_shown_${widget.feature.toString()}';
    await prefs.setBool(key, true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _minHeight = MediaQuery.of(context).size.height * 0.3;
      _maxHeight = MediaQuery.of(context).size.height * 0.9;
      _initializeCamera();
      if (widget.feature == FeatureType.objectDetection) {
        _initObjectDetection();
      }
      _isInitialized = true;
    }
  }

  void _initStateAsync() async {
    await _initializeCamera();
    if (widget.feature == FeatureType.objectDetection) {
      _initObjectDetection();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      await _cameraController!.startImageStream(onLatestImageAvailable);

      if (mounted) {
        setState(() {
          ScreenParams.previewSize = _controller.value.previewSize!;
          ScreenParams.screenPreviewSize = MediaQuery.of(context).size;
        });
      }

      await _controller.setExposureOffset(_fixedExposureOffset);
      await _controller.setExposureMode(ExposureMode.auto);
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _initObjectDetection() {
    Detector.start().then((instance) {
      setState(() {
        _detector = instance;
        _subscription = instance.resultsStream.stream.listen((values) {
          if (isDetecting && !isPaused) {
            setState(() {
              results = values['recognitions'];
              stats = values['stats'];
            });
            _processDetections();
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_controller.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    CustomSlidingPanel buildSlidingPanel() {
      return CustomSlidingPanel(
        panelController: _panelController,
        minHeight: _minHeight,
        maxHeight: _maxHeight,
        feature: widget.feature,
        recognizedTextOutput: recognizedTextOutput,
        sceneDescriptionOutput: sceneDescriptionOutput,
        lastDetectionTime: lastDetectionTime,
        onCopy: (text) => _copyToClipboard(text),
        onShare: (text) => _shareText(text),
        isVoicePlaying: isVoicePlaying,
        onPlayPauseVoice: _toggleVoicePlayback,
        onStopVoice: _stopVoicePlayback,
      );
    }

    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        body: Stack(
          children: [
            // Camera Preview
            CustomCameraPreview(cameraController: _controller),

            // Bounding Boxes
            if (widget.feature == FeatureType.objectDetection && !showGuide)
              CustomBoundingBoxes(results: results),

            // Top Bar with Controls
            CustomFeatureAppBar(
              featureTitle: _getFeatureTitle(),
              onBack: () => _handleBackPress(),
              onHelpPressed: () => setState(() => showGuide = !showGuide),
            ),
            // Guide Overlay
            if (showGuide)
              GuideOverlay(
                featureTitle: _getFeatureTitle(),
                featureGuide: _getFeatureGuide(),
                onGetStarted: _handleGuideClose,
              ),

            // Sliding Panel
            if (showTextOutput) buildSlidingPanel(),
            // Controls (positioning adjusted for panel)
            Positioned(
              bottom: showTextOutput
                  ? MediaQuery.of(context).size.height *
                      0.1 // Adjust based on panel height
                  : 32,
              left: 16,
              right: 16,
              child: AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                bottom: showTextOutput
                    ? MediaQuery.of(context).size.height *
                        0.1 // Dynamic positioning
                    : 32,
                left: 16,
                right: 16,
                child: CustomControlButton(
                  feature: widget.feature,
                  isPaused: isPaused,
                  isTextRecognitionRunning: isTextRecognitionRunning,
                  isImageDescriptionRunning: isImageDescriptionRunning,
                  showTextOutput: showTextOutput,
                  onPressed: _handleControlButtonPress,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleVoicePlayback() async {
    if (isVoicePlaying) {
      await flutterTts.pause();
      setState(() {
        isVoicePlaying = false;
      });
    } else {
      // Resume or replay the last output
      if (widget.feature == FeatureType.textRecognition &&
          recognizedTextOutput != null) {
        await flutterTts.speak(recognizedTextOutput!);
        setState(() {
          isVoicePlaying = true;
        });
      } else if (widget.feature == FeatureType.sceneDescription &&
          sceneDescriptionOutput != null) {
        await flutterTts.speak(sceneDescriptionOutput!);
        setState(() {
          isVoicePlaying = true;
        });
      }
    }

    // Listen for completion of speech
    flutterTts.setCompletionHandler(() {
      setState(() {
        isVoicePlaying = false;
      });
    });
  }

  void _stopVoicePlayback() async {
    await flutterTts.stop();
    setState(() {
      isVoicePlaying = false;
    });
  }

  String _getFeatureTitle() {
    switch (widget.feature) {
      case FeatureType.objectDetection:
        return 'Object Detection';
      case FeatureType.textRecognition:
        return 'Text Recognition';
      case FeatureType.sceneDescription:
        return 'Scene Description';
    }
  }

  String _getFeatureGuide() {
    switch (widget.feature) {
      case FeatureType.objectDetection:
        return 'This feature detects and identifies objects in real-time.\n\n'
            '• Point your camera at objects around you\n'
            '• The app will identify objects and their locations\n'
            '• Voice feedback will describe what is detected\n'
            '• Use the pause button to freeze detection\n'
            '• Best used in well-lit environments';
      case FeatureType.textRecognition:
        return 'This feature reads text from images.\n\n'
            '• Hold the camera steady pointing at text\n'
            '• Press start to capture and read text\n'
            '• Keep text well-lit and clearly visible\n'
            '• Works best with printed text\n'
            '• Wait for the voice to finish reading';
      case FeatureType.sceneDescription:
        return 'This feature describes the overall scene.\n\n'
            '• Point camera at the scene you want described\n'
            '• Press start to capture and analyze\n'
            '• Hold steady while processing\n'
            '• Best for complex scenes or environments\n'
            '• Wait for the complete description';
    }
  }

  void _handleControlButtonPress() {
    switch (widget.feature) {
      case FeatureType.objectDetection:
        _toggleObjectDetection();
        break;
      case FeatureType.textRecognition:
        _toggleTextRecognition();
        break;
      case FeatureType.sceneDescription:
        _toggleImageDescription();
        break;
    }
  }

  void _shareText(String text) {
    try {
      Share.share(text, subject: 'Perceptex Detection Result');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Text('Unable to share text'),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 8),
          Text('Copied to clipboard'),
        ],
      ),
      backgroundColor: const Color(0xFF16A085),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void onLatestImageAvailable(CameraImage cameraImage) {
    if (widget.feature == FeatureType.objectDetection) {
      _detector?.processFrame(cameraImage);
    }
  }

  Future<bool> _handleBackPress() async {
    await _stopCurrentFeature();

    // Only call onBack if the widget is still in the widget tree
    if (mounted) {
      widget.onBack();
    }

    return false;
  }

  Future<void> _stopCurrentFeature() async {
    try {
      // Stop any ongoing TTS
      await flutterTts.stop();

      // Check if the widget is still mounted before calling setState
      if (!mounted) return;

      switch (widget.feature) {
        case FeatureType.objectDetection:
          if (mounted) {
            setState(() {
              isDetecting = false;
              isPaused = true;
            });
          }
          break;
        case FeatureType.textRecognition:
          if (mounted) {
            setState(() {
              isTextRecognitionRunning = false;
            });
          }
          break;
        case FeatureType.sceneDescription:
          if (mounted) {
            setState(() {
              isImageDescriptionRunning = false;
            });
          }
          break;
      }
    } catch (e) {
      print('Error stopping current feature: $e');
    }
  }

  String _getPosition(double left, double right) {
    double screenWidth = ScreenParams.screenPreviewSize.width;
    double objectMidPoint = (left + right) / 2;

    if (objectMidPoint < screenWidth * 0.4) {
      return "on the left";
    } else if (objectMidPoint > screenWidth * 0.6) {
      return "on the right";
    } else {
      return "in front";
    }
  }

  void _processDetections() async {
    if (results == null || results!.isEmpty || isSpeaking) return;

    StringBuffer sb = StringBuffer();
    for (var result in results!) {
      String position =
          _getPosition(result.renderLocation.left, result.renderLocation.right);
      sb.write("${result.label} detected $position. ");
    }

    isSpeaking = true;
    await flutterTts.speak(sb.toString());
    isSpeaking = false;

    setState(() {
      isDetecting = false;
    });
    await Future.delayed(const Duration(seconds: 5));
    if (!isPaused) {
      setState(() {
        isDetecting = true;
      });
    }
  }

  void _toggleObjectDetection() async {
    setState(() {
      isPaused = !isPaused;
    });

    if (isPaused) {
      await _pauseDetection();
      await flutterTts.speak("Object detection paused");
    } else {
      await flutterTts.speak("Object detection starting");
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        isDetecting = true;
      });
    }
  }

  void _toggleTextRecognition() async {
    if (isTextRecognitionRunning) {
      await _pauseTextRecognition();
      return;
    }

    if (showTextOutput && _isPanelOpen) {
      _panelController.close();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      isTextRecognitionRunning = true;
      isDetecting = false;
      showTextOutput = true;
      lastDetectionTime = DateTime.now();
    });

    await flutterTts.speak('Text detection starting');
    _subscription?.pause();

    String? recognizedText =
        await textRecognitionTTS.recognizeText(_cameraController!);
    if (recognizedText!.isNotEmpty) {
      setState(() {
        recognizedTextOutput = recognizedText;
        lastDetectionTime = DateTime.now();
      });

      // Only speak if text is not empty and not already spoken during recognition
      await flutterTts.speak(recognizedText);
      setState(() {
        isVoicePlaying = true;
      });
      flutterTts.setCompletionHandler(() {
        setState(() {
          isVoicePlaying = false;
        });
      });
      _panelController.open();
    } else {
      setState(() {
        recognizedTextOutput = 'No text recognized';
        lastDetectionTime = DateTime.now();
      });
      await flutterTts.speak("No text recognized");
    }

    setState(() {
      isTextRecognitionRunning = false;
    });
    _subscription?.resume();
  }

  void _toggleImageDescription() async {
    if (isImageDescriptionRunning) {
      await _pauseImageDescription();
      return;
    }

    if (showTextOutput && _isPanelOpen) {
      _panelController.close();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      isImageDescriptionRunning = true;
      isDetecting = false;
      showTextOutput = true;
      lastDetectionTime = DateTime.now();
    });

    await flutterTts.speak('Image description starting');
    _subscription?.pause();

    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/temp_image.jpg';
      final XFile imageFile = await _cameraController!.takePicture();

      await File(imageFile.path).copy(imagePath);

      final description = await apiService.describeImage(File(imagePath));
      setState(() {
        sceneDescriptionOutput = description;
        lastDetectionTime = DateTime.now();
      });
      await flutterTts.speak(description);
      setState(() {
        isVoicePlaying = true;
      });
      flutterTts.setCompletionHandler(() {
        setState(() {
          isVoicePlaying = false;
        });
      });
      _panelController.open();
    } catch (e) {
      print('Error describing the image: $e');
      setState(() {
        sceneDescriptionOutput = 'Error describing the image';
        lastDetectionTime = DateTime.now();
      });
      await flutterTts.speak('Error describing the image');
    }

    setState(() {
      isImageDescriptionRunning = false;
    });
    _subscription?.resume();
  }

  Future<void> _speakTextInLanguage(String text, String languageCode) async {
    // Configure TTS for specific language
    await flutterTts.setLanguage(languageCode);
    await flutterTts.speak(text);

    // Reset to default language after speaking
    await flutterTts.setLanguage('en-US');
  }

  Future<void> _pauseDetection() async {
    print('Pausing detection');
    await flutterTts.stop();
    setState(() {
      isDetecting = false;
    });
  }

  Future<void> _pauseTextRecognition() async {
    print('Pausing text recognition');
    await flutterTts.stop();
    setState(() {
      isTextRecognitionRunning = false;
    });
  }

  Future<void> _pauseImageDescription() async {
    print('Pausing image description');
    await flutterTts.stop();
    setState(() {
      isImageDescriptionRunning = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        await _stopCurrentFeature();
        _cameraController?.stopImageStream();
        _detector?.stop();
        _subscription?.cancel();
        break;
      case AppLifecycleState.resumed:
        _initStateAsync();
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Safely stop current feature
    _stopCurrentFeature();

    // Null-safe disposal of resources
    _cameraController?.dispose();
    _detector?.stop();
    _subscription?.cancel();
    textRecognitionTTS.dispose();

    // Safely close panel
    _panelController.close();
    flutterTts.stop();

    super.dispose();
  }
}
