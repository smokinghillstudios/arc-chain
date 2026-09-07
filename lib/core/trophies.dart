/// Sistema de troféus: cada troféu é um marco independente (não uma medalha
/// que evolui) sobre um contador de progresso já existente ou novo — ver
/// `controller/progress.dart` para onde cada contador é persistido.
///
/// Módulo puro (sem Flutter): a UI decide o ícone/cor, aqui só a regra
/// "qual valor cruzou qual marco". Porte de `core/trophies.dart` do ARCO,
/// com as categorias adaptadas ao Arc Chain (sem fases finitas, sem
/// power-ups; ganha duas categorias nativas do jogo — `rainbow` e
/// `infinite`).
enum TrophyCategory {
  /// Soma de todas as estrelas conquistadas (`Progress.best`).
  stars,

  /// Quantas fases têm as 3 estrelas (perfeitas).
  perfectLevels,

  /// Maior fase concluída em sequência (`Progress.completedStreak`).
  campaign,

  /// Paradas de vídeo liberadas no mapa (`Progress.checkpoints`).
  checkpoints,

  /// Fases de 5 cadeias simultâneas já vencidas — a assinatura do Arc
  /// Chain (nenhum outro jogo da série tem isso).
  rainbow,

  /// Fases além da 100 (modo infinito) já alcançadas.
  infinite,

  /// Fases vencidas "de primeira" — nunca perdidas antes da 1ª vitória
  /// daquela fase (`Progress.flawlessFirstClears`).
  flawless,

  /// Fases vencidas depois de aceitar o vídeo de toques extra na derrota,
  /// na mesma tentativa (`Progress.comebackWins`).
  comeback,

  /// Dias seguidos jogados sem pular nenhum (`Progress.consecutiveDays`).
  streakDays,

  /// Dias totais jogados, não precisam ser seguidos
  /// (`Progress.totalDaysPlayed`).
  totalDays,
}

class TrophyDef {
  final String id;
  final TrophyCategory category;
  final int threshold;
  const TrophyDef({
    required this.id,
    required this.category,
    required this.threshold,
  });
}

/// Todos os troféus do jogo, em ordem crescente de marco dentro de cada
/// categoria.
const List<TrophyDef> kTrophies = [
  // Estrelas acumuladas.
  TrophyDef(id: 'stars_10', category: TrophyCategory.stars, threshold: 10),
  TrophyDef(id: 'stars_30', category: TrophyCategory.stars, threshold: 30),
  TrophyDef(id: 'stars_75', category: TrophyCategory.stars, threshold: 75),
  TrophyDef(id: 'stars_150', category: TrophyCategory.stars, threshold: 150),
  TrophyDef(id: 'stars_300', category: TrophyCategory.stars, threshold: 300),
  TrophyDef(id: 'stars_500', category: TrophyCategory.stars, threshold: 500),

  // Fases com 3 estrelas.
  TrophyDef(
      id: 'perfect_5', category: TrophyCategory.perfectLevels, threshold: 5),
  TrophyDef(
      id: 'perfect_20',
      category: TrophyCategory.perfectLevels,
      threshold: 20),
  TrophyDef(
      id: 'perfect_50',
      category: TrophyCategory.perfectLevels,
      threshold: 50),
  TrophyDef(
      id: 'perfect_100',
      category: TrophyCategory.perfectLevels,
      threshold: 100),

  // Progresso na campanha.
  TrophyDef(
      id: 'campaign_10', category: TrophyCategory.campaign, threshold: 10),
  TrophyDef(
      id: 'campaign_25', category: TrophyCategory.campaign, threshold: 25),
  TrophyDef(
      id: 'campaign_50', category: TrophyCategory.campaign, threshold: 50),
  TrophyDef(
      id: 'campaign_100', category: TrophyCategory.campaign, threshold: 100),
  TrophyDef(
      id: 'campaign_150', category: TrophyCategory.campaign, threshold: 150),
  TrophyDef(
      id: 'campaign_250', category: TrophyCategory.campaign, threshold: 250),

  // Paradas de vídeo liberadas.
  TrophyDef(
      id: 'checkpoints_5',
      category: TrophyCategory.checkpoints,
      threshold: 5),
  TrophyDef(
      id: 'checkpoints_10',
      category: TrophyCategory.checkpoints,
      threshold: 10),
  TrophyDef(
      id: 'checkpoints_20',
      category: TrophyCategory.checkpoints,
      threshold: 20),
  TrophyDef(
      id: 'checkpoints_40',
      category: TrophyCategory.checkpoints,
      threshold: 40),

  // Fases de 5 cadeias vencidas.
  TrophyDef(id: 'rainbow_1', category: TrophyCategory.rainbow, threshold: 1),
  TrophyDef(
      id: 'rainbow_10', category: TrophyCategory.rainbow, threshold: 10),
  TrophyDef(
      id: 'rainbow_30', category: TrophyCategory.rainbow, threshold: 30),
  TrophyDef(
      id: 'rainbow_75', category: TrophyCategory.rainbow, threshold: 75),

  // Modo infinito.
  TrophyDef(id: 'infinite_1', category: TrophyCategory.infinite, threshold: 1),
  TrophyDef(
      id: 'infinite_40', category: TrophyCategory.infinite, threshold: 40),
  TrophyDef(
      id: 'infinite_200', category: TrophyCategory.infinite, threshold: 200),
  TrophyDef(
      id: 'infinite_500', category: TrophyCategory.infinite, threshold: 500),

  // Fases vencidas de primeira, sem nunca ter perdido antes.
  TrophyDef(
      id: 'flawless_5', category: TrophyCategory.flawless, threshold: 5),
  TrophyDef(
      id: 'flawless_20', category: TrophyCategory.flawless, threshold: 20),
  TrophyDef(
      id: 'flawless_50', category: TrophyCategory.flawless, threshold: 50),
  TrophyDef(
      id: 'flawless_100', category: TrophyCategory.flawless, threshold: 100),

  // Viradas depois do vídeo de toques extra.
  TrophyDef(id: 'comeback_1', category: TrophyCategory.comeback, threshold: 1),
  TrophyDef(
      id: 'comeback_10', category: TrophyCategory.comeback, threshold: 10),
  TrophyDef(
      id: 'comeback_30', category: TrophyCategory.comeback, threshold: 30),

  // Dias seguidos.
  TrophyDef(id: 'streak_3', category: TrophyCategory.streakDays, threshold: 3),
  TrophyDef(id: 'streak_7', category: TrophyCategory.streakDays, threshold: 7),
  TrophyDef(
      id: 'streak_14', category: TrophyCategory.streakDays, threshold: 14),
  TrophyDef(
      id: 'streak_30', category: TrophyCategory.streakDays, threshold: 30),
  TrophyDef(
      id: 'streak_60', category: TrophyCategory.streakDays, threshold: 60),

  // Dias totais jogados.
  TrophyDef(
      id: 'totaldays_7', category: TrophyCategory.totalDays, threshold: 7),
  TrophyDef(
      id: 'totaldays_30', category: TrophyCategory.totalDays, threshold: 30),
  TrophyDef(
      id: 'totaldays_100',
      category: TrophyCategory.totalDays,
      threshold: 100),
  TrophyDef(
      id: 'totaldays_365',
      category: TrophyCategory.totalDays,
      threshold: 365),
];

/// Instantâneo dos contadores de progresso relevantes pros troféus.
typedef TrophyProgress = ({
  int totalStars,
  int perfectLevels,
  int completedStreak,
  int checkpointsCleared,
  int rainbowClears,
  int infiniteProgress,
  int flawlessFirstClears,
  int comebackWins,
  int consecutiveDays,
  int totalDaysPlayed,
});

TrophyProgress buildTrophyProgress({
  required Map<int, int> stars,
  required int completedStreak,
  required int checkpointsCleared,
  required int rainbowClears,
  required int infiniteProgress,
  required int flawlessFirstClears,
  required int comebackWins,
  required int consecutiveDays,
  required int totalDaysPlayed,
}) =>
    (
      totalStars: stars.values.fold(0, (a, b) => a + b),
      perfectLevels: stars.values.where((s) => s == 3).length,
      completedStreak: completedStreak,
      checkpointsCleared: checkpointsCleared,
      rainbowClears: rainbowClears,
      infiniteProgress: infiniteProgress,
      flawlessFirstClears: flawlessFirstClears,
      comebackWins: comebackWins,
      consecutiveDays: consecutiveDays,
      totalDaysPlayed: totalDaysPlayed,
    );

/// Valor atual de [progress] na categoria de [category].
int valueForCategory(TrophyCategory category, TrophyProgress progress) {
  switch (category) {
    case TrophyCategory.stars:
      return progress.totalStars;
    case TrophyCategory.perfectLevels:
      return progress.perfectLevels;
    case TrophyCategory.campaign:
      return progress.completedStreak;
    case TrophyCategory.checkpoints:
      return progress.checkpointsCleared;
    case TrophyCategory.rainbow:
      return progress.rainbowClears;
    case TrophyCategory.infinite:
      return progress.infiniteProgress;
    case TrophyCategory.flawless:
      return progress.flawlessFirstClears;
    case TrophyCategory.comeback:
      return progress.comebackWins;
    case TrophyCategory.streakDays:
      return progress.consecutiveDays;
    case TrophyCategory.totalDays:
      return progress.totalDaysPlayed;
  }
}

bool isTrophyUnlocked(TrophyDef trophy, TrophyProgress progress) =>
    valueForCategory(trophy.category, progress) >= trophy.threshold;

/// Ids de [kTrophies] que [progress] já cruza mas ainda não estão em
/// [alreadyUnlocked] — os "recém-desbloqueados" desta checagem.
List<String> checkNewTrophies(
  TrophyProgress progress,
  Set<String> alreadyUnlocked,
) =>
    [
      for (final t in kTrophies)
        if (!alreadyUnlocked.contains(t.id) && isTrophyUnlocked(t, progress))
          t.id,
    ];
