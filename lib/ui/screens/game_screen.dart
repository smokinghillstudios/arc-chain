import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../ads/ads_service.dart';
import '../../audio/music.dart';
import '../../audio/sfx.dart';
import '../../controller/progress.dart';
import '../../core/engine.dart';
import '../board/board_painter.dart';
import '../widgets/app_background.dart';
import '../widgets/hud_top.dart';
import '../overlays/game_dialogs.dart';

const int animDelayMs = 100;

class _RepaintNotifier extends ChangeNotifier {
  void tick() => notifyListeners();
}

class GameScreen extends StatefulWidget {
  final LevelDef level;
  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late LevelDef _level;
  late GameBoard _board;

  final Map<String, List<ActiveArc>> _highlighted = {};
  final List<Particle> _particles = [];
  final _repaint = _RepaintNotifier();
  final _rng = math.Random();

  int _flipCount = 0;

  /// Um "run id" por cadeia — permite refazer só a caminhada de UMA cadeia
  /// (quando um toque só pode ter afetado ela) sem cancelar as caminhadas
  /// em andamento das outras.
  List<int> _chainRunIds = [];
  bool _boardLocked = false;
  int _stars = 0;
  bool _showNext = false;

  /// Toques extras ganhos por vídeo premiado.
  int _extraTaps = 0;

  /// Banner do topo (espaço reservado mesmo enquanto carrega).
  BannerAd? _banner;
  bool _bannerRequested = false;

  late final Ticker _ticker;

  int get _maxTaps => _board.maxTaps + _extraTaps;

  @override
  void initState() {
    super.initState();
    _level = widget.level;
    _startLevel(_level);
    _ticker = createTicker(_onTick)..start();
    Music.instance.play(MusicTrack.game);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBanner());
  }

  @override
  void dispose() {
    // Cancela todas as caminhadas pendentes.
    for (var i = 0; i < _chainRunIds.length; i++) {
      _chainRunIds[i]++;
    }
    _ticker.dispose();
    _banner?.dispose();
    // De volta ao menu: retoma a trilha dos menus.
    Music.instance.play(MusicTrack.map);
    super.dispose();
  }

  /// Banner adaptativo ancorado, dimensionado pela largura da tela
  /// (mesmo padrão do ARCO).
  Future<void> _loadBanner() async {
    if (!AdsService.instance.adsAvailable || _bannerRequested || !mounted) {
      return;
    }
    _bannerRequested = true;
    try {
      final width = MediaQuery.sizeOf(context).width.truncate();
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width) ??
          AdSize.banner;
      final banner = BannerAd(
        adUnitId: kAdMobBannerUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() => _banner = ad as BannerAd);
            } else {
              ad.dispose();
            }
          },
          onAdFailedToLoad: (ad, _) => ad.dispose(),
        ),
      );
      await banner.load();
    } catch (_) {
      // SDK indisponível: o espaço reservado fica vazio.
    }
  }

  void _onTick(Duration elapsed) {
    _updateParticles();
    _repaint.tick();
  }

  void _startLevel(LevelDef level) {
    _level = level;
    _board = GameBoard.generate(level);
    _chainRunIds = List.filled(_board.chains.length, 0);
    _flipCount = 0;
    _boardLocked = false;
    _stars = 0;
    _showNext = false;
    _extraTaps = 0;
    _highlighted.clear();
    _particles.clear();
    Sfx.instance.start();
    if (mounted) setState(() {});
    _runAllChains();
  }

  // ── Partículas (confete ao conectar) ──

  void _spawnConfetti(double px, double py) {
    const colors = [
      Color(0xFFF1C40F),
      Color(0xFF7FB56A),
      Color(0xFFE74C3C),
      Color(0xFF4A7FA5),
      Color(0xFFF5F0E8),
    ];
    for (var i = 0; i < 32; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 1.5 + _rng.nextDouble() * 3.5;
      _particles.add(Particle(
        x: px,
        y: py,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 1.5,
        life: 40 + _rng.nextDouble() * 20,
        maxLife: 60,
        color: colors[_rng.nextInt(colors.length)],
        size: 2 + _rng.nextDouble() * 3,
      ));
    }
  }

  void _updateParticles() {
    for (var i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.12;
      p.life--;
      if (p.life <= 0) _particles.removeAt(i);
    }
  }

  // ── Fluxo das cadeias ──

  void _runAllChains() {
    _highlighted.clear();
    for (final ch in _board.chains) {
      ch.success = false;
    }
    if (mounted) setState(() {});
    for (var i = 0; i < _board.chains.length; i++) {
      _chainRunIds[i]++;
      _walkChain(i, _chainRunIds[i]);
    }
  }

  /// Refaz só a caminhada da cadeia [chainIdx] — usado quando um toque só
  /// pode ter mudado essa cadeia (girou o início dela, ou alterou uma
  /// célula que ela atravessa). As outras cadeias ficam intocadas: nem o
  /// destaque delas no tabuleiro, nem a animação em andamento são reiniciados.
  ///
  /// Se [fromKey] for passado (célula comum alterada, não o início), o
  /// redesenho retoma exatamente daquele ponto: o trecho já desenhado antes
  /// dele é preservado (chegar numa célula não depende do próprio tipo
  /// dela, só do caminho até ali — então esse trecho é sempre válido) e só
  /// o que vem depois é apagado e reanimado. Girar o início muda a cadeia
  /// inteira desde o primeiro passo, então nesse caso ([fromKey] nulo) ela
  /// é refeita do zero mesmo.
  void _runChain(int chainIdx, {String? fromKey}) {
    final ch = _board.chains[chainIdx];

    if (fromKey != null) {
      final resume = _simulateUntil(chainIdx, fromKey);
      if (resume != null) {
        final keep = resume.prefix.toSet();
        _highlighted.removeWhere((key, arcs) {
          if (keep.contains(key)) return false;
          arcs.removeWhere((a) => a.color == ch.color);
          return arcs.isEmpty;
        });
        ch.success = false;
        if (mounted) setState(() {});
        _chainRunIds[chainIdx]++;
        _walkChain(chainIdx, _chainRunIds[chainIdx],
            startAt: resume.cur, startEntry: resume.entry);
        return;
      }
      // A caminhada atual nunca alcança [fromKey] (ex.: já tinha entrado
      // em laço antes) — não há trecho válido pra preservar, refaz tudo.
    }

    _highlighted.removeWhere((key, arcs) {
      arcs.removeWhere((a) => a.color == ch.color);
      return arcs.isEmpty;
    });
    ch.success = false;
    if (mounted) setState(() {});
    _chainRunIds[chainIdx]++;
    _walkChain(chainIdx, _chainRunIds[chainIdx]);
  }

  /// Simula a cadeia [chainIdx] de forma síncrona (sem animação, sem tocar
  /// em `_highlighted`) a partir do início dela até alcançar a célula
  /// [targetKey]. Retorna a posição/direção de entrada exatamente ao
  /// chegar lá, e a lista (em ordem) das células visitadas antes dela — ou
  /// `null` se a caminhada termina (sucesso, bloqueio ou laço) sem nunca
  /// passar por [targetKey].
  ({Pos cur, int entry, List<String> prefix})? _simulateUntil(
      int chainIdx, String targetKey) {
    final board = _board;
    final rows = board.rows;
    final cols = board.cols;
    final ch = board.chains[chainIdx];
    final d0 = exitToDelta[ch.startDir]!;
    var cur = Pos((ch.start.r + d0[0] + rows) % rows,
        (ch.start.c + d0[1] + cols) % cols);
    var entry = opposite(ch.startDir);
    final seenStates = <String>{};
    final prefix = <String>[];

    while (true) {
      if (cur.key == targetKey) return (cur: cur, entry: entry, prefix: prefix);

      final isOwnEndCell = cur.r == ch.end.r && cur.c == ch.end.c;
      if (isOwnEndCell) return null;
      if (board.chains.any((c) => c.end.r == cur.r && c.end.c == cur.c)) {
        return null;
      }
      if (board.chains.any((c) => c.start.r == cur.r && c.start.c == cur.c)) {
        return null;
      }

      final type = board.grid[cur.r][cur.c];
      final exit = getExit(type, entry)!;
      prefix.add(cur.key);

      final stateKey = '${cur.key},$entry';
      if (seenStates.contains(stateKey)) return null;
      seenStates.add(stateKey);

      final d = exitToDelta[exit]!;
      cur = Pos((cur.r + d[0] + rows) % rows, (cur.c + d[1] + cols) % cols);
      entry = opposite(exit);
    }
  }

  Future<void> _walkChain(int chainIdx, int myRun,
      {Pos? startAt, int? startEntry}) async {
    final board = _board;
    final rows = board.rows;
    final cols = board.cols;
    final ch = board.chains[chainIdx];
    Pos cur;
    int entry;
    if (startAt != null && startEntry != null) {
      cur = startAt;
      entry = startEntry;
    } else {
      final d0 = exitToDelta[ch.startDir]!;
      cur = Pos((ch.start.r + d0[0] + rows) % rows,
          (ch.start.c + d0[1] + cols) % cols);
      entry = opposite(ch.startDir);
    }

    final seenStates = <String>{};

    while (true) {
      if (myRun != _chainRunIds[chainIdx] || !mounted) return;

      final isOwnEndCell = cur.r == ch.end.r && cur.c == ch.end.c;
      if (isOwnEndCell) {
        ch.success = true;
        Sfx.instance.chainDone();
        _spawnConfetti(
            ch.end.c * kCell + kCell / 2, ch.end.r * kCell + kCell / 2);
        if (board.chains.every((c) => c.success)) _onLevelComplete();
        if (mounted) setState(() {});
        return;
      }

      if (board.chains.any((c) => c.end.r == cur.r && c.end.c == cur.c)) return;
      if (board.chains.any((c) => c.start.r == cur.r && c.start.c == cur.c)) {
        return;
      }

      final type = board.grid[cur.r][cur.c];
      final exit = getExit(type, entry)!;
      final pIdx = pairIndex(type, entry, exit);
      final key = cur.key;
      final existing = _highlighted[key];
      if (existing != null) {
        if (!existing.any((a) => a.idx == pIdx)) {
          existing.add(ActiveArc(pIdx, ch.color));
        }
      } else {
        _highlighted[key] = [ActiveArc(pIdx, ch.color)];
      }

      // detecção de ciclo: quando o estado se repete, todos os arcos do
      // laço já estão acesos — a caminhada pode parar
      final stateKey = '$key,$entry';
      if (seenStates.contains(stateKey)) return;
      seenStates.add(stateKey);

      await Future.delayed(const Duration(milliseconds: animDelayMs));
      if (myRun != _chainRunIds[chainIdx] || !mounted) return;

      final d = exitToDelta[exit]!;
      cur = Pos((cur.r + d[0] + rows) % rows, (cur.c + d[1] + cols) % cols);
      entry = opposite(exit);
    }
  }

  int _computeStars() {
    if (_flipCount <= _board.minTaps) return 3;
    if (_flipCount <=
        _board.minTaps + (_board.maxTaps - _board.minTaps) * 0.5) {
      return 2;
    }
    return 1;
  }

  Future<void> _onLevelComplete() async {
    _stars = _computeStars();
    _showNext = true; // bloqueia novos toques no tabuleiro
    Sfx.instance.win();
    if (mounted) setState(() {});

    final prev = Progress.instance.best[_level.id] ?? 0;
    if (_stars > prev) {
      Progress.instance.best[_level.id] = _stars;
      await Progress.instance.save();
    }

    // Deixa o confete brilhar antes do diálogo de vitória.
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted || !_showNext) return; // fase reiniciada nesse meio tempo
    final action = await showVictoryDialog(context, stars: _stars);
    if (!mounted) return;
    switch (action) {
      case VictoryAction.retry:
        _resetBoard(); // mesma fase, sem passar pelo mapa
      case VictoryAction.menu:
      case null:
        // Volta ao mapa (como no ARCO) — é lá que o pedágio de vídeo entre
        // grupos de 5 fases fica clicável.
        Navigator.of(context).pop();
    }
  }

  // ── Interação ──

  void _onBoardTap(Offset local, double cellPx) {
    if (_boardLocked || _showNext) return;
    final c = (local.dx / cellPx).floor();
    final r = (local.dy / cellPx).floor();
    if (r < 0 || r >= _board.rows || c < 0 || c >= _board.cols) return;

    final isEndCell =
        _board.chains.any((ch) => ch.end.r == r && ch.end.c == c);
    if (isEndCell) return;

    var startChainIdx = -1;
    for (var i = 0; i < _board.chains.length; i++) {
      if (_board.chains[i].start.r == r && _board.chains[i].start.c == c) {
        startChainIdx = i;
        break;
      }
    }

    Set<int> affected;
    String? changedKey;
    if (startChainIdx != -1) {
      final startChain = _board.chains[startChainIdx];
      startChain.startDir = (startChain.startDir + 1) % 4;
      // Só essa cadeia começa de um jeito diferente agora — as outras
      // não usam esse início, então continuam exatamente como estavam.
      affected = {startChainIdx};
    } else {
      final type = _board.grid[r][c];
      if (type == 'A') {
        _board.grid[r][c] = 'B';
      } else if (type == 'B') {
        _board.grid[r][c] = 'A';
      } else {
        return;
      }
      changedKey = '$r,$c';
      // Só as cadeias que hoje atravessam esta célula podem ter mudado de
      // rota — se nenhuma passa por aqui, nenhuma caminhada precisa ser
      // refeita (alcançar esta célula não depende do próprio tipo dela).
      final arcsHere = _highlighted[changedKey] ?? const [];
      affected = {
        for (final arc in arcsHere)
          _board.chains.indexWhere((ch) => ch.color == arc.color),
      }..removeWhere((i) => i < 0);
    }

    Sfx.instance.tap();
    _flipCount++;
    if (_flipCount >= _maxTaps) {
      _boardLocked = true;
      Sfx.instance.lose();
      // Espera as cadeias assentarem: o último toque ainda pode vencer.
      Future.delayed(const Duration(milliseconds: 1500), _offerExtraTaps);
    }
    setState(() {});
    for (final idx in affected) {
      _runChain(idx, fromKey: changedKey);
    }
  }

  /// Toques esgotados: diálogo único de derrota com oferta de vídeo
  /// (+[kDefeatExtraTaps] toques) e as ações tentar de novo / voltar ao
  /// mapa — espelhando o `_DefeatDialog` do ARCO.
  Future<void> _offerExtraTaps() async {
    if (!mounted || !_boardLocked || _showNext) return;

    final action = await showDefeatDialog(context);
    if (!mounted) return;
    switch (action) {
      case DefeatAction.continueWithVideo:
        setState(() {
          _extraTaps += kDefeatExtraTaps;
          _boardLocked = false;
        });
      case DefeatAction.retry:
        _resetBoard();
      case DefeatAction.menu:
      case null:
        Navigator.of(context).pop();
    }
  }

  void _resetBoard() {
    _board.reset();
    _flipCount = 0;
    _boardLocked = false;
    _stars = 0;
    _showNext = false;
    _extraTaps = 0;
    setState(() {});
    _runAllChains();
  }

  /// Configurações (engrenagem do HUD): reiniciar, voltar, som e música.
  Future<void> _openSettings() async {
    final action = await showSettingsDialog(
      context,
      soundEnabled: Sfx.instance.enabled,
      musicEnabled: Music.instance.enabled,
      onToggleSound: (value) {
        Sfx.instance.enabled = value;
        Progress.instance.saveSoundEnabled(value);
      },
      onToggleMusic: (value) {
        Music.instance.enabled = value;
        Progress.instance.saveMusicEnabled(value);
      },
    );
    if (!mounted) return;
    switch (action) {
      case SettingsAction.resetLevel:
        _resetBoard();
      case SettingsAction.backToMap:
        Navigator.of(context).pop();
      case null:
        break;
    }
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Espaço superior reservado ao banner (AdMob) — mantém a altura
              // mesmo antes do anúncio carregar para o tabuleiro não pular.
              SizedBox(
                height: (_banner?.size.height ?? 50).toDouble(),
                child: _banner == null
                    ? const SizedBox.shrink()
                    : Center(
                        child: SizedBox(
                          width: _banner!.size.width.toDouble(),
                          height: _banner!.size.height.toDouble(),
                          child: AdWidget(ad: _banner!),
                        ),
                      ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Altura reservada ao HUD (~72) + espaçamentos.
                    const reserved = 72.0 + 12.0 + 24.0;
                    final rows = _board.rows;
                    final cols = _board.cols;
                    // Célula quadrada: o menor dos dois limites (largura e
                    // altura disponíveis) decide o tamanho — fases mais
                    // altas que largas usam a altura da tela em vez de
                    // ficarem espremidas num quadrado.
                    final cellPx = [
                      (constraints.maxWidth - 32) / cols,
                      (constraints.maxHeight - reserved) / rows,
                      70.0, // teto: fases pequenas não viram células gigantes
                    ].reduce((a, b) => a < b ? a : b);
                    final boardWidth = cols * cellPx;
                    final boardHeight = rows * cellPx;
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RepaintBoundary(
                            child: HudTop(
                              width: boardWidth,
                              remaining: _maxTaps - _flipCount,
                              level: _level,
                              onSettings: _openSettings,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RepaintBoundary(
                            child: _buildBoard(boardWidth, boardHeight, cellPx),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoard(double boardWidth, double boardHeight, double cellPx) {
    return AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _boardLocked ? 0.45 : 1.0,
          child: Container(
            width: boardWidth,
            height: boardHeight,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4A7695), Color(0xFF345875)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(0, 10)),
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 16),
                    blurRadius: 30),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                onTapDown: (d) => _onBoardTap(d.localPosition, cellPx),
                child: CustomPaint(
                  size: Size(boardWidth, boardHeight),
                  painter: BoardPainter(
                    board: _board,
                    highlighted: _highlighted,
                    particles: _particles,
                    repaint: _repaint,
                  ),
                ),
              ),
            ),
          ),
        );
  }
}
