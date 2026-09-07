import '../core/engine.dart';
import '../core/trophies.dart';
import 'progress.dart';

/// Monta o instantâneo de progresso a partir de [Progress.instance], checa
/// quais troféus (`core/trophies.dart`) foram cruzados desde a última
/// checagem e persiste os novos. Chamado nos pontos onde progresso
/// relevante muda: fim de fase vencida (`GameScreen`), parada de vídeo
/// liberada (`level_map_screen.dart`) e visita diária
/// (`daily_visit_screen.dart`).
Future<List<String>> checkAndPersistTrophies() async {
  final p = Progress.instance;
  final rainbowClears =
      p.best.keys.where((id) => levelForId(id).chains == 5).length;
  final infiniteProgress = (p.completedStreak - 100).clamp(0, 1 << 30);

  final progress = buildTrophyProgress(
    stars: p.best,
    completedStreak: p.completedStreak,
    checkpointsCleared: p.checkpoints.length,
    rainbowClears: rainbowClears,
    infiniteProgress: infiniteProgress,
    flawlessFirstClears: p.flawlessFirstClears,
    comebackWins: p.comebackWins,
    consecutiveDays: p.consecutiveDays,
    totalDaysPlayed: p.totalDaysPlayed,
  );
  final newIds = checkNewTrophies(progress, p.unlockedTrophies);
  if (newIds.isNotEmpty) {
    p.unlockedTrophies.addAll(newIds);
    await p.saveUnlockedTrophies();
  }
  return newIds;
}
