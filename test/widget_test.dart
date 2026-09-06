import 'package:flutter_test/flutter_test.dart';

import 'package:arc_chain/core/engine.dart';

void main() {
  test('todas as fases geram tabuleiro válido e determinístico', () {
    for (final level in levels) {
      final a = GameBoard.generate(level);
      final b = GameBoard.generate(level);
      expect(a.rows, level.rows);
      expect(a.cols, level.cols);
      expect(a.chains.length, level.chains);
      expect(a.minTaps, greaterThan(0));
      expect(a.maxTaps, greaterThan(a.minTaps));
      // mesma seed => mesmo tabuleiro
      expect(a.grid, b.grid);
      expect(a.chains.map((c) => c.startDir).toList(),
          b.chains.map((c) => c.startDir).toList());
    }
  });

  test('exits dos arcos batem com a tabela de pares', () {
    expect(getExit('A', 3), 0);
    expect(getExit('A', 0), 3);
    expect(getExit('A', 2), 1);
    expect(getExit('B', 0), 1);
    expect(getExit('B', 3), 2);
    expect(getExit('D', 3), 1);
    expect(getExit('D', 0), 2);
  });
}
