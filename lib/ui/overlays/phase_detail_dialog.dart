import 'package:flutter/material.dart';

import '../../core/engine.dart';
import '../theme.dart';

/// Abre o detalhe da fase (identificação visual, no padrão do ARCO).
/// Retorna true se o jogador tocou em "jogar".
Future<bool?> showPhaseDetailDialog(BuildContext context,
    {required LevelDef level}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => PhaseDetailDialog(level: level),
  );
}

/// Porte do detalhe de fase do ARCO — sem palavras, só números/ícones:
/// cabeçalho com o número da fase, previews de desafio (cadeias, tabuleiro,
/// toques, toques para 3 estrelas) e as ações jogar/voltar.
class PhaseDetailDialog extends StatelessWidget {
  final LevelDef level;
  const PhaseDetailDialog({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    // Gera o tabuleiro (determinístico por seed) só para exibir os números
    // reais da fase — mesma fonte de verdade do jogo.
    final board = GameBoard.generate(level);

    return Dialog(
      backgroundColor: const Color(0xFFFAFAF8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho — só o número da fase, centralizado.
            Container(
              color: headerDark,
              height: 98,
              alignment: Alignment.center,
              child: Text(
                '${level.id}',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoPreview(
                      icon: Icons.link_rounded,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < level.chains; i++)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2.5),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: chainColors[i],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    const _ObjectiveDivider(),
                    const SizedBox(width: 18),
                    _InfoPreview(
                      icon: Icons.grid_4x4_rounded,
                      child: Text(
                        '${level.cols}×${level.rows}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF536F84),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    const _ObjectiveDivider(),
                    const SizedBox(width: 18),
                    _InfoPreview(
                      icon: Icons.touch_app_rounded,
                      child: Text(
                        '≤ ${board.maxTaps}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF536F84),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded,
                      size: 13, color: Color(0xFFC79A0A)),
                  const SizedBox(width: 4),
                  Text(
                    '${board.minTaps}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFC79A0A),
                    ),
                  ),
                ],
              ),
            ),
            // Ações: voltar (seta) e jogar (triângulo), sem texto.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 24),
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 52,
                      child: Material(
                        color: btnBg,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(false),
                          customBorder: const CircleBorder(),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Material(
                        color: playGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(true),
                          customBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Center(child: _PlayTriangle()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Valor + ícone em coluna, como os previews de objetivo do ARCO.
class _InfoPreview extends StatelessWidget {
  final IconData icon;
  final Widget child;
  const _InfoPreview({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 26, child: Center(child: child)),
        const SizedBox(height: 5),
        Icon(icon, size: 12, color: const Color(0xFF90A0AA)),
      ],
    );
  }
}

/// Barra vertical fina que separa os previews de desafio — só do topo até o
/// fim da linha de valores (26px), sem descer até a linha do ícone.
class _ObjectiveDivider extends StatelessWidget {
  const _ObjectiveDivider();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 1.5,
        height: 26,
        color: ink.withValues(alpha: 0.14),
      ),
    );
  }
}

/// Triângulo branco (▶) usado no botão "jogar" no lugar do ícone padrão.
class _PlayTriangle extends StatelessWidget {
  const _PlayTriangle();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(18, 22),
      painter: _PlayTrianglePainter(),
    );
  }
}

class _PlayTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PlayTrianglePainter oldDelegate) => false;
}
