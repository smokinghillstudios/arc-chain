import 'package:flutter/material.dart';

import '../theme.dart';

/// Botão circular flutuante — 48px, fundo quase branco com sombra (ou
/// [headerDark] quando [active], mesmo tom do `AudioToggleButton` ligado),
/// com um pontinho vermelho opcional pra "novidade". Porte do
/// `_MapBalloonButton` do ARCO — usado no mapa de fases e na sala de
/// troféus.
class MapBalloonButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;
  final bool showDot;

  const MapBalloonButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: active ? headerDark : Colors.white.withValues(alpha: 0.94),
            shape: const CircleBorder(),
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.28),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  icon,
                  size: 22,
                  color: active ? Colors.white : ink.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          if (showDot)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFE24B4A),
                  shape: BoxShape.circle,
                  border: Border.all(color: paper, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
