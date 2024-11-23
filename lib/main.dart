import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:perceptexx/components/error_app.dart';
import 'package:perceptexx/config/app_config.dart';
import 'package:perceptexx/features/splash/splash_screen.dart';

void main() async {
  // Ensuring all necessary async operations are completed before running the app.
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize AppConfig first to load environment variables
    await AppConfig.initialize();

    // Lock screen orientation to portrait only.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

    // Run the app once initialization is complete.
    runApp(const MyApp());
  } catch (e) {
    print('Failed to initialize app: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Perceptex',
      theme: ThemeData(
        primaryColor: Colors.blue[900],
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
