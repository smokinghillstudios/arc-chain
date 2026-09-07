import 'package:flutter/material.dart';

import '../../controller/progress.dart';
import '../../core/engine.dart';
import '../../core/trophies.dart';
import '../theme.dart';
import '../widgets/map_balloon_button.dart';
import '../widgets/trophy_icons.dart';

/// Sala de troféus: grade única e contínua com todos os [kTrophies], na
/// mesma ordem de [TrophyCategory] mas sem separação visual entre
/// categorias. Cada troféu bloqueado é uma silhueta cinza; desbloqueado,
/// dourado — o ícone muda por categoria (`trophyCategoryGlyph`) pro
/// jogador reconhecer do que se trata sem nenhuma palavra na tela, com a
/// fração numérica de progresso abaixo. Porte do `TrophyRoomScreen` do
/// ARCO.
class TrophyRoomScreen extends StatefulWidget {
  const TrophyRoomScreen({super.key});

  @override
  State<TrophyRoomScreen> createState() => _TrophyRoomScreenState();
}

class _TrophyRoomScreenState extends State<TrophyRoomScreen> {
  bool _loaded = false;
  TrophyProgress _progress = (
    totalStars: 0,
    perfectLevels: 0,
    completedStreak: 0,
    checkpointsCleared: 0,
    rainbowClears: 0,
    infiniteProgress: 0,
    flawlessFirstClears: 0,
    comebackWins: 0,
    consecutiveDays: 0,
    totalDaysPlayed: 0,
  );
  Set<String> _unlocked = const {};

  /// Troféus desbloqueados mas ainda não vistos aqui antes desta abertura —
  /// destacados na grade. Calculado ANTES de marcar tudo como visto, senão
  /// nunca haveria nada pra destacar.
  Set<String> _newlySeen = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = Progress.instance;
    final unlocked = Set.of(p.unlockedTrophies);
    final newlySeen = unlocked.difference(p.seenTrophyIds);
    // Marca todos os desbloqueados como vistos — apaga o pontinho de "novo"
    // no balão de entrada do mapa e o destaque não reaparece na próxima
    // visita.
    p.seenTrophyIds
      ..clear()
      ..addAll(unlocked);
    await p.saveSeenTrophyIds();
    if (!mounted) return;
    final rainbowClears =
        p.best.keys.where((id) => levelForId(id).chains == 5).length;
    setState(() {
      _progress = buildTrophyProgress(
        stars: p.best,
        completedStreak: p.completedStreak,
        checkpointsCleared: p.checkpoints.length,
        rainbowClears: rainbowClears,
        infiniteProgress: (p.completedStreak - 100).clamp(0, 1 << 30),
        flawlessFirstClears: p.flawlessFirstClears,
        comebackWins: p.comebackWins,
        consecutiveDays: p.consecutiveDays,
        totalDaysPlayed: p.totalDaysPlayed,
      );
      _unlocked = unlocked;
      _newlySeen = newlySeen;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Stack(
          children: [
            !_loaded
                ? const Center(child: CircularProgressIndicator(color: inkMuted))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 78, 20, 24),
                    child: _TrophyGroups(
                      progress: _progress,
                      unlocked: _unlocked,
                      newlySeen: _newlySeen,
                    ),
                  ),
            Positioned(
              left: 16,
              top: 14,
              child: MapBalloonButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Voltar',
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grade única com todos os troféus, na ordem de [kTrophies] — sem
/// separação visual entre categorias.
class _TrophyGroups extends StatelessWidget {
  final TrophyProgress progress;
  final Set<String> unlocked;
  final Set<String> newlySeen;
  const _TrophyGroups({
    required this.progress,
    required this.unlocked,
    required this.newlySeen,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 13,
      runSpacing: 16,
      children: [
        for (final t in kTrophies)
          _TrophyTile(
            trophy: t,
            value: valueForCategory(t.category, progress),
            unlocked: unlocked.contains(t.id),
            isNew: newlySeen.contains(t.id),
          ),
      ],
    );
  }
}

class _TrophyTile extends StatelessWidget {
  final TrophyDef trophy;
  final int value;
  final bool unlocked;

  /// Verdadeiro só na 1ª vez que este troféu é mostrado aqui depois de
  /// desbloqueado — ganha o mesmo pontinho de "novidade" do balão de
  /// entrada, além de um anel de destaque em volta do círculo.
  final bool isNew;
  const _TrophyTile({
    required this.trophy,
    required this.value,
    required this.unlocked,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final shown = value.clamp(0, trophy.threshold);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: unlocked ? accentGold.withValues(alpha: 0.16) : btnBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isNew
                      ? const Color(0xFFE24B4A)
                      : unlocked
                          ? accentGold
                          : const Color(0xFFDDDDDD),
                  width: isNew ? 3 : 2,
                ),
              ),
              alignment: Alignment.center,
              child: trophyCategoryGlyph(
                trophy.category,
                size: 32,
                color: unlocked ? accentGold : const Color(0xFFC9C0B0),
              ),
            ),
            if (isNew)
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
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            text: '$shown',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: unlocked ? ink : inkMuted,
            ),
            children: [
              TextSpan(
                text: '/${trophy.threshold}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
