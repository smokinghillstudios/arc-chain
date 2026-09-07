import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Progresso persistente: melhor número de estrelas por fase, paradas de
/// vídeo, visita diária e troféus (ver `core/trophies.dart`).
class Progress {
  Progress._();
  static final Progress instance = Progress._();

  static const _key = 'arcChainProgress';
  static const _soundKey = 'arcChainSound';
  static const _musicKey = 'arcChainMusic';
  static const _cpKey = 'arcChainCheckpoints';
  static const _lastVisitKey = 'arcChainLastVisitDate';
  static const _consecutiveDaysKey = 'arcChainConsecutiveDays';
  static const _totalDaysKey = 'arcChainTotalDaysPlayed';
  static const _unlockedTrophiesKey = 'arcChainUnlockedTrophies';
  static const _seenTrophyIdsKey = 'arcChainSeenTrophyIds';
  static const _everLostKey = 'arcChainEverLost';
  static const _flawlessKey = 'arcChainFlawlessFirstClears';
  static const _comebackKey = 'arcChainComebackWins';

  final Map<int, int> best = {};

  /// Paradas de vídeo já liberadas (1, 2, …).
  final Set<int> checkpoints = {};

  /// Data (`aaaa-mm-dd`) da última visita contabilizada — `null` se o
  /// jogador nunca abriu a tela de visita diária.
  String? lastVisitDate;

  /// Dias seguidos jogando sem pular nenhum (ver `daily_visit_screen.dart`).
  int consecutiveDays = 0;

  /// Dias totais jogados, não precisam ser seguidos.
  int totalDaysPlayed = 0;

  /// Ids de troféus (`core/trophies.dart`) já desbloqueados.
  final Set<String> unlockedTrophies = {};

  /// Ids de troféus já vistos na sala de troféus — a diferença com
  /// [unlockedTrophies] é o que acende o pontinho de "novidade".
  final Set<String> seenTrophyIds = {};

  /// Fases já perdidas ao menos uma vez (esgotaram os toques) — usado só
  /// pra decidir o troféu "flawless" na 1ª vitória de cada fase; some do
  /// set assim que essa 1ª vitória acontece (não serve mais depois disso).
  final Set<int> everLost = {};

  /// Quantas fases foram vencidas "de primeira" — nunca perdidas antes da
  /// 1ª vitória (troféu `flawless`).
  int flawlessFirstClears = 0;

  /// Quantas fases foram vencidas depois de aceitar o vídeo de toques
  /// extra na derrota, na mesma tentativa (troféu `comeback`).
  int comebackWins = 0;

  /// Fases concluídas em sequência a partir da 1 (progressão da trilha) —
  /// mesma conta usada pelo mapa de fases e pelo troféu `campaign`. Sem
  /// teto real — só para no primeiro buraco de progresso; o `1 << 20` é só
  /// uma trava de segurança contra dado salvo corrompido.
  int get completedStreak {
    var n = 0;
    while (n < (1 << 20) && (best[n + 1] ?? 0) > 0) {
      n++;
    }
    return n;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        best
          ..clear()
          ..addAll(map.map((k, v) => MapEntry(int.parse(k), v as int)));
      }
      final cps = prefs.getString(_cpKey);
      if (cps != null) {
        checkpoints
          ..clear()
          ..addAll((jsonDecode(cps) as List).cast<int>());
      }
      lastVisitDate = prefs.getString(_lastVisitKey);
      consecutiveDays = prefs.getInt(_consecutiveDaysKey) ?? 0;
      totalDaysPlayed = prefs.getInt(_totalDaysKey) ?? 0;
      unlockedTrophies
        ..clear()
        ..addAll(prefs.getStringList(_unlockedTrophiesKey) ?? const []);
      seenTrophyIds
        ..clear()
        ..addAll(prefs.getStringList(_seenTrophyIdsKey) ?? const []);
      final lost = prefs.getString(_everLostKey);
      everLost.clear();
      if (lost != null) {
        everLost.addAll((jsonDecode(lost) as List).cast<int>());
      }
      flawlessFirstClears = prefs.getInt(_flawlessKey) ?? 0;
      comebackWins = prefs.getInt(_comebackKey) ?? 0;
    } catch (_) {
      best.clear();
      checkpoints.clear();
      lastVisitDate = null;
      consecutiveDays = 0;
      totalDaysPlayed = 0;
      unlockedTrophies.clear();
      seenTrophyIds.clear();
      everLost.clear();
      flawlessFirstClears = 0;
      comebackWins = 0;
    }
  }

  Future<void> saveCheckpoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cpKey, jsonEncode(checkpoints.toList()));
    } catch (_) {}
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(best.map((k, v) => MapEntry('$k', v))));
    } catch (_) {}
  }

  Future<bool> loadSoundEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_soundKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> saveSoundEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundKey, value);
    } catch (_) {}
  }

  Future<bool> loadMusicEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_musicKey) ?? true;
    } catch (_) {}
    return true;
  }

  Future<void> saveMusicEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_musicKey, value);
    } catch (_) {}
  }

  /// Grava a visita de hoje: [lastVisitDate]/[consecutiveDays]/
  /// [totalDaysPlayed] já devem estar atualizados no objeto antes de chamar
  /// (ver `daily_visit_screen.dart`).
  Future<void> saveDailyVisit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (lastVisitDate != null) {
        await prefs.setString(_lastVisitKey, lastVisitDate!);
      }
      await prefs.setInt(_consecutiveDaysKey, consecutiveDays);
      await prefs.setInt(_totalDaysKey, totalDaysPlayed);
    } catch (_) {}
  }

  Future<void> saveUnlockedTrophies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _unlockedTrophiesKey, unlockedTrophies.toList());
    } catch (_) {}
  }

  Future<void> saveSeenTrophyIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_seenTrophyIdsKey, seenTrophyIds.toList());
    } catch (_) {}
  }

  Future<void> saveEverLost() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_everLostKey, jsonEncode(everLost.toList()));
    } catch (_) {}
  }

  Future<void> saveFlawlessFirstClears() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_flawlessKey, flawlessFirstClears);
    } catch (_) {}
  }

  Future<void> saveComebackWins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_comebackKey, comebackWins);
    } catch (_) {}
  }
}
