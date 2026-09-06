import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads/ads_service.dart';
import 'audio/music.dart';
import 'audio/sfx.dart';
import 'controller/progress.dart';
import 'ui/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Progress.instance.load();
  Sfx.instance.enabled = await Progress.instance.loadSoundEnabled();
  Music.instance.enabled = await Progress.instance.loadMusicEnabled();
  AdsService.instance.init(); // pré-carrega o rewarded em segundo plano
  runApp(const ArcChainApp());
}

class ArcChainApp extends StatelessWidget {
  const ArcChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arc Chain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF3F6A88),
        fontFamily: 'Nunito',
      ),
      home: const SplashScreen(),
    );
  }
}
