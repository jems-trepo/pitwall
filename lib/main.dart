import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'features/live_scoreboard/presentation/screens/live_scoreboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await LiquidGlassWidgets.initialize(
      enablePerformanceMonitor: false,
      warmUpMode: GlassWarmUpMode.never,
    );
  } catch (error, stackTrace) {
    debugPrint('Liquid glass shader prewarm failed: $error\n$stackTrace');
  }
  runApp(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      theme: GlassThemeData.simple(
        blur: 8,
        thickness: 22,
        quality: GlassQuality.minimal,
      ),
      child: const ProviderScope(child: F1ScoreboardApp()),
    ),
  );
}

class F1ScoreboardApp extends StatelessWidget {
  const F1ScoreboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pitwall — F1 Live Timing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080B11),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF5149),
          surface: Color(0xFF111722),
        ),
        useMaterial3: true,
      ),
      home: const LiveScoreboardScreen(),
    );
  }
}
