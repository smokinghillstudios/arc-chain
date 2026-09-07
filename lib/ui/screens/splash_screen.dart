import 'package:flutter/material.dart';

import '../../audio/music.dart';
import '../../controller/progress.dart';
import '../theme.dart';
import 'daily_visit_screen.dart';
import 'level_map_screen.dart';

/// Tela de título — fundo claro, tipografia espaçada e o próprio ícone
/// do app (o mesmo que aparece na tela inicial do aparelho) como logo.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Trilha dos menus (segue tocando na seleção de fases).
    Music.instance.play(MusicTrack.map);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      // SizedBox.expand: o body do Scaffold recebe constraints soltas e a
      // Column encolheria para a largura do filho mais largo (desalinhada).
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            children: [
              const Spacer(flex: 5),
              // Logo: o próprio ícone do app, igual ao da tela inicial do
              // aparelho — mesma imagem usada por flutter_launcher_icons.
              ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: Image.asset(
                  'assets/icon/icon.png',
                  width: 176,
                  height: 176,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'ARC CHAIN',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                  height: 1.05,
                  color: ink.withValues(alpha: 0.92),
                ),
              ),
              const Spacer(flex: 3),
              // Mesmo círculo preto com seta branca do ARCO (splash e CTA
              // genérico de "continuar" nos diálogos de jogo).
              Material(
                color: ink,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {
                    // Visita diária só na 1ª abertura de um novo dia civil
                    // — o resto do dia vai direto pro mapa.
                    final isNewDay = Progress.instance.lastVisitDate !=
                        dailyDateStr(DateTime.now());
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => isNewDay
                            ? const DailyVisitScreen()
                            : const LevelMapScreen(),
                      ),
                    );
                  },
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 26,
                      color: paper,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }
}
