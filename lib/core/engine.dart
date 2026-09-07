import 'dart:collection';
import 'dart:ui' show Color;

/// PRNG mulberry32 — porte fiel do protótipo JS, para que cada fase
/// gere sempre o mesmo tabuleiro a partir da mesma seed.
class Mulberry32 {
  int _s;
  Mulberry32(int seed) : _s = seed & 0xFFFFFFFF;

  static int _imul(int a, int b) => (a * b) & 0xFFFFFFFF;

  double nextDouble() {
    _s = (_s + 0x6D2B79F5) & 0xFFFFFFFF;
    int t = _s;
    t = _imul(t ^ (t >> 15), t | 1);
    t = (((t + _imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF) ^ t) & 0xFFFFFFFF;
    t = t ^ (t >> 14);
    return t / 4294967296;
  }
}

// Bordas: 0=TOP, 1=RIGHT, 2=BOTTOM, 3=LEFT
const Map<String, List<List<int>>> arcPairs = {
  'A': [
    [3, 0],
    [2, 1]
  ],
  'B': [
    [0, 1],
    [3, 2]
  ],
  'D': [
    [3, 1],
    [0, 2]
  ],
};

int? getExit(String arcType, int entryEdge) {
  final pairs = arcPairs[arcType]!;
  final matches =
      pairs.where((p) => p[0] == entryEdge || p[1] == entryEdge).toList();
  if (matches.isEmpty) return null;
  for (final p in matches) {
    final exit = p[0] == entryEdge ? p[1] : p[0];
    if (exit != entryEdge) return exit;
  }
  return null;
}

int pairIndex(String arcType, int entry, int exit) {
  final pairs = arcPairs[arcType]!;
  for (var i = 0; i < pairs.length; i++) {
    final a = pairs[i][0], b = pairs[i][1];
    if ((a == entry && b == exit) || (a == exit && b == entry)) return i;
  }
  return -1;
}

int opposite(int edge) => (edge + 2) % 4;

const Map<int, List<int>> exitToDelta = {
  0: [-1, 0],
  1: [0, 1],
  2: [1, 0],
  3: [0, -1],
};

const List<Color> chainColors = [
  Color(0xFFF1C40F),
  Color(0xFF78B9F2),
  Color(0xFF81C995),
  Color(0xFFF28B82),
  Color(0xFFC6A7F5),
];

/// Definição de uma fase: tabuleiro retangular (mais alto que largo nas
/// fases avançadas, para aproveitar a tela vertical do celular).
class LevelDef {
  final int id;
  final int rows;
  final int cols;
  final int chains;
  final int seed;
  const LevelDef(this.id, this.rows, this.cols, this.chains, this.seed);
}

/// A cada [_kCheckpointEvery] fases (mesmo agrupamento das paradas de vídeo
/// do mapa) a dificuldade dá um respiro: um passo pra trás antes de
/// continuar subindo — a "onda" que sobe e desce em vez de só crescer.
/// Só vale para a rampa inicial (fases 1–100); depois disso o modo
/// infinito (ver [_endlessChains] etc.) já tem sua própria onda.
const int _kCheckpointEvery = 5;
const Set<int> _reliefGroups = {4, 9, 14};

/// Última fase da rampa inicial — a partir daqui entra o modo infinito
/// (ciclo, ver [_endlessChains]/[_endlessRows]/[_endlessCols]).
const int _kRampEnd = 100;

/// Teto de tabuleiro: 7 colunas × 10 linhas — acima disso fica ruim de
/// jogar (células pequenas demais / difícil de tocar com precisão).
const int _maxCols = 7;
const int _maxRows = 10;

/// Teto de toques máximos aceitável numa fase — `GameBoard.generate`
/// tenta várias vezes até achar um tabuleiro dentro desse limite.
const int kMaxAcceptableTaps = 50;

/// Modo infinito (fases além de [_kRampEnd]): em vez de continuar travado
/// no teto pra sempre, cadeias e altura do tabuleiro oscilam juntas num
/// ciclo de 8 grupos de 5 fases (40 fases por volta completa) — índice =
/// fase do ciclo (`eg % 8`). A fase 0 do ciclo bate com o teto da rampa
/// (7×10, 5 cadeias), então a virada 100→101 é suave, sem degrau. A
/// largura já fica no teto (7) o tempo todo — só a altura oscila.
const List<int> _endlessChains = [5, 4, 4, 3, 3, 4, 4, 5];
const List<int> _endlessRows = [10, 9, 9, 8, 8, 9, 9, 10];
const List<int> _endlessCols = [7, 7, 7, 7, 7, 7, 7, 7];

/// Definição de uma fase, calculada sob demanda a partir do `id` — sem
/// lista nem teto: fases 1–100 seguem a rampa original de sempre; a partir
/// da 101 entra o ciclo do modo infinito (ver [_endlessChains] etc.). Como
/// é puramente uma função de `id` (a seed é `10000 + id`), o mesmo `id`
/// sempre gera exatamente o mesmo tabuleiro em qualquer aparelho.
LevelDef levelForId(int id) {
  final g = (id - 1) ~/ _kCheckpointEvery;
  final p = (id - 1) % _kCheckpointEvery;
  const extraByPosition = [0, 0, 1, 0, 1];

  int rows, cols, chainsBase;
  if (id <= _kRampEnd) {
    final relief = _reliefGroups.contains(g);
    final rowTier = (g ~/ 3).clamp(0, _maxRows - 6);
    rows = 6 + rowTier - (relief ? 1 : 0);
    final colTier = (g ~/ 6).clamp(0, _maxCols - 6);
    cols = 6 + colTier;
    final chainsTier = (g ~/ 4).clamp(0, 4);
    chainsBase = 1 + chainsTier - (relief ? 1 : 0);
  } else {
    final eg = (id - _kRampEnd - 1) ~/ _kCheckpointEvery;
    final cyclePhase = eg % _endlessChains.length;
    rows = _endlessRows[cyclePhase];
    cols = _endlessCols[cyclePhase];
    chainsBase = _endlessChains[cyclePhase];
  }

  final chains = (chainsBase + extraByPosition[p]).clamp(1, 5);
  return LevelDef(id, rows, cols, chains, 10000 + id);
}

/// Piso mínimo de `minTaps` (já sobre o custo real, ver
/// `GameBoard._realMinTapsForChain`) por faixa de fase — garante que a
/// fase nunca fique fácil demais mesmo quando a seed sorteia um caminho
/// curto. Fases com poucas cadeias num tabuleiro pequeno têm um teto real
/// mais baixo (o tabuleiro é toroidal — sempre existe um atalho curto
/// quando há pouca coisa disputando espaço) — pedir mais que isso faria
/// `GameBoard.generate` esgotar as 300 tentativas sempre à toa, então o
/// piso respeita esse teto por quantidade de cadeias.
int minTapsFloor(int id, int chains) {
  if (id <= 3) return 1;
  final base = id <= 20 ? 3 : 5;
  final chainCap = switch (chains) {
    1 => 2,
    2 => 4,
    _ => base,
  };
  return base < chainCap ? base : chainCap;
}

/// (posição de linha, lado) de onde cada cadeia começa, por quantidade de
/// cadeias — posição de linha: um "slot" de 0 (topo) a 4 (base), lado:
/// 0=esquerda, 1=direita. Duas cadeias em lados opostos (colunas opostas)
/// nunca dividem o mesmo slot — se dividissem, cairiam na mesma linha do
/// tabuleiro (ver `startRow` em `GameBoard.generate`), o que confunde
/// visualmente qual início pertence a qual cadeia.
const List<List<(int, int)>> _startLayouts = [
  [],
  [(2, 0)], // 1: esquerda centro
  [(1, 0), (3, 1)], // 2: esquerda meio-alto, direita meio-baixo
  [(0, 0), (2, 1), (4, 0)], // 3: esquerda topo, direita centro, esquerda base
  [(0, 0), (1, 1), (3, 0), (4, 1)], // 4: os 4 cantos, lado oposto sempre 1 slot adiante
  [(0, 0), (1, 1), (2, 0), (3, 0), (4, 1)], // 5: topo×2, esquerda-centro, base×2
];

class Pos {
  final int r, c;
  const Pos(this.r, this.c);
  String get key => '$r,$c';

  @override
  bool operator ==(Object other) => other is Pos && other.r == r && other.c == c;
  @override
  int get hashCode => r * 997 + c;
}

class Chain {
  final Pos start;
  final Pos end;
  final Color color;
  final List<Pos> path;
  bool success = false;
  int startDir;
  Chain(
      {required this.start,
      required this.end,
      required this.color,
      required this.path,
      required this.startDir});
}

/// Tabuleiro gerado para uma fase: grade de tipos de arco + cadeias.
class GameBoard {
  final int rows;
  final int cols;
  final List<List<String>> grid;
  final List<Chain> chains;
  final int minTaps;
  final int maxTaps;
  final List<List<String>> originalGrid;
  final List<int> originalStartDirs;

  GameBoard._(
      this.rows, this.cols, this.grid, this.chains, this.minTaps, this.maxTaps)
      : originalGrid = grid.map((r) => List<String>.from(r)).toList(),
        originalStartDirs = chains.map((c) => c.startDir).toList();

  void reset() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        grid[r][c] = originalGrid[r][c];
      }
    }
    for (var i = 0; i < chains.length; i++) {
      chains[i].startDir = originalStartDirs[i];
      chains[i].success = false;
    }
  }

  static late Mulberry32 _rand;

  static String _randomBaseType() {
    final r = _rand.nextDouble();
    if (r < 0.10) return 'D';
    return _rand.nextDouble() < 0.5 ? 'A' : 'B';
  }

  static List<T> _shuffle<T>(List<T> arr) {
    for (var i = arr.length - 1; i > 0; i--) {
      final j = (_rand.nextDouble() * (i + 1)).floor();
      final tmp = arr[i];
      arr[i] = arr[j];
      arr[j] = tmp;
    }
    return arr;
  }

  /// Busca um caminho auto-evitante num grid toroidal (linhas e colunas
  /// podem ter tamanhos diferentes) do início ao fim, evitando células já
  /// usadas por outras cadeias (blocked).
  static List<Pos> _generatePath(
      Pos start, Pos end, int rows, int cols, Set<String> blocked) {
    final visited = Set<String>.from(blocked);
    final path = <Pos>[];
    var calls = 0;

    bool dfs(Pos cur) {
      calls++;
      if (calls > 20000) return false;
      path.add(cur);
      visited.add(cur.key);
      if (cur.r == end.r && cur.c == end.c) return true;

      final moves = _shuffle([
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1]
      ]);
      for (final m in moves) {
        final next =
            Pos((cur.r + m[0] + rows) % rows, (cur.c + m[1] + cols) % cols);
        if (!visited.contains(next.key)) {
          if (dfs(next)) return true;
        }
      }
      path.removeLast();
      visited.remove(cur.key);
      return false;
    }

    dfs(start);
    return path;
  }

  static int _exitEdgeFrom(Pos a, Pos b, int rows, int cols) {
    final dr = ((b.r - a.r) + rows) % rows;
    final dc = ((b.c - a.c) + cols) % cols;
    if (dr == rows - 1) return 0;
    if (dr == 1) return 2;
    if (dc == 1) return 1;
    if (dc == cols - 1) return 3;
    return -1;
  }

  /// Custo real mínimo de toques pra levar [ch] do início até o próprio
  /// fim, dado o grid já gerado — 0-1 BFS sobre estados (célula, borda de
  /// entrada), mais 4 estados extras pro giro da seta de início (cada
  /// toque nela avança 1 borda — `startDir = (startDir + 1) % 4`, igual
  /// em `GameScreen._onCellTap` — então o custo pra alcançar uma direção é
  /// a distância cíclica). Existe pra detectar quando uma rota
  /// alternativa (não a intencional) resolve mais barato que o
  /// `chainMinTaps` calculado durante a geração — sem isso, a fase podia
  /// anunciar um número de toques maior do que o realmente necessário.
  static int _realMinTapsForChain(
      Chain ch, List<Chain> allChains, List<List<String>> grid, int rows, int cols) {
    final stateCount = 4 + rows * cols * 4;
    int gridId(int r, int c, int entry) => 4 + ((r * cols) + c) * 4 + entry;
    final dist = List<int>.filled(stateCount, 1 << 30);
    final done = List<bool>.filled(stateCount, false);
    final dq = Queue<int>();

    void relax(int id, int newDist, bool zeroCost) {
      if (!done[id] && newDist < dist[id]) {
        dist[id] = newDist;
        if (zeroCost) {
          dq.addFirst(id);
        } else {
          dq.addLast(id);
        }
      }
    }

    dist[ch.startDir] = 0;
    dq.addFirst(ch.startDir);

    var best = 1 << 30;
    while (dq.isNotEmpty) {
      final id = dq.removeFirst();
      if (done[id]) continue; // já processado com a distância final — pula
      done[id] = true;
      final d = dist[id];

      if (id < 4) {
        // Nó de direção da seta de início: girar (+1, custo 1) ou entrar
        // no tabuleiro nessa direção (custo 0).
        final dir = id;
        relax((dir + 1) % 4, d + 1, false);
        final d0 = exitToDelta[dir]!;
        final r0 = (ch.start.r + d0[0] + rows) % rows;
        final c0 = (ch.start.c + d0[1] + cols) % cols;
        relax(gridId(r0, c0, opposite(dir)), d, true);
        continue;
      }

      final rest = id - 4;
      final entry = rest % 4;
      final c = (rest ~/ 4) % cols;
      final r = rest ~/ (4 * cols);

      if (r == ch.end.r && c == ch.end.c) {
        if (d < best) best = d;
        continue;
      }
      if (allChains.any((o) => o.end.r == r && o.end.c == c)) continue;
      if (allChains.any((o) => o.start.r == r && o.start.c == c)) continue;

      final type = grid[r][c];
      if (type == 'D') {
        final exit = getExit('D', entry)!;
        final dl = exitToDelta[exit]!;
        final nr = (r + dl[0] + rows) % rows;
        final nc = (c + dl[1] + cols) % cols;
        relax(gridId(nr, nc, opposite(exit)), d, true);
      } else {
        for (final candidate in const ['A', 'B']) {
          final exit = getExit(candidate, entry)!;
          final matches = type == candidate;
          final dl = exitToDelta[exit]!;
          final nr = (r + dl[0] + rows) % rows;
          final nc = (c + dl[1] + cols) % cols;
          relax(gridId(nr, nc, opposite(exit)), matches ? d : d + 1, matches);
        }
      }
    }

    return best;
  }

  static GameBoard generate(LevelDef level) {
    final rows = level.rows;
    final cols = level.cols;
    final numChains = level.chains;
    _rand = Mulberry32(level.seed); // mesma fase = sempre o mesmo tabuleiro

    int rowFor(int i) => ((i + 0.5) * rows / numChains).floor();
    final farColumn = cols ~/ 2;
    final startLayout = _startLayouts[numChains];
    final reservedStarts = <Pos>[];
    final reservedEnds = <Pos>[];
    for (var i = 0; i < numChains; i++) {
      final (slot, colSide) = startLayout[i];
      final startRow = (slot * (rows - 1) / 4).round();
      final startCol = colSide == 0 ? 0 : cols - 1;
      reservedStarts.add(Pos(startRow, startCol));
      reservedEnds.add(Pos(rowFor(numChains - 1 - i), farColumn));
    }

    var minTaps = 0;
    var genAttempt = 0;
    // Mais tentativas que antes: além de evitar vitória de graça, agora
    // também persegue o piso e o teto de toques abaixo.
    const maxGenAttempts = 300;
    final minTapsFloorForLevel = minTapsFloor(level.id, numChains);
    late List<List<String>> grid;
    late List<Chain> chains;

    List<List<String>>? bestGrid;
    List<Chain>? bestChains;
    var bestMinTaps = 0;
    var bestViolation = 1 << 30;

    while (true) {
      genAttempt++;

      // 1. preenchimento base aleatório
      grid = [
        for (var r = 0; r < rows; r++)
          [for (var c = 0; c < cols; c++) _randomBaseType()]
      ];

      // 2. gera o caminho de cada cadeia
      final globalBlocked = <String>{};
      chains = [];
      minTaps = 0;

      for (var i = 0; i < numChains; i++) {
        final start = reservedStarts[i];
        final end = reservedEnds[i];

        final blocked = Set<String>.from(globalBlocked);
        for (var j = 0; j < numChains; j++) {
          if (j == i) continue;
          blocked.add(reservedStarts[j].key);
          blocked.add(reservedEnds[j].key);
        }

        var path = _generatePath(start, end, rows, cols, blocked);
        var attempts = 0;
        while (path.isEmpty && attempts < 20) {
          path = _generatePath(start, end, rows, cols, blocked);
          attempts++;
        }
        if (path.isEmpty) {
          path = _generatePath(start, end, rows, cols, <String>{});
        }

        for (final p in path) {
          globalBlocked.add(p.key);
        }

        final requiredStartDir = path.length > 1
            ? _exitEdgeFrom(path[0], path[1], rows, cols)
            : 1;
        var initialStartDir = (_rand.nextDouble() * 4).floor();
        var chainMinTaps = (requiredStartDir - initialStartDir + 4) % 4;

        final turnCells = <({int r, int c, String required})>[];
        for (var k = 1; k < path.length - 1; k++) {
          final cell = path[k];
          final entry =
              opposite(_exitEdgeFrom(path[k - 1], cell, rows, cols));
          final exit = _exitEdgeFrom(cell, path[k + 1], rows, cols);
          final isStraight = opposite(entry) == exit;
          if (isStraight) {
            grid[cell.r][cell.c] = 'D';
          } else {
            final required = pairIndex('A', entry, exit) >= 0 ? 'A' : 'B';
            if (grid[cell.r][cell.c] != 'A' && grid[cell.r][cell.c] != 'B') {
              grid[cell.r][cell.c] = _rand.nextDouble() < 0.5 ? 'A' : 'B';
            }
            if (grid[cell.r][cell.c] != required) chainMinTaps++;
            turnCells.add((r: cell.r, c: cell.c, required: required));
          }
        }

        // garante que nenhuma cadeia já nasça conectada pelo caminho
        // pretendido — força pelo menos 1 toque
        if (chainMinTaps == 0) {
          if (turnCells.isNotEmpty) {
            final t = turnCells[(_rand.nextDouble() * turnCells.length).floor()];
            grid[t.r][t.c] = t.required == 'A' ? 'B' : 'A';
          } else {
            initialStartDir =
                (requiredStartDir + 1 + (_rand.nextDouble() * 3).floor()) % 4;
          }
          chainMinTaps = 1;
        }
        minTaps += chainMinTaps;

        chains.add(Chain(
            start: start,
            end: end,
            color: chainColors[i % chainColors.length],
            path: path,
            startDir: initialStartDir));
      }

      // 3. custo real: pode existir uma rota alternativa (não a
      //    intencional) que resolve alguma cadeia mais barato do que o
      //    `chainMinTaps` heurístico calculado acima — o tabuleiro é
      //    toroidal (as bordas se conectam) e as células de preenchimento
      //    são sorteadas soltas, então atalhos acontecem. Em vez de tentar
      //    evitar todo atalho (impraticável nos tabuleiros maiores — quase
      //    sempre existe algum), o piso/teto e o número mostrado ao
      //    jogador passam a valer sobre esse custo real, não o da rota
      //    pretendida — assim a fase nunca anuncia mais toques do que o
      //    realmente necessário.
      final realPerChain = [
        for (final ch in chains) _realMinTapsForChain(ch, chains, grid, rows, cols)
      ];
      final realMinTaps = realPerChain.fold(0, (a, b) => a + b);
      // Uma cadeia já nascer resolvida (custo real 0) é o único caso
      // sempre rejeitado — sensação de vitória de graça antes de tocar.
      final anyChainAlreadySolved = realPerChain.any((v) => v == 0);

      final maxTapsAttempt = realMinTaps +
          [3, (realMinTaps * 0.5).ceil()].reduce((a, b) => a > b ? a : b);

      // Quanto essa tentativa fica fora da faixa aceitável (piso de
      // minTaps por baixo, teto de maxTaps por cima) — 0 = dentro dos dois.
      final violation = (minTapsFloorForLevel - realMinTaps).clamp(0, 1 << 30) +
          (maxTapsAttempt - kMaxAcceptableTaps).clamp(0, 1 << 30);

      // Guarda a melhor tentativa válida até agora, caso nenhuma dentro do
      // orçamento de tentativas fique dentro da faixa.
      if (!anyChainAlreadySolved && violation < bestViolation) {
        bestGrid = grid;
        bestChains = chains;
        bestMinTaps = realMinTaps;
        bestViolation = violation;
      }

      if (!anyChainAlreadySolved && violation == 0) {
        minTaps = realMinTaps;
        break;
      }
      if (genAttempt >= maxGenAttempts) {
        // Não achou nenhuma dentro da faixa: fica com a melhor encontrada,
        // em vez de aceitar a última tentativa (que pode ter sido pior).
        if (bestGrid != null) {
          grid = bestGrid;
          chains = bestChains!;
          minTaps = bestMinTaps;
        } else {
          minTaps = realMinTaps;
        }
        break;
      }
    }

    final maxTaps = minTaps + [3, (minTaps * 0.5).ceil()].reduce((a, b) => a > b ? a : b);
    return GameBoard._(rows, cols, grid, chains, minTaps, maxTaps);
  }
}
