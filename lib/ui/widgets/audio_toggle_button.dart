import 'package:flutter/material.dart';

import '../theme.dart';

/// Botão quadrado liga/desliga de áudio — mesmo formato/tamanho dos botões
/// de ação dos diálogos (44×44, cantos arredondados): preenche de azul-escuro
/// (`headerDark`) quando ligado, cinza claro (`btnBg`) quando desligado.
class AudioToggleButton extends StatelessWidget {
  final bool enabled;
  final IconData iconOn;
  final IconData iconOff;
  final String tooltip;
  final VoidCallback onTap;
  final double size;

  const AudioToggleButton({
    super.key,
    required this.enabled,
    required this.iconOn,
    required this.iconOff,
    required this.tooltip,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? headerDark : btnBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Icon(
                enabled ? iconOn : iconOff,
                size: size * 0.5,
                color: enabled ? Colors.white : ink.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
