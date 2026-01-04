import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'screens/splash_screen.dart'; // ✅ ADD THIS
import 'services/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 DO NOT BLOCK APP STARTUP ON NETWORK
  try {
    await ApiConfig.load();
  } catch (e) {
    debugPrint("⚠️ Server offline. App starting in offline mode.");
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const FocusReadApp());
}

class FocusReadApp extends StatelessWidget {
  const FocusReadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Focus Read',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5EFE6),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B4513),
          brightness: Brightness.light,
        ),
      ),

      // 🔥 ONLY CHANGE: Splash → Home handled internally
      home: const SplashScreen(),
    );
  }
}
