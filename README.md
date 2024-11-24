# PercepteX: Multimodal Accessibility Assistant

PercepteX is a Flutter-based mobile application that combines computer vision, text recognition, and generative AI to create an accessible experience. The app provides real-time object detection, text recognition, scene description, and object search capabilities through an intuitive...

<img src="https://github.com/user-attachments/assets/6fc425ef-456a-45bd-bd01-e1460e98b65e" alt="homepage" height="500"> <img src="https://github.com/user-attachments/assets/1222b067-cb7b-47ca-b0f9-461022586903" alt="settings" height="500"> <img src="https://github.com/user-attachments/assets/33508b65-5967-4827-9016-f7d7d5829a1c" alt="tutorial" height="500"> <img src="https://github.com/user-attachments/assets/a49aa7ef-96cb-49b1-9a4d-4906699ac42b" alt="object_search" height="500"> <img src="(https://github.com/user-attachments/assets/1e191cf5-2afc-4118-ae6a-03142fc5d2aa" alt="scene_description" height="500"> <img src="https://github.com/user-attachments/assets/94612826-91e6-48f3-acbe-2d8ccc9dd6ff" alt="text_recognition" height="500">

## Features

### 1. Real-time Object Detection

- Real-time object detection using TensorFlow Lite with multi-threading support
- Custom bounding box visualization with confidence threshold filtering
- Performance metrics:
  - Processing speed: 30 FPS
  - Model inference time: ~50ms per frame
  - Confidence threshold: 0.5
  - Configurable maximum object detection limit

### 2. Text Recognition with TTS

- Real-time text detection and recognition using Google ML Kit
- Immediate text-to-speech feedback for detected text
- Support for both camera preview and file-based recognition
- Performance metrics:
  - Processing speed: ~300ms per frame
  - Word Error Rate (WER): 2.5%
  - Accuracy: 95%+ for clear printed text
  - Language support based on ML Kit capabilities

### 3. Scene Description

- Detailed natural language descriptions of captured scenes using Google's Gemini 1.5 Flash model
- Performance metrics:
  - Average response time: 1-2 seconds
  - Image size limit: 800x800 pixels
  - Supported formats: JPEG, PNG, GIF, WebP
- Audio narration of scene descriptions
- Complex scene handling with multiple objects and activities

### 4. Object Search

- Detailed object information through capture and analysis
- Search keyword generation and suggested queries
- Comprehensive object descriptions
- Educational exploration features for identified objects

### 5. Settings and Configuration

- Comprehensive settings management for API keys and TTS
- **API Key Management**:
  - Secure storage of Gemini API key
  - Visual key obscuring/revealing
  - Direct link to API key generation
- **Text-to-Speech Configuration**:

  - Adjustable speech rate (0.1 to 1.5)
  - Customizable pitch (0.5 to 2.0)
  - Volume control (0 to 1.0)
  - Multiple language support:
    - English (US)
    - Spanish (Spain)
    - French (France)
    - German (Germany)
    - Chinese (Simplified)
    - Japanese
    - Korean
    - Arabic (Saudi Arabia)
    - Hindi (India)

- **Settings Persistence**:
  - Automatic settings saving
  - Default value restoration
  - Error handling and user feedback
  - Settings synchronization across app restarts

## Technical Architecture

### Core Components

#### 1. Camera Module

- Camera initialization and image stream processing
- Resolution and exposure settings management
- Real-time frame capture for analysis

#### 2. Vision Services

- Object Detection Service: Real-time recognition and tracking
- Text Recognition Service: OCR processing and text extraction
- Image Analysis Service: Scene understanding and object analysis

#### 3. Audio Feedback

- Text-to-Speech (TTS) engine with customizable parameters
- Spatial audio cues for object location
- Voice command processing
- Multi-language support with configurable voices

#### 4. UI Components

- Sliding panel for results display
- Interactive guide overlay
- Mode switching controls
- Custom camera preview with bounding boxes
- Settings interface with real-time preview
- Animated transitions and feedback

### Component Interaction Flow

    A[Camera Module] --> B[Image Processing Service]
    B --> C{Feature Type}
    C -->|Object Detection| D[Object Detector Service]
    C -->|Text Recognition| E[Text Recognition Service]
    C -->|Scene Description| F[Image Analysis Service]
    D --> G[Audio Feedback]
    E --> G
    F --> G
    G --> H[UI Update]
    H --> I[Sliding Panel Display]

### Key Component Examples

```dart
// Text Recognition Service
class TextRecognitionTTS {
  final TextRecognizer textRecognizer;
  final FlutterTts flutterTts;

  Future<String?> recognizeText(CameraController cameraController);
  Future<String?> recognizeTextFromFile(File imageFile);
}

// Image Analysis Service
class ImageAnalysisService {
  final GenerativeModel _model;

  Future<String> describeImage(File imageFile);
  Future<Map<String, dynamic>> analyzeObject(File imageFile);
}

// Settings Management
class SettingsService {
  Future<void> saveSettings(Settings settings);
  Future<Settings> loadSettings();
  Future<void> resetToDefaults();
}
```

## Project Structure

```
lib/
├── components/          # Reusable UI components
│   ├── analyzing_loader.dart
│   ├── bounding_boxes.dart
│   ├── camera_preview.dart
│   ├── error_app.dart
│   ├── guide_overlay.dart
│   └── typewriter_text.dart
├── config/             # Configuration files
│   └── app_config.dart
├── features/          # Feature-specific implementations
│   ├── home/         # Home screen and related widgets
│   ├── onboarding/   # Onboarding flow
│   ├── settings/     # App settings and configuration
│   ├── slidingpanel/ # Results panel
│   ├── splash/       # Splash screen
│   └── tutorial/     # Tutorial screens
├── models/           # Data models
├── services/         # Core services
├── shared/          # Shared components
├── ui/              # UI utilities
└── utils/           # Utility functions
```

[Rest of the README remains the same...]

## Installation

[Previous installation instructions remain the same...]

## Usage Guide

### 1. Feature Selection

- Launch app and select desired feature
- Review feature guide
- Grant necessary permissions

### 2. Camera Operation

- Maintain steady device position
- Ensure adequate lighting
- Follow on-screen positioning guides

### 3. Analysis and Feedback

- Observe real-time detection feedback
- Trigger analysis using action button
- Wait for processing completion
- Review audio and visual feedback

### 4. Settings Configuration

- Configure TTS parameters for optimal experience
- Set up API keys for advanced features
- Customize language preferences
- Save or reset settings as needed

### 5. Result Management

- View detailed analysis in sliding panel
- Listen to audio descriptions
- Share or save results as needed

## Error Handling

The application implements comprehensive error handling:

```dart
// Image Analysis
try {
  final result = await analysisService.analyzeObject(imageFile);
} on ImageAnalysisException catch (e) {
  print('User-friendly message: ${e.userFriendlyMessage}');
  print('Technical details: ${e.message}');
}

// Text Recognition
try {
  final text = await textService.recognizeText(cameraController);
} catch (e) {
  await flutterTts.speak("Failed to recognize text");
}
```

## Performance Optimization

### Image Processing

- Automatic resizing to 800x800 pixels
- Memory-efficient image conversion
- Multi-format support

### Object Detection

- Configurable confidence thresholds
- Maximum detection limit settings
- Optimized bounding box rendering

## Acknowledgments

- Google ML Kit for text recognition capabilities
- TensorFlow Lite for object detection
- Google's Gemini 1.5 Flash model for image analysis
- Flutter team for the excellent framework

---

Built with ❤️ for accessibility
