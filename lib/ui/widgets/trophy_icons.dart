import 'package:flutter/material.dart';

import '../../core/trophies.dart';

/// Ícone por categoria de troféu — todo troféu desbloqueado é dourado (sem
/// medalhas bronze/prata/ouro), mas o desenho muda por categoria pro
/// jogador reconhecer do que se trata sem nenhuma palavra na tela.
///
/// `null` para [TrophyCategory.perfectLevels]: essa categoria não tem um
/// ícone único — é desenhada como 3 estrelas do mesmo tamanho por
/// [trophyCategoryGlyph], porque um ícone genérico de "brilho"/"perfeição"
/// não deixava claro que o troféu é sobre estrelas.
IconData? trophyCategoryIcon(TrophyCategory category) {
  switch (category) {
    case TrophyCategory.stars:
      return Icons.star_rounded;
    case TrophyCategory.perfectLevels:
      return null;
    case TrophyCategory.campaign:
      return Icons.flag_rounded;
    case TrophyCategory.checkpoints:
      return Icons.videocam_rounded;
    case TrophyCategory.rainbow:
      return Icons.palette_rounded;
    case TrophyCategory.infinite:
      return Icons.all_inclusive_rounded;
    case TrophyCategory.flawless:
      return Icons.diamond_rounded;
    case TrophyCategory.comeback:
      return Icons.trending_up_rounded;
    case TrophyCategory.streakDays:
      return Icons.local_fire_department_rounded;
    case TrophyCategory.totalDays:
      return Icons.calendar_month_rounded;
  }
}

/// Widget do símbolo da categoria, no tamanho/cor pedidos — use este em vez
/// de [trophyCategoryIcon] direto, já que [TrophyCategory.perfectLevels]
/// não é um `IconData` único.
Widget trophyCategoryGlyph(
  TrophyCategory category, {
  required double size,
  required Color color,
}) {
  final icon = trophyCategoryIcon(category);
  if (icon != null) return Icon(icon, size: size, color: color);

  final starSize = size * 0.46;
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Icon(Icons.star_rounded, size: starSize, color: color),
      Icon(Icons.star_rounded, size: starSize, color: color),
      Icon(Icons.star_rounded, size: starSize, color: color),
    ],
  );
}
