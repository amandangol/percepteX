import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:perceptexx/components/bounding_boxes.dart';
import 'package:perceptexx/components/guide_overlay.dart';
import 'package:perceptexx/features/slidingpanel/custom_slidingpanel.dart';
import 'package:perceptexx/models/recognition_model.dart';
import 'package:perceptexx/models/screen_params_model.dart';
import 'package:perceptexx/services/image_analysis_service.dart';
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
  final ImageAnalysisService imageAnalysisService = ImageAnalysisService();
  // final ObjectSearchService objectSearchService = ObjectSearchService();

  final PanelController _panelController = PanelController();
  double _minHeight = 0.0;
  double _maxHeight = 0.0;
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
  bool isImageSearchRunning = false;
  Map<String, dynamic>? objectSearchResult;
  Map<String, dynamic>? _preservedSearchResult;

  DateTime? lastDetectionTime;
  final double _fixedExposureOffset = 1.0;
  double panelHeightPercentage = 0.4;

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
      bool isAnalyzing = isTextRecognitionRunning ||
          isImageDescriptionRunning ||
          isImageSearchRunning;

      return CustomSlidingPanel(
        panelController: _panelController,
        minHeight: _minHeight,
        maxHeight: _maxHeight,
        feature: widget.feature,
        recognizedTextOutput: recognizedTextOutput,
        sceneDescriptionOutput: sceneDescriptionOutput,
        objectSearchResult: objectSearchResult,
        // onShare: (text) => _shareText(text),
        isAnalyzing: isAnalyzing,
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

  String _getFeatureTitle() {
    switch (widget.feature) {
      case FeatureType.objectDetection:
        return 'Object Detection';
      case FeatureType.textRecognition:
        return 'Text Recognition';
      case FeatureType.sceneDescription:
        return 'Scene Description';
      case FeatureType.objectSearch:
        return 'Search Object';
    }
  }

  String _getFeatureGuide() {
    switch (widget.feature) {
      case FeatureType.objectDetection:
        return 'This feature detects and identifies objects in real-time.\n\n'
            '• Point your camera at objects around you\n'
            '•Press start to identify objects and their locations\n'
            '• Voice feedback will describe what is detected\n'
            '• Use the pause button to freeze detection\n'
            '• Best used in well-lit environments';
      case FeatureType.textRecognition:
        return 'This feature reads text from images.\n\n'
            '• Hold the camera steady pointing at text\n'
            '• Press Read Text to capture and read text\n'
            '• Keep text well-lit and clearly visible\n'
            '• Works best with printed text\n'
            '• Wait for the voice to finish reading';
      case FeatureType.sceneDescription:
        return 'This feature describes the overall scene.\n\n'
            '• Point camera at the scene you want described\n'
            '• Press Describe Scene to capture and analyze\n'
            '• Hold steady while processing\n'
            '• Best for complex scenes or environments\n'
            '• Wait for the complete description';
      case FeatureType.objectSearch:
        return 'This feature identifies objects and finds related information.\n\n'
            '• Point camera at an object you want to learn about\n'
            '• Press Search Objects to capture and analyze the object\n'
            '• View object details and suggested searches\n'
            '• Tap search buttons or image search to find more information\n'
            '• Best used with clear, well-lit objects';
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
      case FeatureType.objectSearch:
        _toggleObjectSearch();
        break;
    }
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
        case FeatureType.objectSearch:
          if (mounted) {
            setState(() {
              isImageSearchRunning = false;
              // objectSearchResult = null;
            });
          }
          break;
      }
    } catch (e) {
      print('Error stopping current feature: $e');
    }
  }

  void _handlePanelAction(Function action) async {
    // Store current result before action
    final currentResult = objectSearchResult;

    // Perform the action
    await action();

    // Restore the result if it was cleared
    if (mounted && currentResult != null) {
      setState(() {
        objectSearchResult = currentResult;
      });
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

  void _toggleObjectSearch() async {
    if (isImageSearchRunning) {
      await _pauseImageSearch();
      return;
    }

    setState(() {
      isImageSearchRunning = true;
      isDetecting = false;
      showTextOutput = true;
      lastDetectionTime = DateTime.now();
    });

    await flutterTts.speak('Analyzing object');
    _subscription?.pause();

    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/temp_image.jpg';
      final XFile imageFile = await _cameraController!.takePicture();
      await File(imageFile.path).copy(imagePath);

      final analysisResult =
          await imageAnalysisService.analyzeObject(File(imagePath));

      if (!mounted) return;

      // Store the result in both state variables
      setState(() {
        objectSearchResult = analysisResult;
        _preservedSearchResult = analysisResult; // Preserve the result
        lastDetectionTime = DateTime.now();
        isImageSearchRunning = false;
      });

      final speechText =
          'I found ${analysisResult['main_object']}. ${analysisResult['description']}';
      await flutterTts.speak(speechText);

      setState(() {
        isVoicePlaying = true;
      });

      flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            isVoicePlaying = false;
          });
        }
      });

      _panelController.open();
    } catch (e) {
      // Handle errors...
      print('Error in object search: $e');
      // Update error states similarly
      final errorResult = {
        'main_object': 'Error',
        'description': 'An unexpected error occurred. Please try again.',
        'search_keywords': [],
        'suggested_queries': []
      };

      if (mounted) {
        setState(() {
          objectSearchResult = errorResult;
          _preservedSearchResult = errorResult;
          lastDetectionTime = DateTime.now();
          isImageSearchRunning = false;
        });
      }
    } finally {
      _subscription?.resume();
    }
  }

  void _toggleTextRecognition() async {
    if (isTextRecognitionRunning) {
      await _pauseTextRecognition();
      return;
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

    if (!mounted) return;

    setState(() {
      recognizedTextOutput = recognizedText?.isNotEmpty == true
          ? recognizedText
          : 'No text recognized';
      lastDetectionTime = DateTime.now();
      isTextRecognitionRunning = false; // Clear loading state
    });

    if (recognizedText?.isNotEmpty == true) {
      await flutterTts.speak(recognizedText!);
      setState(() {
        isVoicePlaying = true;
      });

      flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            isVoicePlaying = false;
          });
        }
      });

      _panelController.open();
    } else {
      await flutterTts.speak("No text recognized");
    }

    _subscription?.resume();
  }

  void _toggleImageDescription() async {
    if (isImageDescriptionRunning) {
      await _pauseImageDescription();
      return;
    }

    setState(() {
      isImageDescriptionRunning = true;
      isDetecting = false;
      showTextOutput = true;
      lastDetectionTime = DateTime.now();
    });

    await flutterTts.speak('Scene description starting');
    _subscription?.pause();

    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/temp_image.jpg';
      final XFile imageFile = await _cameraController!.takePicture();
      await File(imageFile.path).copy(imagePath);

      final description =
          await imageAnalysisService.describeImage(File(imagePath));

      if (!mounted) return;

      setState(() {
        sceneDescriptionOutput = description;
        lastDetectionTime = DateTime.now();
        isImageDescriptionRunning = false;
      });

      await flutterTts.speak(description);
      setState(() {
        isVoicePlaying = true;
      });

      flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            isVoicePlaying = false;
          });
        }
      });

      _panelController.open();
    } on ImageAnalysisException catch (e) {
      print('Error describing the image: $e');
      if (mounted) {
        setState(() {
          sceneDescriptionOutput = e.userFriendlyMessage;
          lastDetectionTime = DateTime.now();
          isImageDescriptionRunning = false;
        });
        await flutterTts.speak(e.userFriendlyMessage);

        // If it's a server error, show a snackbar
        if (e.isServerError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.userFriendlyMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ));
        }
      }
    } catch (e) {
      print('Unexpected error: $e');
      if (mounted) {
        setState(() {
          sceneDescriptionOutput =
              'An unexpected error occurred. Please try again.';
          lastDetectionTime = DateTime.now();
          isImageDescriptionRunning = false;
        });
        await flutterTts
            .speak('An unexpected error occurred. Please try again.');
      }
    } finally {
      _subscription?.resume();
    }
  }

  Future<void> _pauseImageSearch() async {
    print('Pausing object search');
    await flutterTts.stop();
    setState(() {
      isImageSearchRunning = false;
    });
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
    print('Pausing scene description');
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
        // Restore the object search result if it exists
        if (_preservedSearchResult != null) {
          setState(() {
            objectSearchResult = _preservedSearchResult;
          });
        }
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCurrentFeature();
    _cameraController?.dispose();
    _detector?.stop();
    _subscription?.cancel();
    textRecognitionTTS.dispose();
    _panelController.close();
    flutterTts.stop();
    super.dispose();
  }
}
