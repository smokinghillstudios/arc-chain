import 'package:flutter_test/flutter_test.dart';

import 'package:arc_chain/core/trophies.dart';
import 'package:arc_chain/ui/screens/daily_visit_screen.dart';

TrophyProgress _progress({
  int totalStars = 0,
  int perfectLevels = 0,
  int completedStreak = 0,
  int checkpointsCleared = 0,
  int rainbowClears = 0,
  int infiniteProgress = 0,
  int flawlessFirstClears = 0,
  int comebackWins = 0,
  int consecutiveDays = 0,
  int totalDaysPlayed = 0,
}) =>
    (
      totalStars: totalStars,
      perfectLevels: perfectLevels,
      completedStreak: completedStreak,
      checkpointsCleared: checkpointsCleared,
      rainbowClears: rainbowClears,
      infiniteProgress: infiniteProgress,
      flawlessFirstClears: flawlessFirstClears,
      comebackWins: comebackWins,
      consecutiveDays: consecutiveDays,
      totalDaysPlayed: totalDaysPlayed,
    );

void main() {
  test('checkNewTrophies só devolve marcos recém-cruzados', () {
    final newIds =
        checkNewTrophies(_progress(totalStars: 35), <String>{});
    expect(newIds, containsAll(['stars_10', 'stars_30']));
    expect(newIds, isNot(contains('stars_75')));

    // Já desbloqueado antes não volta a aparecer, mesmo cruzando de novo.
    final again =
        checkNewTrophies(_progress(totalStars: 35), {'stars_10', 'stars_30'});
    expect(again, isEmpty);
  });

  test('valueForCategory lê o contador certo por categoria', () {
    final p = _progress(rainbowClears: 3, infiniteProgress: 12);
    expect(valueForCategory(TrophyCategory.rainbow, p), 3);
    expect(valueForCategory(TrophyCategory.infinite, p), 12);
  });

  test('computeConsecutiveDays: dia seguinte incrementa', () {
    final today = DateTime(2026, 3, 10);
    final result = computeConsecutiveDays(
      today: today,
      lastVisit: '2026-03-09',
      previousConsecutiveDays: 4,
    );
    expect(result, 5);
  });

  test('computeConsecutiveDays: pular um dia reinicia em 1', () {
    final today = DateTime(2026, 3, 10);
    final result = computeConsecutiveDays(
      today: today,
      lastVisit: '2026-03-07',
      previousConsecutiveDays: 6,
    );
    expect(result, 1);
  });

  test('computeConsecutiveDays: mesmo dia não muda nada', () {
    final today = DateTime(2026, 3, 10);
    final result = computeConsecutiveDays(
      today: today,
      lastVisit: '2026-03-10',
      previousConsecutiveDays: 4,
    );
    expect(result, 4);
  });

  test('computeConsecutiveDays: 1ª visita começa em 1', () {
    final result = computeConsecutiveDays(
      today: DateTime(2026, 3, 10),
      lastVisit: null,
      previousConsecutiveDays: 0,
    );
    expect(result, 1);
  });

  test('displayDayFor cicla em blocos de kStreakRowLength', () {
    expect(displayDayFor(1), 1);
    expect(displayDayFor(5), 5);
    expect(displayDayFor(6), 1);
    expect(displayDayFor(11), 1);
  });
}
