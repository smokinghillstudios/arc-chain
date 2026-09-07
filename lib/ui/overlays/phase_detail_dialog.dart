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

/// Porte do detalhe de fase do ARCO — sem palavras, só números:
/// cabeçalho com o número da fase, as cores do desafio, uma escada de
/// estrelas (1★/2★/3★, cada uma com seu teto de toques) e as ações
/// jogar/voltar.
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < level.chains; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.5),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: chainColors[i],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 0),
              child: _StarLadder(board: board),
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

/// Escada de estrelas: uma linha por patamar (1★/2★/3★), cada uma com o
/// teto de toques daquele patamar — mesma fonte de verdade de
/// `GameScreen._computeStars`. Sem símbolo nem rótulo, só o número.
class _StarLadder extends StatelessWidget {
  final GameBoard board;
  const _StarLadder({required this.board});

  @override
  Widget build(BuildContext context) {
    final threeStars = board.minTaps;
    final twoStars =
        (board.minTaps + (board.maxTaps - board.minTaps) * 0.5).floor();
    final oneStar = board.maxTaps;
    final rows = [(1, oneStar), (2, twoStars), (3, threeStars)];

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          _StarLadderRow(
            filled: rows[i].$1,
            value: rows[i].$2,
            emphasize: i == rows.length - 1,
          ),
        ],
      ],
    );
  }
}

class _StarLadderRow extends StatelessWidget {
  final int filled;
  final int value;
  final bool emphasize;
  const _StarLadderRow(
      {required this.filled, required this.value, required this.emphasize});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(right: 1),
            child: Icon(
              i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 15,
              color: i < filled
                  ? const Color(0xFFC79A0A)
                  : const Color(0xFFC79A0A).withValues(alpha: 0.3),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: CustomPaint(painter: _DottedLinePainter(), size: const Size(double.infinity, 1)),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$value',
          style: TextStyle(
            fontSize: emphasize ? 19 : 17,
            fontWeight: FontWeight.w900,
            color: emphasize ? headerDark : ink,
          ),
        ),
      ],
    );
  }
}

/// Linha pontilhada fina, ligando as estrelas ao número na escada.
class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 3.0;
    const dashGap = 3.0;
    final paint = Paint()
      ..color = ink.withValues(alpha: 0.14)
      ..strokeWidth = 1.5;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter oldDelegate) => false;
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
