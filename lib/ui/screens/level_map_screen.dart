import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../ads/ads_service.dart';
import '../../audio/music.dart';
import '../../controller/progress.dart';
import '../../core/engine.dart';
import '../overlays/game_dialogs.dart' show kSimulatedAdSeconds;
import '../overlays/phase_detail_dialog.dart';
import '../theme.dart';
import '../widgets/arc_ring.dart';
import '../widgets/audio_toggle_button.dart';
import '../widgets/hex_badge.dart';
import 'game_screen.dart';

/// Desbloqueia todas as fases para testar. Ativo apenas em builds debug
/// (release mantém a progressão normal) — mesma decisão do ARCO.
bool debugUnlockAllLevels = kDebugMode;

/// Quantas fases o horizonte cresce de cada vez que o jogador chega perto
/// do topo do que já foi desenhado (ver `_growHorizon`).
const int _kHorizonChunk = 50;

/// Seleção de fases estilo ARCO: trilha serpenteante com corda de cânhamo
/// e nós circulares de baixo para cima. Sem fim — a trilha cresce sozinha
/// conforme o jogador rola (ver `_horizonLevels`/`_growHorizon`), em vez de
/// ter um total de fases fixo.
class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  final _scroll = ScrollController();

  /// Até onde a trilha já foi desenhada/testada por toque — cresce sozinho
  /// conforme o jogador rola perto do topo (ver `_growHorizon`). Começa
  /// generoso o bastante pra cobrir o progresso atual mais uma folga.
  late int _horizonLevels;

  /// Estado local do botão de música do cabeçalho (a fonte de verdade é
  /// `Music.instance.enabled`).
  late bool _musicOn = Music.instance.enabled;

  Map<int, int> get _stars => Progress.instance.best;

  /// Fases concluídas em sequência a partir da 1 (progressão da trilha).
  /// Sem teto real — só para no primeiro buraco de progresso; o `1 << 20`
  /// é só uma trava de segurança contra dado salvo corrompido.
  int get _completedStreak {
    var n = 0;
    while (n < (1 << 20) && (_stars[n + 1] ?? 0) > 0) {
      n++;
    }
    return n;
  }

  Set<int> get _checkpoints => Progress.instance.checkpoints;

  /// Fase liberada: progressão + todas as paradas de vídeo anteriores vistas.
  bool _phaseUnlocked(int level) {
    if (debugUnlockAllLevels) return true;
    if (level > _completedStreak + 1) return false;
    for (var k = 1; k <= (level - 1) ~/ kCheckpointEvery; k++) {
      if (!_checkpoints.contains(k)) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _horizonLevels = math.max(100, _completedStreak + 30);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    // Trava a rolagem para nunca revelar o vazio acima da nuvem de fim de
    // trilha, e cresce o horizonte quando chega perto do topo (ver
    // `cloudTopY`/`_minScrollOffset`/`_growHorizon`).
    _scroll.addListener(_clampScroll);
    _scroll.addListener(_maybeGrowHorizon);
  }

  @override
  void dispose() {
    _scroll.removeListener(_clampScroll);
    _scroll.removeListener(_maybeGrowHorizon);
    _scroll.dispose();
    super.dispose();
  }

  /// Y mínimo de rolagem: o ponto em que o retângulo branco da nuvem já
  /// preenche o topo da tela — rolar além disso mostraria hexágonos vazios
  /// (nada) acima da nuvem, o que não deve acontecer.
  double get _minScrollOffset {
    final width = MediaQuery.sizeOf(context).width;
    final mapSize = Size(width, mapHeightFor(_horizonLevels));
    final ropeEnd = _slotPosition(mapSize, totalSlotsFor(_horizonLevels));
    return cloudTopY(mapSize, ropeEnd).clamp(0.0, double.infinity);
  }

  void _clampScroll() {
    if (!_scroll.hasClients) return;
    final minOffset = _minScrollOffset;
    if (_scroll.offset < minOffset) {
      _scroll.jumpTo(minOffset);
    }
  }

  /// Estende a trilha (mais `_kHorizonChunk` fases) quando o jogador rola
  /// perto do topo do que já foi desenhado — a trilha "infinita" nunca
  /// precisa de um total de fases predefinido, só cresce sob demanda.
  void _maybeGrowHorizon() {
    if (!_scroll.hasClients) return;
    final viewport = _scroll.position.viewportDimension;
    // Margem de ~2 telas antes do topo atual — dá tempo de crescer antes
    // do jogador realmente alcançar o fim do que já existe.
    if (_scroll.offset > _minScrollOffset + viewport * 2) return;
    _growHorizon();
  }

  void _growHorizon() {
    final oldHeight = mapHeightFor(_horizonLevels);
    setState(() => _horizonLevels += _kHorizonChunk);
    final deltaHeight = mapHeightFor(_horizonLevels) - oldHeight;
    // A trilha é ancorada pelo fim (fase 1 fica perto da base do canvas),
    // então crescer o canvas empurra a coordenada Y de tudo que já existia
    // pra baixo, na mesma quantidade — compensa a rolagem pelo mesmo tanto
    // pra manter exatamente o que já estava na tela, sem pulo visual.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.offset + deltaHeight);
    });
  }

  void _toggleMusic() {
    setState(() => _musicOn = !_musicOn);
    Music.instance.enabled = _musicOn;
    Progress.instance.saveMusicEnabled(_musicOn);
  }

  void _scrollToCurrent() {
    if (!_scroll.hasClients) return;
    final current = (_completedStreak + 1).clamp(1, _horizonLevels);
    final nodeY = mapHeightFor(_horizonLevels) - 110 - levelSlot(current - 1) * 78.0;
    final viewport = _scroll.position.viewportDimension;
    _scroll.jumpTo(
      (nodeY - viewport * 0.55)
          .clamp(_minScrollOffset, _scroll.position.maxScrollExtent),
    );
  }

  Future<void> _openLevel(int level) async {
    final def = levelForId(level);
    final play = await showPhaseDetailDialog(context, level: def);
    if (play != true || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(level: def)),
    );
    if (mounted) setState(() {}); // atualiza estrelas/progressão ao voltar
  }

  void _onTapUp(TapUpDetails details) {
    final local = details.localPosition;
    final mapSize =
        Size(MediaQuery.sizeOf(context).width, mapHeightFor(_horizonLevels));

    // Paradas de vídeo primeiro (ficam entre os nós).
    final cps = checkpointPositions(mapSize, _horizonLevels);
    for (var k = 1; k <= cps.length; k++) {
      if ((local - cps[k - 1]).distance <= 30) {
        _openCheckpoint(k);
        return;
      }
    }

    final positions = levelNodePositions(mapSize, _horizonLevels);
    for (var i = 0; i < _horizonLevels; i++) {
      if ((local - positions[i]).distance <= 34) {
        final level = i + 1;
        if (_phaseUnlocked(level)) _openLevel(level);
        return;
      }
    }
  }

  /// Parada de vídeo: vídeo obrigatório libera as fases seguintes.
  Future<void> _openCheckpoint(int k) async {
    if (_checkpoints.contains(k)) return; // já liberada
    final reachable = debugUnlockAllLevels ||
        _completedStreak >= k * kCheckpointEvery;
    if (!reachable) return;

    final watched = await showCheckpointDialog(context);
    if (watched == true && mounted) {
      setState(() => _checkpoints.add(k));
      Progress.instance.saveCheckpoints();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back_rounded,
                        color: ink.withValues(alpha: 0.55)),
                  ),
                  AudioToggleButton(
                    enabled: _musicOn,
                    iconOn: Icons.music_note,
                    iconOff: Icons.music_off,
                    tooltip: _musicOn ? 'Desligar música' : 'Ligar música',
                    onTap: _toggleMusic,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                child: GestureDetector(
                  onTapUp: _onTapUp,
                  child: SizedBox(
                    width: double.infinity,
                    height: mapHeightFor(_horizonLevels),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: LevelMapPainter(
                          completedStreak: _completedStreak,
                          scroll: _scroll,
                          horizonLevels: _horizonLevels,
                          stars: Map.of(_stars),
                          checkpoints: Set.of(_checkpoints),
                          unlockAll: debugUnlockAllLevels,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A cada [kCheckpointEvery] fases há uma parada de vídeo obrigatória na
/// corda (entre a fase 5k e a 5k+1).
const int kCheckpointEvery = 5;
int checkpointCountFor(int totalLevels) => (totalLevels - 1) ~/ kCheckpointEvery;

/// A trilha é uma sequência de "slots" igualmente espaçados: fases e
/// paradas de vídeo ocupam cada uma o seu slot. Parametrizado pelo
/// horizonte atual da tela (não há um total de fases fixo — a trilha
/// cresce sob demanda, ver `_LevelMapScreenState._growHorizon`).
int totalSlotsFor(int totalLevels) =>
    totalLevels + checkpointCountFor(totalLevels);

/// Slot da fase i (0-based): desloca 1 slot a cada parada anterior.
int levelSlot(int i) => i + i ~/ kCheckpointEvery;

/// Slot da parada de vídeo k (1+): logo após a fase 5k.
int _checkpointSlot(int k) => levelSlot(k * kCheckpointEvery - 1) + 1;

double mapHeightFor(int totalLevels) =>
    110 + (totalSlotsFor(totalLevels) - 1) * 78.0 + 150;

/// Posição de um slot: onda senoidal com um segundo harmônico leve — a
/// trilha flui em curvas largas e orgânicas (mesma fórmula do ARCO).
Offset _slotPosition(Size size, int slot) {
  final yStart = size.height - 110;
  return Offset(
    size.width *
        (0.5 +
            0.21 * math.sin(slot * 0.75) +
            0.05 * math.sin(slot * 0.31 + 1.7)),
    yStart - slot * 78.0,
  );
}

/// Posição de cada nó de fase (compartilhada entre pintura e hit-test).
List<Offset> levelNodePositions(Size size, int totalLevels) =>
    [for (var i = 0; i < totalLevels; i++) _slotPosition(size, levelSlot(i))];

/// Posições das paradas de vídeo (compartilhada entre pintura e hit-test).
List<Offset> checkpointPositions(Size size, int totalLevels) => [
      for (var k = 1; k <= checkpointCountFor(totalLevels); k++)
        _slotPosition(size, _checkpointSlot(k)),
    ];

/// Todos os slots em ordem — a corda atravessa todos.
List<Offset> _allSlotPositions(Size size, int totalLevels) => [
      for (var s = 0; s < totalSlotsFor(totalLevels); s++)
        _slotPosition(size, s),
    ];

/// Y do topo do retângulo branco da nuvem de fim de trilha — mesma conta
/// usada por [LevelMapPainter._paintEndCloud] e por
/// `_LevelMapScreenState._minScrollOffset` (que trava a rolagem ali),
/// centralizada aqui para as duas nunca ficarem fora de sincronia.
double cloudTopY(Size mapSize, Offset ropeEnd) {
  final cloudWidth = mapSize.width + 40;
  final cloudHeight = cloudWidth * (400 / 500);
  // A ponta mais funda da camada de trás (path1-0) fica a ~86,2% da
  // altura da figura; ancora essa ponta exatamente onde a corda termina.
  return ropeEnd.dy - 0.862 * cloudHeight;
}

class LevelMapPainter extends CustomPainter {
  /// Fases concluídas em sequência (a atual é a seguinte).
  final int completedStreak;

  /// Controller do scroll do mapa — usado tanto para repintar a cada
  /// rolagem quanto para saber qual trecho está visível (ver [paint]).
  final ScrollController scroll;

  /// Até onde a trilha existe agora (cresce sozinha conforme o jogador
  /// rola — ver `_LevelMapScreenState._horizonLevels`).
  final int horizonLevels;

  /// Estrelas (1–3) por fase concluída.
  final Map<int, int> stars;

  /// Paradas de vídeo já liberadas.
  final Set<int> checkpoints;

  /// Pinta todos os nós como desbloqueados (modo de teste em debug).
  final bool unlockAll;

  LevelMapPainter({
    required this.completedStreak,
    required this.scroll,
    required this.horizonLevels,
    this.stars = const {},
    this.checkpoints = const {},
    this.unlockAll = false,
  }) : super(repaint: scroll);

  /// Mesma regra de liberação usada no hit-test da tela.
  bool _phaseUnlocked(int level) {
    if (unlockAll) return true;
    if (level > completedStreak + 1) return false;
    for (var k = 1; k <= (level - 1) ~/ kCheckpointEvery; k++) {
      if (!checkpoints.contains(k)) return false;
    }
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Janela visível (mais uma margem de folga) — o mapa inteiro chega a
    // milhares de pixels de altura, então só vale a pena desenhar
    // hexágonos/corda/nós perto do que está realmente na tela. Lido do
    // controller a cada chamada (o `repaint: scroll` do construtor garante
    // que paint() roda de novo a cada tick de rolagem).
    const margin = 300.0;
    final viewTop = scroll.hasClients ? scroll.offset : 0.0;
    final viewHeight =
        scroll.hasClients ? scroll.position.viewportDimension : size.height;
    final visibleTop = viewTop - margin;
    final visibleBottom = viewTop + viewHeight + margin;
    bool inView(double y) => y >= visibleTop && y <= visibleBottom;

    final nodes = levelNodePositions(size, horizonLevels);
    final slots = _allSlotPositions(size, horizonLevels);
    _paintHexBackground(canvas, size, slots, visibleTop, visibleBottom);

    final current = (completedStreak + 1).clamp(1, horizonLevels);

    // Corda de cânhamo atravessando TODOS os slots, mais um trecho extra
    // além da última fase, num slot sem nó nenhum — é ali, livre de
    // qualquer fase real, que a nuvem de fim de conteúdo fica (ver
    // _paintEndCloud); a última fase nunca fica coberta por ela.
    // Spline Catmull-Rom: a tangente é contínua ao atravessar cada nó — a
    // corda flui em curvas suaves.
    final ropeSlots = [...slots, _slotPosition(size, totalSlotsFor(horizonLevels))];
    final path = Path()..moveTo(ropeSlots[0].dx, ropeSlots[0].dy);
    for (var i = 0; i < ropeSlots.length - 1; i++) {
      final p0 = ropeSlots[i == 0 ? 0 : i - 1];
      final p1 = ropeSlots[i];
      final p2 = ropeSlots[i + 1];
      final p3 = ropeSlots[math.min(i + 2, ropeSlots.length - 1)];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    _paintRope(canvas, path, visibleTop, visibleBottom);

    _paintCheckpoints(canvas, size, visibleTop, visibleBottom);

    for (var i = 0; i < nodes.length; i++) {
      final level = i + 1;
      final p = nodes[i];
      if (!inView(p.dy)) continue;
      final isCurrent = level == current;
      final unlocked = _phaseUnlocked(level);
      final completed = (stars[level] ?? 0) > 0;
      final radius = isCurrent ? 29.0 : 24.0;

      // Disco do nó (achatado, sem sombra — minimalista).
      canvas.drawCircle(
        p,
        radius,
        Paint()..color = unlocked ? Colors.white : const Color(0xFFF3EEE4),
      );

      if (isCurrent) {
        // Nó atual: anel de arcos segmentados nas cores das cadeias (o
        // mesmo motivo do logo da splash).
        paintSegmentedRing(canvas, p, radius + 3, colors: chainColors);
      } else if (completed) {
        // Concluído: anel cheio numa cor das cadeias (cicla pelo índice).
        canvas.drawCircle(
          p,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = chainColors[i % chainColors.length]
                .withValues(alpha: 0.85),
        );
      } else {
        canvas.drawCircle(
          p,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = unlocked ? 2 : 1.5
            ..color = unlocked ? const Color(0xFFD9D1C1) : paperLine,
        );
      }

      final tp = TextPainter(
        text: TextSpan(
          text: '$level',
          style: TextStyle(
            fontSize: isCurrent ? 16 : 14,
            fontWeight: FontWeight.w800,
            fontFamily: 'Nunito',
            color: isCurrent
                ? ink
                : unlocked
                    ? ink.withValues(alpha: 0.75)
                    : const Color(0xFFC9C0B0),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2 - 1));

      // Estrelas conquistadas (1–3) em leque sobre o nó concluído.
      if (completed) {
        _paintStars(canvas, p, stars[level] ?? 0, radius + 4);
      }
    }

    _paintEndCloud(canvas, size, ropeSlots.last);
  }

  /// Nuvem de fim de trilha: cobre o topo do mapa acima do trecho extra de
  /// corda depois da última fase (ver `ropeSlots` em [paint]) — nunca
  /// sobrepõe a última fase, só o pedaço de corda sem nenhum nó além dela.
  void _paintEndCloud(Canvas canvas, Size size, Offset ropeEnd) {
    final cloudWidth = size.width + 40;
    final cloudHeight = cloudWidth * (400 / 500);
    final cloudTop = cloudTopY(size, ropeEnd);

    canvas.save();
    canvas.translate(-20, cloudTop);
    canvas.scale(cloudWidth / 500, cloudHeight / 400);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 500, 225.14159),
      Paint()..color = Colors.white,
    );

    const clipRect =
        Rect.fromLTWH(80.207939, 377.75388, 496.74683, 263.64923);
    void paintLayer(Path path, Color color, double ty) {
      canvas.save();
      canvas.translate(-80.733213, ty);
      canvas.scale(1.0065489, 0.99634097);
      canvas.clipRect(clipRect);
      canvas.drawPath(path, Paint()..color = color);
      canvas.restore();
    }

    paintLayer(_cloudLayer1, const Color(0xFF93C5FD), -189.56175);
    paintLayer(_cloudLayer2, const Color(0xFFBFDBFE), -189.56175);
    paintLayer(_cloudLayer3, const Color(0xFFDBEAFE), -189.56175);
    paintLayer(_cloudLayer4, Colors.white, -191.56175);

    canvas.restore();

    // Cadeado: elemento do mapa, marcando onde a corda desaparece atrás da
    // nuvem.
    final lock = Offset(size.width / 2, cloudTop + 0.5486 * cloudHeight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(lock.dx - 16, lock.dy - 2, 32, 26),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFFD9D1C1),
    );
    canvas.drawCircle(
      Offset(lock.dx, lock.dy + 10),
      4.5,
      Paint()..color = Colors.white,
    );
    final shackle = Path()
      ..moveTo(lock.dx - 10, lock.dy - 2)
      ..relativeLineTo(0, -9)
      ..relativeArcToPoint(
        const Offset(20, 0),
        radius: const Radius.circular(10),
        clockwise: true,
      )
      ..relativeLineTo(0, 9);
    canvas.drawPath(
      shackle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFD9D1C1),
    );
  }

  static Path _buildCloudPath(
    Offset start,
    List<(double, double, double, double)> arcs,
  ) {
    final path = Path()..moveTo(start.dx, start.dy);
    for (final (rx, ry, dx, dy) in arcs) {
      path.relativeArcToPoint(
        Offset(dx, dy),
        radius: Radius.elliptical(rx, ry),
        clockwise: false,
      );
    }
    return path..close();
  }

  // Camadas de nuvem.svg (path1-0 .. path4-1): cada tupla é (rx, ry, dx, dy)
  // de um comando de arco relativo 'a rx,ry 0 0 0 dx,dy'.
  static final Path _cloudLayer1 = _buildCloudPath(
    const Offset(-121.41864, 416.22631),
    const [
      (60.0, 60.0, 99.999997, 50.0),
      (100.0, 100.0, 170.000003, 50.0),
      (100.0, 100.0, 180.0, 20.0),
      (110.0, 110.0, 200.0, -20.0),
      (90.0, 90.0, 150.0, -50.0),
      (60.0, 60.0, 100.0, -50.0),
    ],
  );
  static final Path _cloudLayer2 = _buildCloudPath(
    const Offset(-71.418643, 416.22631),
    const [
      (50.0, 50.0, 80.0000001, 40.0),
      (90.0, 90.0, 160.0000029, 40.0),
      (110.0, 110.0, 200.0, 20.0),
      (100.0, 100.0, 180.0, -30.0),
      (80.0, 80.0, 140.0, -40.0),
      (40.0, 40.0, 60.0, -30.0),
    ],
  );
  static final Path _cloudLayer3 = _buildCloudPath(
    const Offset(-21.418643, 416.22631),
    const [
      (50.0, 50.0, 70.0, 30.0),
      (90.0, 90.0, 160.000003, 30.0),
      (120.0, 120.0, 220.0, 20.0),
      (100.0, 100.0, 180.0, -30.0),
      (60.0, 60.0, 100.0, -50.0),
    ],
  );
  static final Path _cloudLayer4 = _buildCloudPath(
    const Offset(78.581357, 416.22631),
    const [
      (60.0, 60.0, 90.000003, 40.0),
      (90.553851, 90.553851, 180.0, 20.0),
      (80.0, 80.0, 140.0, -30.0),
      (50.0, 50.0, 90.0, -30.0),
    ],
  );

  /// Paradas de vídeo na corda: hexágono do tamanho do círculo das fases —
  /// VERMELHO com ▶ enquanto pendente, VERDE com ✓ depois de assistida.
  void _paintCheckpoints(
      Canvas canvas, Size size, double visibleTop, double visibleBottom) {
    final cps = checkpointPositions(size, horizonLevels);
    for (var k = 1; k <= cps.length; k++) {
      final p = cps[k - 1];
      if (p.dy < visibleTop || p.dy > visibleBottom) continue;
      final cleared = checkpoints.contains(k);
      final reachable =
          unlockAll || completedStreak >= k * kCheckpointEvery;

      paintHexBadge(
        canvas,
        p,
        24,
        cleared: cleared,
        clearedColor: chainColors[2], // verde das cadeias
        pendingColor:
            chainColors[3].withValues(alpha: reachable ? 1.0 : 0.35),
      );
    }
  }

  /// Corda de cânhamo: fio com contorno + tranças diagonais curtas. O fio
  /// em si é um único `drawPath` (barato mesmo sendo comprido); só as
  /// tranças (uma linha a cada ~7,5px) são cortadas pela janela visível,
  /// já que são centenas ao longo do mapa inteiro.
  void _paintRope(
      Canvas canvas, Path path, double visibleTop, double visibleBottom) {
    const halfW = 5.5;

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = halfW * 2 + 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFA98A5F);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = halfW * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFD3B183);
    canvas.drawPath(path, outline);
    canvas.drawPath(path, base);

    final twist = Paint()
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFA98A5F).withValues(alpha: 0.85);
    for (final metric in path.computeMetrics()) {
      for (var d = 4.0; d + 4 < metric.length; d += 7.5) {
        final t = metric.getTangentForOffset(d);
        if (t == null) continue;
        if (t.position.dy < visibleTop || t.position.dy > visibleBottom) {
          continue;
        }
        final dir = t.vector;
        final n = Offset(-dir.dy, dir.dx);
        canvas.drawLine(
          t.position + n * (halfW - 1) - dir * 2.4,
          t.position - n * (halfW - 1) + dir * 2.4,
          twist,
        );
      }
    }
  }

  /// Fundo de ladrilhos hexagonais suaves com clareiras e árvores flat
  /// (longe da trilha para não competir com os nós). Só desenha as linhas
  /// de hexágonos dentro da janela visível — o mapa inteiro tem milhares
  /// de pixels de altura, então desenhar tudo sempre é o maior custo da
  /// tela de seleção de fases.
  void _paintHexBackground(Canvas canvas, Size size, List<Offset> nodes,
      double visibleTop, double visibleBottom) {
    const s = 34.0;
    const rowHeight = s * 1.5;
    final w = s * math.sqrt(3);
    final plain = Paint()..color = const Color(0xFFF3EEE1);
    final grass = Paint()..color = const Color(0xFFEAEDD8);
    var row = (visibleTop / rowHeight).floor().clamp(0, 1 << 30);
    final maxCy = math.min(size.height + s, visibleBottom);
    for (var cy = row * rowHeight; cy < maxCy; cy += rowHeight, row++) {
      final xOff = row.isOdd ? w / 2 : 0.0;
      var col = 0;
      for (var cx = -w; cx < size.width + w; cx += w, col++) {
        final center = Offset(cx + xOff, cy);
        // Variedade determinística (sem RNG: pintura estável entre frames).
        final h = (row * 37 + col * 19) % 100;
        final isGrass = h >= 52;
        canvas.drawPath(_hexPath(center, s - 2.5), isGrass ? grass : plain);
        if (h >= 84) {
          final nearNode =
              nodes.any((n) => (n - center).distanceSquared < 72 * 72);
          if (!nearNode) _paintTrees(canvas, center, h);
        }
      }
    }
  }

  /// Árvores flat: copa redonda + tronco, 1 ou 2 por hexágono.
  void _paintTrees(Canvas canvas, Offset c, int h) {
    final canopy =
        h.isEven ? const Color(0xFFABC698) : const Color(0xFF9BBA87);
    final trunk = Paint()..color = const Color(0xFFC4A183);

    void treeAt(Offset t, double k) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: t + Offset(0, 9 * k), width: 4.5 * k, height: 10 * k),
          const Radius.circular(2),
        ),
        trunk,
      );
      canvas.drawCircle(
          t + Offset(0, -2 * k), 9.5 * k, Paint()..color = canopy);
      canvas.drawCircle(
        t + Offset(-2.5 * k, -4.5 * k),
        3.2 * k,
        Paint()..color = Colors.white.withValues(alpha: 0.22),
      );
    }

    if (h % 3 == 0) {
      treeAt(c + const Offset(-8, 3), 0.75);
      treeAt(c + const Offset(7, -4), 1.0);
    } else {
      treeAt(c, 1.0);
    }
  }

  Path _hexPath(Offset c, double s) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + i * math.pi / 3;
      final v = c + Offset(math.cos(a), math.sin(a)) * s;
      i == 0 ? path.moveTo(v.dx, v.dy) : path.lineTo(v.dx, v.dy);
    }
    return path..close();
  }

  /// Três slots de estrela em leque acima do nó; [earned] preenchidas.
  void _paintStars(Canvas canvas, Offset node, int earned, double nodeRadius) {
    const slots = [
      (-15.0, -6.0, 6.5, -0.35),
      (0.0, -11.0, 8.0, 0.0),
      (15.0, -6.0, 6.5, 0.35),
    ];
    for (var i = 0; i < 3; i++) {
      final (dx, dy, r, tilt) = slots[i];
      final center = node + Offset(dx, dy - nodeRadius);
      final filled = i < earned;
      final path = _starPath(center, r, tilt);
      canvas.drawPath(
        path,
        Paint()..color = filled ? accentGold : const Color(0xFFEDE7DA),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeJoin = StrokeJoin.round
          ..color =
              filled ? const Color(0xFFC79A0A) : const Color(0xFFDBD2C0),
      );
    }
  }

  /// Estrela de 5 pontas centrada em [c] com raio externo [r].
  Path _starPath(Offset c, double r, double tilt) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.46;
      final angle = -math.pi / 2 + tilt + i * math.pi / 5;
      final p = c + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(LevelMapPainter old) =>
      old.completedStreak != completedStreak ||
      old.horizonLevels != horizonLevels ||
      old.unlockAll != unlockAll ||
      !setEquals(old.checkpoints, checkpoints) ||
      !mapEquals(old.stars, stars);
}

/// Parada de vídeo obrigatória — sem tela de aviso: abre já disparando o
/// vídeo (real, via [AdsService]; ou, se indisponível, uma contagem
/// simulada), igual ao ARCO. Retorna true se o vídeo foi assistido até o
/// fim. Mantém a semântica de recompensa do Arc Chain (libera as fases
/// seguintes) — nenhum power-up é concedido.
Future<bool?> showCheckpointDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _CheckpointDialog(),
  );
}

class _CheckpointDialog extends StatefulWidget {
  const _CheckpointDialog();

  @override
  State<_CheckpointDialog> createState() => _CheckpointDialogState();
}

class _CheckpointDialogState extends State<_CheckpointDialog> {
  bool watching = false;
  int remaining = kSimulatedAdSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    // Rewarded real; null = indisponível → simulação de contagem.
    final result = await AdsService.instance.showRewarded();
    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pop(result);
      return;
    }
    setState(() => watching = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => remaining--);
      if (remaining <= 0) {
        t.cancel();
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFAFAF8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: watching
            ? Container(
                width: 120,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1228),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$remaining',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB5EAD7),
                    ),
                  ),
                ),
              )
            : const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: inkMuted,
                ),
              ),
      ),
    );
  }
}
