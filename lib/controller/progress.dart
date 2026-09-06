import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Progresso persistente: melhor número de estrelas por fase.
class Progress {
  Progress._();
  static final Progress instance = Progress._();

  static const _key = 'arcChainProgress';
  static const _soundKey = 'arcChainSound';
  static const _musicKey = 'arcChainMusic';
  static const _cpKey = 'arcChainCheckpoints';
  final Map<int, int> best = {};

  /// Paradas de vídeo já liberadas (1, 2, …).
  final Set<int> checkpoints = {};

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
    } catch (_) {
      best.clear();
      checkpoints.clear();
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
}
