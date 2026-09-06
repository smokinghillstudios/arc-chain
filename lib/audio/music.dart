import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

/// Trilhas disponíveis (arquivos em assets/music/, ver LICENSES.md).
enum MusicTrack { map, game }

/// Música de fundo em loop — porte do serviço do ARCO: uma trilha para o
/// menu e outra para as fases. Player único (MediaPlayer) com foco de áudio
/// padrão — pausa se outro app tomar o foco e quando o jogo vai para
/// background.
class Music with WidgetsBindingObserver {
  Music._();
  static final Music instance = Music._();

  static final bool _isTestEnv =
      Platform.environment.containsKey('FLUTTER_TEST');

  static const _volume = 0.35;

  AudioPlayer? _player;
  MusicTrack? _current;
  bool _observing = false;

  bool _enabled = true;
  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;
    if (!value) {
      _player?.pause();
    } else {
      _resumeCurrent();
    }
  }

  /// Toca a trilha em loop (troca com stop; ignora se já é a corrente).
  Future<void> play(MusicTrack track) async {
    if (_isTestEnv) return;
    final alreadyPlaying =
        _current == track && _player?.state == PlayerState.playing;
    _current = track;
    if (!_enabled || alreadyPlaying) return;
    try {
      final player = await _ensurePlayer();
      await player.stop();
      await player.play(AssetSource('music/${track.name}.mp3'));
    } catch (_) {
      // Plugin indisponível: jogo segue sem música.
    }
  }

  Future<AudioPlayer> _ensurePlayer() async {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(_volume);
    _player = player;
    if (!_observing) {
      _observing = true;
      WidgetsBinding.instance.addObserver(this);
    }
    return player;
  }

  void _resumeCurrent() {
    if (!_enabled || _current == null) return;
    _player?.resume().catchError((_) {});
  }

  /// Pausa em background, retoma ao voltar (ciclo de vida do app).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _resumeCurrent();
      case AppLifecycleState.paused ||
            AppLifecycleState.inactive ||
            AppLifecycleState.hidden ||
            AppLifecycleState.detached:
        _player?.pause();
    }
  }
}
