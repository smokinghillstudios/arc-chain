import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Anel de arcos segmentados nas cores das cadeias — usado no nó da fase
/// atual do mapa de fases.
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
