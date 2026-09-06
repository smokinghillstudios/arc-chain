import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Selo hexagonal das paradas de vídeo do mapa: vermelho com ▶ branco
/// enquanto pendente, verde com ✓ branco depois de assistido. Porte de
/// `ui/widgets/hex_badge.dart` do ARCO, como função de pintura em vez de
/// widget — o mapa desenha tudo num único `CustomPainter`.
void paintHexBadge(
  Canvas canvas,
  Offset center,
  double radius, {
  required bool cleared,
  required Color clearedColor,
  required Color pendingColor,
}) {
  final hex = _hexPath(center, radius);
  canvas.drawPath(hex, Paint()..color = cleared ? clearedColor : pendingColor);
  canvas.drawPath(
    hex,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white,
  );

  // Ícones dimensionados em proporção ao raio do hexágono — os valores
  // absolutos abaixo foram calibrados para radius=24; escalamos por
  // radius/24 para manter a mesma proporção em qualquer tamanho.
  final scale = radius / 24;

  if (cleared) {
    final check = Path()
      ..moveTo(center.dx - 7 * scale, center.dy + 0.5 * scale)
      ..lineTo(center.dx - 2 * scale, center.dy + 5.5 * scale)
      ..lineTo(center.dx + 7.5 * scale, center.dy - 5.5 * scale);
    canvas.drawPath(
      check,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  } else {
    final play = Path()
      ..moveTo(center.dx - 4.5 * scale, center.dy - 7.5 * scale)
      ..lineTo(center.dx - 4.5 * scale, center.dy + 7.5 * scale)
      ..lineTo(center.dx + 9 * scale, center.dy)
      ..close();
    canvas.drawPath(play, Paint()..color = Colors.white);
  }
}

Path _hexPath(Offset center, double r) {
  final path = Path();
  for (var i = 0; i < 6; i++) {
    final angle = -math.pi / 2 + i * math.pi / 3;
    final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
    i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
  }
  return path..close();
}
