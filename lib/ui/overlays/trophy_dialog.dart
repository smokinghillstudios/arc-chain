import 'package:flutter/material.dart';

import '../../core/trophies.dart';
import '../theme.dart';
import '../widgets/trophy_icons.dart';

/// Popup de celebração ao desbloquear 1+ troféus — o símbolo dourado da
/// categoria de cada um ([trophyCategoryGlyph]), sem palavras (mesmo
/// estilo do diálogo de vitória). Se [ids] tiver mais de um troféu, mostra
/// em fila: toque avança pro próximo, último toque fecha.
Future<void> showTrophyUnlockedDialog(
  BuildContext context, {
  required List<String> ids,
}) {
  if (ids.isEmpty) return Future<void>.value();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xFF4A7FA5).withValues(alpha: 0.88),
    builder: (_) => _TrophyUnlockedDialog(ids: ids),
  );
}

class _TrophyUnlockedDialog extends StatefulWidget {
  final List<String> ids;
  const _TrophyUnlockedDialog({required this.ids});

  @override
  State<_TrophyUnlockedDialog> createState() => _TrophyUnlockedDialogState();
}

class _TrophyUnlockedDialogState extends State<_TrophyUnlockedDialog> {
  int _index = 0;

  void _advance() {
    if (_index >= widget.ids.length - 1) {
      Navigator.of(context).pop();
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final def = kTrophies.firstWhere((t) => t.id == widget.ids[_index]);
    return GestureDetector(
      onTap: _advance,
      child: Dialog(
        backgroundColor: const Color(0xFFFAFAF8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 40, 40, 36),
          child: _TrophyBurst(key: ValueKey(_index), category: def.category),
        ),
      ),
    );
  }
}

/// Símbolo dourado da categoria do troféu, com um "pop" de entrada (escala
/// com overshoot) — toca uma vez por troféu mostrado.
class _TrophyBurst extends StatefulWidget {
  final TrophyCategory category;
  const _TrophyBurst({super.key, required this.category});

  @override
  State<_TrophyBurst> createState() => _TrophyBurstState();
}

class _TrophyBurstState extends State<_TrophyBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.elasticOut.transform(_c.value);
        return Transform.scale(
          scale: t,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentGold.withValues(alpha: 0.55 * t.clamp(0.0, 1.0)),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: trophyCategoryGlyph(
              widget.category,
              size: 96,
              color: accentGold,
            ),
          ),
        );
      },
    );
  }
}
