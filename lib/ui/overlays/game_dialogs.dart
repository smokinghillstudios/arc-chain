import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ads/ads_service.dart';
import '../../core/engine.dart' show chainColors;
import '../theme.dart';
import '../widgets/audio_toggle_button.dart';
import '../widgets/hex_badge.dart';

/// Segundos do anúncio simulado (fallback quando o vídeo não carrega).
const kSimulatedAdSeconds = 5;

/// Toques extras oferecidos a quem assiste o vídeo após perder — mostrado
/// no diálogo de derrota e efetivamente concedido pelo chamador
/// (`GameScreen._offerExtraTaps`).
const kDefeatExtraTaps = 5;

/// Tamanho dos botões quadrados de ação nos diálogos de vitória/derrota e no
/// menu de configurações — porte de `kDialogButtonSize` do ARCO.
const double kDialogButtonSize = 52.8;

/// Ação escolhida no diálogo de vitória.
enum VictoryAction {
  /// Recomeçar a mesma fase do zero (sem navegar — fica na mesma tela).
  retry,

  /// Voltar à seleção de fases.
  menu,
}

/// Diálogo de vitória — cabeçalho verde com um visto, estrelas conquistadas
/// acendendo em sequência com confete contínuo por trás (porte de
/// `_VictoryDialog` do ARCO) e as ações repetir/voltar ao mapa.
Future<VictoryAction?> showVictoryDialog(
  BuildContext context, {
  required int stars,
}) {
  return showDialog<VictoryAction>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xFF4A7FA5).withValues(alpha: 0.88),
    builder: (_) => _VictoryDialog(stars: stars),
  );
}

class _VictoryDialog extends StatelessWidget {
  final int stars;
  const _VictoryDialog({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFAFAF8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              color: playGreen,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 26),
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_rounded,
                size: 46,
                color: Colors.white,
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                const Positioned.fill(child: _ConfettiRain()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(36, 30, 36, 26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 96, child: _VictoryStars(stars: stars)),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SettingsIconButton(
                            size: kDialogButtonSize,
                            icon: Icons.refresh,
                            tooltip: 'Jogar novamente',
                            onTap: () => Navigator.of(context)
                                .pop(VictoryAction.retry),
                          ),
                          const SizedBox(width: 18),
                          _SettingsIconButton(
                            size: kDialogButtonSize,
                            icon: Icons.grid_view,
                            tooltip: 'Voltar para seleção de fases',
                            onTap: () => Navigator.of(context)
                                .pop(VictoryAction.menu),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fileira de 3 estrelas (a do meio maior) que acendem uma a uma — toca uma
/// única vez ao abrir o diálogo e fica parada acesa.
class _VictoryStars extends StatefulWidget {
  final int stars;
  const _VictoryStars({required this.stars});

  @override
  State<_VictoryStars> createState() => _VictoryStarsState();
}

class _VictoryStarsState extends State<_VictoryStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _AnimatedStar(
              size: i == 1 ? 52 : 38,
              lit: i < widget.stars,
              controller: _c,
              start: i * 0.22,
            ),
          ),
      ],
    );
  }
}

class _AnimatedStar extends StatelessWidget {
  final double size;
  final bool lit;
  final Animation<double> controller;
  final double start;

  const _AnimatedStar({
    required this.size,
    required this.lit,
    required this.controller,
    required this.start,
  });

  @override
  Widget build(BuildContext context) {
    const off = Color(0xFFDDD8CE);
    if (!lit) {
      return Icon(Icons.star_rounded, size: size, color: off);
    }
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(
        start.clamp(0.0, 1.0),
        (start + 0.4).clamp(0.0, 1.0),
        curve: Curves.elasticOut,
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final t = anim.value;
        final glow = t.clamp(0.0, 1.0);
        return Transform.scale(
          scale: t.clamp(0.0, 4.0),
          child: Opacity(
            opacity: glow,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentGold.withValues(alpha: 0.55 * glow),
                    blurRadius: size * 0.5,
                    spreadRadius: size * 0.05,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Icon(Icons.star_rounded, size: size, color: accentGold),
    );
  }
}

class _ConfettiPiece {
  final double dx;

  /// Deslocamento de fase (0–1) do próprio ciclo do controller — cada
  /// pedaço cai, desaparece e reaparece no topo num ponto diferente do
  /// loop, por isso a chuva nunca some por completo.
  final double phase;
  final int colorIndex;
  final bool circle;
  final double size;
  final double turns;

  _ConfettiPiece({
    required this.dx,
    required this.phase,
    required this.colorIndex,
    required this.circle,
    required this.size,
    required this.turns,
  });
}

/// Chuva de confete que nunca termina, espalhada pelo retângulo inteiro do
/// diálogo — 26 pedaços nas cores das cadeias, cada um com sua própria fase
/// dentro do loop contínuo do controller.
class _ConfettiRain extends StatefulWidget {
  const _ConfettiRain();

  @override
  State<_ConfettiRain> createState() => _ConfettiRainState();
}

class _ConfettiRainState extends State<_ConfettiRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_ConfettiPiece> _pieces;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    final rng = math.Random(11); // semente fixa: mesma coreografia sempre
    _pieces = List.generate(26, (i) {
      return _ConfettiPiece(
        dx: rng.nextDouble(),
        phase: rng.nextDouble(),
        colorIndex: i % chainColors.length,
        circle: rng.nextBool(),
        size: 5 + rng.nextDouble() * 4,
        turns: 0.6 + rng.nextDouble() * 0.6,
      );
    });
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
      builder: (context, _) =>
          CustomPaint(painter: _ConfettiPainter(_pieces, _c.value)),
    );
  }
}

/// Cada pedaço usa `(t + fase) % 1` como progresso — ao voltar a 0 ele
/// reaparece no topo, então o loop do controller vira uma chuva contínua.
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double t;
  _ConfettiPainter(this.pieces, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final local = (t + p.phase) % 1.0;
      final opacity = local < 0.12
          ? local / 0.12
          : local > 0.85
              ? 1 - (local - 0.85) / 0.15
              : 1.0;
      if (opacity <= 0) continue;

      final x = p.dx * size.width;
      final y = -12 + local * (size.height + 24);
      final angle = p.turns * 2 * math.pi * local;
      final paint = Paint()
        ..color = chainColors[p.colorIndex]
            .withValues(alpha: opacity.clamp(0.0, 1.0));

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      if (p.circle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size * 0.7, height: p.size),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

/// Ação escolhida no diálogo de derrota.
enum DefeatAction {
  /// Assistiu ao vídeo: +[kDefeatExtraTaps] toques, mesma fase continua.
  continueWithVideo,

  /// Recomeçar a fase do zero.
  retry,

  /// Voltar à seleção de fases.
  menu,
}

/// Diálogo de derrota — cabeçalho vermelho com um "×", oferta de vídeo por
/// +[kDefeatExtraTaps] toques (mesma caixa + selo hexagonal do ARCO) e as
/// ações tentar de novo / voltar ao mapa.
Future<DefeatAction?> showDefeatDialog(BuildContext context) {
  return showDialog<DefeatAction>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xFF4A7FA5).withValues(alpha: 0.88),
    builder: (_) => const _DefeatDialog(),
  );
}

class _DefeatDialog extends StatefulWidget {
  const _DefeatDialog();

  @override
  State<_DefeatDialog> createState() => _DefeatDialogState();
}

class _DefeatDialogState extends State<_DefeatDialog> {
  static const double _actionBtnSize = kDialogButtonSize;
  static const double _actionBtnGap = 18;
  static const double _videoBoxWidth = _actionBtnSize * 2 + _actionBtnGap;

  bool watching = false;
  int remaining = kSimulatedAdSeconds;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _watchAd() async {
    // Tenta o rewarded real (release); null = indisponível → simulação.
    final earned = await AdsService.instance.showRewarded();
    if (!mounted) return;
    if (earned != null) {
      if (earned) Navigator.of(context).pop(DefeatAction.continueWithVideo);
      return;
    }
    setState(() => watching = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => remaining--);
      if (remaining <= 0) {
        t.cancel();
        Navigator.of(context).pop(DefeatAction.continueWithVideo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFAFAF8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              color: defeatRed,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 26),
              alignment: Alignment.center,
              child: const Text(
                '×',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
              child: Center(
                child: watching
                    ? Container(
                        width: _videoBoxWidth,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2A38),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '$remaining',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB5EAD7),
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: _watchAd,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: _videoBoxWidth,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: paperLine,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.touch_app_rounded,
                                      size: 22, color: Color(0xFF2C2C2C)),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '$kDefeatExtraTaps',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2C2C2C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Positioned(
                              left: -14,
                              top: 12,
                              child: _PlusBadge(),
                            ),
                            const Positioned(
                              bottom: -9,
                              right: -9,
                              child: _CornerHex(),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SettingsIconButton(
                    size: _actionBtnSize,
                    icon: Icons.refresh,
                    tooltip: 'Tentar de novo',
                    onTap: () => Navigator.of(context).pop(DefeatAction.retry),
                  ),
                  const SizedBox(width: _actionBtnGap),
                  _SettingsIconButton(
                    size: _actionBtnSize,
                    icon: Icons.grid_view,
                    tooltip: 'Voltar para seleção de fases',
                    onTap: () => Navigator.of(context).pop(DefeatAction.menu),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selo circular com "+" sobreposto à borda esquerda da caixa de
/// recompensa do vídeo.
class _PlusBadge extends StatelessWidget {
  const _PlusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: paperLine, width: 2),
      ),
      alignment: Alignment.center,
      child: const Text(
        '+',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Color(0xFF2C2C2C),
          height: 1,
        ),
      ),
    );
  }
}

/// Selo hexagonal flutuando no canto da caixa de recompensa — mesmo desenho
/// das paradas de vídeo do mapa (`paintHexBadge`).
class _CornerHex extends StatelessWidget {
  const _CornerHex();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: CustomPaint(painter: _CornerHexPainter()),
    );
  }
}

class _CornerHexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    paintHexBadge(
      canvas,
      size.center(Offset.zero),
      size.width / 2 - 2,
      cleared: false,
      clearedColor: chainColors[2],
      pendingColor: chainColors[3],
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Menu de configurações — grade 2×2 (som, música, reiniciar, voltar) com
/// um botão de fechar centralizado embaixo, sem palavras.
enum SettingsAction { resetLevel, backToMap }

Future<SettingsAction?> showSettingsDialog(
  BuildContext context, {
  required bool soundEnabled,
  required bool musicEnabled,
  required ValueChanged<bool> onToggleSound,
  required ValueChanged<bool> onToggleMusic,
}) {
  return showDialog<SettingsAction>(
    context: context,
    builder: (context) {
      var sound = soundEnabled;
      var music = musicEnabled;
      return StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFFF7F3EC),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AudioToggleButton(
                            size: kDialogButtonSize,
                            enabled: sound,
                            iconOn: Icons.volume_up,
                            iconOff: Icons.volume_off,
                            tooltip: sound ? 'Desligar som' : 'Ligar som',
                            onTap: () {
                              setState(() => sound = !sound);
                              onToggleSound(sound);
                            },
                          ),
                          const SizedBox(width: 14),
                          AudioToggleButton(
                            size: kDialogButtonSize,
                            enabled: music,
                            iconOn: Icons.music_note,
                            iconOff: Icons.music_off,
                            tooltip: music ? 'Desligar música' : 'Ligar música',
                            onTap: () {
                              setState(() => music = !music);
                              onToggleMusic(music);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _IconGroupDivider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SettingsIconButton(
                            size: kDialogButtonSize,
                            icon: Icons.refresh,
                            tooltip: 'Reiniciar a fase',
                            onTap: () => Navigator.of(context)
                                .pop(SettingsAction.resetLevel),
                          ),
                          const SizedBox(width: 14),
                          _SettingsIconButton(
                            size: kDialogButtonSize,
                            icon: Icons.grid_view,
                            tooltip: 'Voltar para seleção de fases',
                            onTap: () => Navigator.of(context)
                                .pop(SettingsAction.backToMap),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _SettingsIconButton(
                  size: kDialogButtonSize,
                  icon: Icons.close,
                  tooltip: 'Fechar',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Botão quadrado de ação — som/música usam [AudioToggleButton] (têm estado
/// ligado/desligado); este é para ações pontuais (reiniciar, voltar, jogar
/// de novo etc.), sempre no tom neutro `btnBg`.
class _SettingsIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;

  const _SettingsIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: btnBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Icon(
                icon,
                size: size * 0.5,
                color: ink.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Divisor horizontal fino que separa a linha som/música da linha
/// resetar/voltar no grid 2×2 do menu de configurações.
class _IconGroupDivider extends StatelessWidget {
  const _IconGroupDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kDialogButtonSize * 2 + 14,
      child: Divider(
        height: 1,
        thickness: 1,
        color: ink.withValues(alpha: 0.12),
      ),
    );
  }
}
