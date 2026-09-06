import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Anel de arcos coloridos — o motivo de arcos do jogo destilado num único
/// símbolo (usado na splash e no nó da fase atual do mapa). Porte de
/// `ui/widgets/arc_ring.dart` do ARCO, parametrizado pelas cores das cadeias
/// em vez de uma paleta fixa.
///
/// Os números (raio, espessura do traço, gap) são os mesmos da splash
/// original, escalados proporcionalmente a [diameter] (a splash desenha
/// numa caixa de 240×240 com raio `120-12` e traço `13`).
void paintArcRing(Canvas canvas, Offset center, double diameter,
    {required List<Color> colors, double alpha = 0.90}) {
  const refBox = 240.0;
  final scale = diameter / refBox;
  final radius = diameter / 2 - 12 * scale;
  final segments = colors.length;
  const gap = 0.30; // radianos entre segmentos
  final sweep = 2 * math.pi / segments - gap;
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 13 * scale;
  for (var i = 0; i < segments; i++) {
    paint.color = colors[i].withValues(alpha: alpha);
    final start = -math.pi / 2 + i * (2 * math.pi / segments) + gap / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      paint,
    );
  }
}

/// Anel de arcos segmentados, mais compacto que [paintArcRing] (gap maior,
/// traço fixo) — usado no nó da fase atual do mapa de fases.
void paintSegmentedRing(
  Canvas canvas,
  Offset center,
  double radius, {
  required List<Color> colors,
  double strokeWidth = 4,
  double gap = 0.42,
  double alpha = 0.9,
}) {
  final segments = colors.length;
  final sweep = 2 * math.pi / segments - gap;
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = strokeWidth;
  for (var s = 0; s < segments; s++) {
    paint.color = colors[s].withValues(alpha: alpha);
    final start = -math.pi / 2 + s * (2 * math.pi / segments) + gap / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      paint,
    );
  }
}
