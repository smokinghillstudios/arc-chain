import 'package:flutter_test/flutter_test.dart';

import 'package:arc_chain/core/engine.dart';

void main() {
  test('todas as fases geram tabuleiro válido e determinístico', () {
    // Rampa original (1–100) inteira, mais uma amostra do modo infinito
    // (101 em diante) cobrindo cada patamar do ciclo de 8 grupos.
    final sampleIds = [
      for (var id = 1; id <= 100; id++) id,
      101, 106, 111, 116, 121, 126, 131, 136, // um ciclo completo (40 fases)
      141, 180, 500, // vários ciclos adiante, deve repetir certinho
    ];
    for (final id in sampleIds) {
      final level = levelForId(id);
      final a = GameBoard.generate(level);
      final b = GameBoard.generate(level);
      expect(a.rows, level.rows);
      expect(a.cols, level.cols);
      expect(a.chains.length, level.chains);
      expect(a.minTaps, greaterThanOrEqualTo(minTapsFloor(id, level.chains)));
      expect(a.maxTaps, lessThanOrEqualTo(kMaxAcceptableTaps));
      expect(a.maxTaps, greaterThan(a.minTaps));
      // mesma seed => mesmo tabuleiro
      expect(a.grid, b.grid);
      expect(a.chains.map((c) => c.startDir).toList(),
          b.chains.map((c) => c.startDir).toList());
    }

    // O ciclo do modo infinito se repete a cada 40 fases (8 grupos × 5).
    expect(levelForId(101).rows, levelForId(141).rows);
    expect(levelForId(101).cols, levelForId(141).cols);
    expect(levelForId(106).rows, levelForId(146).rows);
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
