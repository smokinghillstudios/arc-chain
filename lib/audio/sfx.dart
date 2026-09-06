import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

/// Serviço de efeitos sonoros — mesmo padrão do ARCO: WAVs em assets/sfx/
/// tocados por AudioPool em modo lowLatency (SoundPool do Android).
///
/// Todas as chamadas são fire-and-forget e engolem erros (em testes o
/// plugin de áudio não existe).
class Sfx {
  Sfx._();
  static final Sfx instance = Sfx._();

  bool enabled = true;

  static final bool _isTestEnv =
      Platform.environment.containsKey('FLUTTER_TEST');

  final _pools = <String, Future<AudioPool>>{};
  final _lastStart = <String, DateTime>{};

  /// Nenhum SFX passa de ~1s; folga para devolver o player ao pool
  /// (lowLatency não emite onPlayerComplete).
  static const _recycleAfter = Duration(milliseconds: 1400);

  /// Intervalo mínimo entre plays do MESMO som (toques em sequência).
  static const _minGap = Duration(milliseconds: 30);

  /// Sem disputa de audio focus: SFX de jogo não deve pausar outros áudios.
  static final _sfxContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  Future<void> _play(String name, {int maxPlayers = 3}) async {
    if (!enabled || _isTestEnv) return;
    final now = DateTime.now();
    final last = _lastStart[name];
    if (last != null && now.difference(last) < _minGap) return;
    _lastStart[name] = now;
    try {
      final pool = _pools.putIfAbsent(
        name,
        () => AudioPool.create(
          source: AssetSource('sfx/$name.wav'),
          maxPlayers: maxPlayers,
          playerMode: PlayerMode.lowLatency,
          audioContext: _sfxContext,
        ),
      );
      final stop = await (await pool).start();
      Future.delayed(_recycleAfter, () {
        stop().catchError((_) {});
      });
    } catch (_) {
      _pools.remove(name); // plugin ausente (testes) ou falha de carga
    }
  }

  // ── API do Arc Chain sobre os SFX do ARCO ──
  void tap() => _play('rotate', maxPlayers: 4); // girar/alternar arco
  void chainDone() => _play('objhit'); // uma cadeia conectou
  void win() => _play('win'); // fase completa
  void lose() => _play('lose'); // toques esgotados
  void start() => _play('start'); // início de fase
}
