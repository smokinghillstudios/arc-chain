import 'package:flutter/material.dart';

import '../../core/engine.dart';

/// HUD superior estilo ARCO: toques | fase | engrenagem, em cards creme
/// arredondados. Proporções do original: 68 | flex | 62 numa largura de 352.
class HudTop extends StatelessWidget {
  final double width;
  final int remaining;
  final LevelDef level;
  final VoidCallback onSettings;

  const HudTop({
    super.key,
    required this.width,
    required this.remaining,
    required this.level,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final scale = width / 352;
    final low = remaining <= 2;
    return SizedBox(
      width: width,
      child: Row(
        children: [
          SizedBox(
            width: 68 * scale,
            child: _HudCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.touch_app_rounded,
                      size: 14, color: Color(0xFF90A0AA)),
                  const SizedBox(height: 3),
                  Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      color: low
                          ? const Color(0xFFFF8C42)
                          : const Color(0xFF536F84),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _HudCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${level.id}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      color: Color(0xFF536F84),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < level.chains; i++)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: chainColors[i],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        '${level.cols}×${level.rows}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF90A0AA),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 62 * scale,
            child: _HudCard(
              child: IconButton(
                onPressed: onSettings,
                icon: const Icon(Icons.settings_outlined,
                    color: Color(0xFF7C8C95), size: 28),
                tooltip: 'Configurações',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudCard extends StatelessWidget {
  final Widget child;
  const _HudCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }
}
