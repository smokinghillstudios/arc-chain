import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/engine.dart';

/// Tamanho de célula de referência (o canvas é escalado para o widget).
const double kCell = 46;

const colorArc = Color(0xFF3A5F7A);
final colorArcDim = colorArc.withAlpha(0x55);

class ActiveArc {
  final int idx;
  final Color color;
  ActiveArc(this.idx, this.color);
}

class Particle {
  double x, y, vx, vy, life;
  final double maxLife, size;
  final Color color;
  Particle(
      {required this.x,
      required this.y,
      required this.vx,
      required this.vy,
      required this.life,
      required this.maxLife,
      required this.color,
      required this.size});
}

class _ArcDef {
  final bool straight;
  final bool split;
  final double cx, cy, sa, ea;
  final double x1, y1, x2, y2, x3, y3, x4, y4;
  const _ArcDef.arc(this.cx, this.cy, this.sa, this.ea)
      : straight = false,
        split = false,
        x1 = 0, y1 = 0, x2 = 0, y2 = 0, x3 = 0, y3 = 0, x4 = 0, y4 = 0;
  const _ArcDef.line(this.x1, this.y1, this.x2, this.y2)
      : straight = true,
        split = false,
        cx = 0, cy = 0, sa = 0, ea = 0,
        x3 = 0, y3 = 0, x4 = 0, y4 = 0;
  const _ArcDef.splitLine(
      this.x1, this.y1, this.x2, this.y2, this.x3, this.y3, this.x4, this.y4)
      : straight = true,
        split = true,
        cx = 0, cy = 0, sa = 0, ea = 0;
}

Map<String, List<_ArcDef>> _arcDefs(double s) {
  final mid = s / 2;
  return {
    'A': [
      _ArcDef.arc(0, 0, 0, math.pi / 2),
      _ArcDef.arc(s, s, math.pi, 3 * math.pi / 2),
    ],
    'B': [
      _ArcDef.arc(s, 0, math.pi / 2, math.pi),
      _ArcDef.arc(0, s, 3 * math.pi / 2, 2 * math.pi),
    ],
    'D': [
      _ArcDef.line(0, mid, s, mid),
      _ArcDef.splitLine(mid, 0, mid, mid * 0.72, mid, mid * 1.28, mid, s),
    ],
  };
}

class BoardPainter extends CustomPainter {
  final GameBoard board;
  final Map<String, List<ActiveArc>> highlighted;
  final List<Particle> particles;

  BoardPainter({
    required this.board,
    required this.highlighted,
    required this.particles,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final rows = board.rows;
    final cols = board.cols;
    // Um único fator de escala (as células continuam quadradas — senão os
    // arcos, desenhados como círculos de verdade, ficariam ovais); quem
    // decide o tamanho retangular real do canvas é o chamador.
    final scale = size.width / (cols * kCell);
    canvas.save();
    canvas.scale(scale);

    final startInfo = {for (final ch in board.chains) ch.start.key: ch};
    final endInfo = {for (final ch in board.chains) ch.end.key: ch};

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final px = c * kCell, py = r * kCell;
        final type = board.grid[r][c];
        final isRotatable = type == 'A' || type == 'B';
        final key = '$r,$c';
        final startCh = startInfo[key];
        final endCh = endInfo[key];
        final connected = endCh?.success ?? false;

        final rrect = RRect.fromRectAndRadius(
            Rect.fromLTWH(px + 2, py + 2, kCell - 4, kCell - 4),
            const Radius.circular(9));

        if (startCh != null || endCh != null) {
          final baseColor = startCh?.color ?? endCh!.color;
          final fill = connected
              ? baseColor.withValues(alpha: 0.55)
              : baseColor.withValues(alpha: startCh != null ? 0.35 : 0.22);
          canvas.drawRRect(rrect, Paint()..color = fill);
          if (connected) {
            // Acende a célula de chegada — anel brilhante marcando a
            // cadeia como completa, além do asterisco (ver _drawEndMarker).
            canvas.drawRRect(
                rrect,
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = kCell * 0.06
                  ..color = baseColor
                  ..maskFilter =
                      MaskFilter.blur(BlurStyle.normal, kCell * 0.08));
          }
        } else {
          final grad = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isRotatable
                ? const [Color(0xFFFFFDF8), Color(0xFFE7DFCE)]
                : const [Color(0xFFF0EBDF), Color(0xFFDBD2C0)],
          );
          canvas.drawRRect(
              rrect, Paint()..shader = grad.createShader(rrect.outerRect));
          canvas.drawRRect(
              rrect,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1
                ..color = const Color(0xFF3A5F7A).withValues(alpha: 0.12));
        }

        if (endCh != null) {
          _drawEndMarker(canvas, px, py, endCh.color, lit: connected);
        } else if (startCh != null) {
          _drawDirArrow(canvas, px, py, startCh.startDir, startCh.color);
        } else {
          _drawCellArcs(canvas, px, py, type, highlighted[key] ?? const []);
        }
      }
    }

    for (final p in particles) {
      canvas.drawCircle(
          Offset(p.x, p.y),
          p.size,
          Paint()
            ..color = p.color
                .withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0)));
    }

    canvas.restore();
  }

  void _drawCellArcs(
      Canvas canvas, double px, double py, String type, List<ActiveArc> active) {
    const s = kCell;
    final mid = s / 2;
    final defs = _arcDefs(s)[type]!;
    final drawOrder = type == 'D' ? [1, 0] : [0, 1];
    final anyActive = active.isNotEmpty;

    for (final i in drawOrder) {
      final a = defs[i];
      ActiveArc? activeArc;
      for (final x in active) {
        if (x.idx == i) {
          activeArc = x;
          break;
        }
      }

      final passes = <Paint>[];
      if (!anyActive) {
        passes.add(Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.14
          ..strokeCap = StrokeCap.round
          ..color = colorArc);
      } else if (activeArc != null) {
        // brilho (equivalente ao shadowBlur do canvas)
        passes.add(Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.16
          ..strokeCap = StrokeCap.round
          ..color = activeArc.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.15));
        passes.add(Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.16
          ..strokeCap = StrokeCap.round
          ..color = activeArc.color);
      } else {
        passes.add(Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.11
          ..strokeCap = StrokeCap.round
          ..color = colorArcDim);
      }

      final path = Path();
      if (a.straight) {
        path.moveTo(px + a.x1, py + a.y1);
        path.lineTo(px + a.x2, py + a.y2);
        if (a.split) {
          path.moveTo(px + a.x3, py + a.y3);
          path.lineTo(px + a.x4, py + a.y4);
        }
      } else {
        path.addArc(
            Rect.fromCircle(center: Offset(px + a.cx, py + a.cy), radius: mid),
            a.sa,
            a.ea - a.sa);
      }
      for (final paint in passes) {
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawDirArrow(
      Canvas canvas, double px, double py, int dirEdge, Color color) {
    final cx = px + kCell / 2, cy = py + kCell / 2;
    final angle = (dirEdge - 1) * math.pi / 2;
    const s = kCell * 0.3;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    final tri = Path()
      ..moveTo(s, 0)
      ..lineTo(-s * 0.5, -s * 0.75)
      ..lineTo(-s * 0.5, s * 0.75)
      ..close();
    canvas.drawPath(
        tri,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, kCell * 0.075));
    canvas.drawPath(tri, Paint()..color = color);
    canvas.restore();
  }

  /// Asterisco de 8 pontas (o '✳' do protótipo), desenhado à mão para
  /// não depender da fonte de emojis. Quando [lit] (cadeia completa), ganha
  /// um brilho por trás e fica maior/mais grosso — o indicativo de "conectado".
  void _drawEndMarker(Canvas canvas, double px, double py, Color color,
      {bool lit = false}) {
    final cx = px + kCell / 2, cy = py + kCell / 2;
    final radius = kCell * (lit ? 0.28 : 0.22);
    if (lit) {
      canvas.drawCircle(
          Offset(cx, cy),
          radius * 1.3,
          Paint()
            ..color = color.withValues(alpha: 0.55)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, kCell * 0.14));
    }
    final paint = Paint()
      ..color = lit ? Colors.white : color
      ..strokeWidth = kCell * (lit ? 0.1 : 0.08)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
          Offset(cx - math.cos(a) * radius, cy - math.sin(a) * radius),
          Offset(cx + math.cos(a) * radius, cy + math.sin(a) * radius),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}
