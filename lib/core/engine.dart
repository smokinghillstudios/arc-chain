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
const int _kCheckpointEvery = 5;
const Set<int> _reliefGroups = {4, 9, 14};

/// Gera as 100 fases por fórmula (duas ondas sobrepostas: altura cresce
/// rápido com respiros periódicos, largura cresce devagar e sempre menor
/// que a altura, cadeias oscilam a cada grupo de 5 fases) em vez de listar
/// cada uma à mão. Ver o plano de implementação para o raciocínio completo.
List<LevelDef> _buildLevels() {
  const totalLevels = 100;
  return [
    for (var id = 1; id <= totalLevels; id++) _levelFor(id),
  ];
}

/// Teto de tabuleiro: 8 colunas × 12 linhas — acima disso fica ruim de
/// jogar (células pequenas demais / difícil de tocar com precisão).
const int _maxCols = 8;
const int _maxRows = 12;

/// Teto de toques máximos aceitável numa fase — `GameBoard.generate`
/// tenta várias vezes até achar um tabuleiro dentro desse limite.
const int kMaxAcceptableTaps = 50;

LevelDef _levelFor(int id) {
  final g = (id - 1) ~/ _kCheckpointEvery;
  final p = (id - 1) % _kCheckpointEvery;
  final relief = _reliefGroups.contains(g);

  final rowTier = (g ~/ 3).clamp(0, _maxRows - 6);
  final rows = 6 + rowTier - (relief ? 1 : 0);

  final colTier = (g ~/ 6).clamp(0, _maxCols - 6);
  final cols = 6 + colTier;

  final chainsTier = (g ~/ 4).clamp(0, 4);
  final chainsBase = 1 + chainsTier - (relief ? 1 : 0);
  const extraByPosition = [0, 0, 1, 0, 1];
  final chains = (chainsBase + extraByPosition[p]).clamp(1, 5);

  return LevelDef(id, rows, cols, chains, 10000 + id);
}

final List<LevelDef> levels = _buildLevels();

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

  /// Percorre a cadeia de forma síncrona para verificar se ela já
  /// conecta sem nenhum toque (rota alternativa "de graça").
  static bool _simulateImmediateWin(Chain ch, List<Chain> allChains,
      List<List<String>> grid, int rows, int cols) {
    final d0 = exitToDelta[ch.startDir]!;
    var cur = Pos(
        (ch.start.r + d0[0] + rows) % rows, (ch.start.c + d0[1] + cols) % cols);
    var entry = opposite(ch.startDir);
    final seen = <String>{};
    final maxSteps = rows * cols * 4;

    for (var steps = 0; steps < maxSteps; steps++) {
      if (cur.r == ch.end.r && cur.c == ch.end.c) return true;
      if (allChains.any((c) => c.end.r == cur.r && c.end.c == cur.c)) return false;
      if (allChains.any((c) => c.start.r == cur.r && c.start.c == cur.c)) {
        return false;
      }

      final stateKey = '${cur.key},$entry';
      if (seen.contains(stateKey)) return false;
      seen.add(stateKey);

      final type = grid[cur.r][cur.c];
      final exit = getExit(type, entry)!;
      final d = exitToDelta[exit]!;
      cur = Pos((cur.r + d[0] + rows) % rows, (cur.c + d[1] + cols) % cols);
      entry = opposite(exit);
    }
    return false;
  }

  static GameBoard generate(LevelDef level) {
    final rows = level.rows;
    final cols = level.cols;
    final numChains = level.chains;
    _rand = Mulberry32(level.seed); // mesma fase = sempre o mesmo tabuleiro

    int rowFor(int i) => ((i + 0.5) * rows / numChains).floor();
    final farColumn = cols ~/ 2;
    final reservedStarts = <Pos>[];
    final reservedEnds = <Pos>[];
    for (var i = 0; i < numChains; i++) {
      reservedStarts.add(Pos(rowFor(i), 0));
      reservedEnds.add(Pos(rowFor(numChains - 1 - i), farColumn));
    }

    var minTaps = 0;
    var genAttempt = 0;
    // Mais tentativas que antes: além de evitar vitória de graça, agora
    // também persegue o teto de toques (kMaxAcceptableTaps) abaixo.
    const maxGenAttempts = 300;
    late List<List<String>> grid;
    late List<Chain> chains;

    List<List<String>>? bestGrid;
    List<Chain>? bestChains;
    var bestMinTaps = 0;
    var bestMaxTaps = 1 << 30;

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

      // 3. verificação real: pode existir uma rota alternativa que
      //    conecta de graça
      final anyImmediateWin = chains.any(
          (ch) => _simulateImmediateWin(ch, chains, grid, rows, cols));
      final maxTapsAttempt =
          minTaps + [3, (minTaps * 0.5).ceil()].reduce((a, b) => a > b ? a : b);

      // Guarda a melhor tentativa válida (sem vitória de graça) até agora,
      // caso nenhuma dentro do orçamento de tentativas fique abaixo do teto.
      if (!anyImmediateWin && maxTapsAttempt < bestMaxTaps) {
        bestGrid = grid;
        bestChains = chains;
        bestMinTaps = minTaps;
        bestMaxTaps = maxTapsAttempt;
      }

      if (!anyImmediateWin && maxTapsAttempt <= kMaxAcceptableTaps) break;
      if (genAttempt >= maxGenAttempts) {
        // Não achou nenhuma dentro do teto: fica com a melhor encontrada,
        // em vez de aceitar a última tentativa (que pode ter sido pior).
        if (bestGrid != null) {
          grid = bestGrid;
          chains = bestChains!;
          minTaps = bestMinTaps;
        }
        break;
      }
    }

    final maxTaps = minTaps + [3, (minTaps * 0.5).ceil()].reduce((a, b) => a > b ? a : b);
    return GameBoard._(rows, cols, grid, chains, minTaps, maxTaps);
  }
}
