import 'package:flutter/material.dart';

import '../../audio/music.dart';
import '../../core/engine.dart';
import '../theme.dart';
import '../widgets/arc_ring.dart';
import 'level_map_screen.dart';

/// Tela de título — mesmo estilo minimalista do ARCO: fundo claro,
/// tipografia espaçada e um anel de arcos segmentado como logo, nas
/// cores das cadeias do Arc Chain.
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
              // Logo: anel de arcos nas cores das cadeias com o título dentro.
              SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(painter: _ArcRingPainter()),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ARC',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 8,
                            height: 1.05,
                            color: ink.withValues(alpha: 0.92),
                          ),
                        ),
                        Text(
                          'CHAIN',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 8,
                            height: 1.05,
                            color: ink.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              // Mesmo círculo preto com seta branca do ARCO (splash e CTA
              // genérico de "continuar" nos diálogos de jogo).
              Material(
                color: ink,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LevelMapScreen()),
                  ),
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

/// Anel de arcos segmentados nas cores das cadeias — o motivo do jogo
/// destilado num único símbolo (mesmo logo da splash do ARCO).
class _ArcRingPainter extends CustomPainter {
  const _ArcRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    paintArcRing(canvas, size.center(Offset.zero), size.width,
        colors: chainColors);
  }

  @override
  bool shouldRepaint(_ArcRingPainter oldDelegate) => false;
}
