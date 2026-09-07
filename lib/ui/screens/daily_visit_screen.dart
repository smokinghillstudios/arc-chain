import 'package:flutter/material.dart';

import '../../controller/progress.dart';
import '../../controller/trophy_service.dart';
import '../overlays/trophy_dialog.dart';
import '../theme.dart';
import 'level_map_screen.dart';

/// Quantos dias cabem numa fileira do calendário de streak (só visual —
/// o contador de verdade, `Progress.consecutiveDays`, não tem teto).
const int kStreakRowLength = 5;

String dailyDateStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Dias seguidos jogados — função pura (testável), porte de
/// `computeConsecutiveDays` do ARCO. Volta pra 1 se um dia foi pulado.
int computeConsecutiveDays({
  required DateTime today,
  required String? lastVisit,
  required int previousConsecutiveDays,
}) {
  if (lastVisit == dailyDateStr(today)) return previousConsecutiveDays;
  final last = DateTime.tryParse(lastVisit ?? '');
  if (last == null) return 1;
  final gap = DateTime(today.year, today.month, today.day)
      .difference(DateTime(last.year, last.month, last.day))
      .inDays;
  return gap == 1 ? previousConsecutiveDays + 1 : 1;
}

/// Posição (1..[kStreakRowLength]) de [consecutiveDays] dentro da fileira
/// visual do calendário — só estética, não afeta o contador de verdade.
int displayDayFor(int consecutiveDays) =>
    ((consecutiveDays - 1) % kStreakRowLength) + 1;

/// Tela de visita diária — registra o dia (streak de constância) e mostra
/// o calendário de dias seguidos, sem recompensa (o Arc Chain não tem
/// moeda de power-ups como o ARCO); só alimenta os troféus `streakDays`/
/// `totalDays`. Porte enxuto de `DailyRewardScreen` do ARCO.
class DailyVisitScreen extends StatefulWidget {
  const DailyVisitScreen({super.key});

  @override
  State<DailyVisitScreen> createState() => _DailyVisitScreenState();
}

class _DailyVisitScreenState extends State<DailyVisitScreen> {
  bool _loaded = false;
  int _consecutiveDays = 1;
  bool _broken = false;
  int _previousConsecutiveDays = 1;
  bool _brokenAnimDone = true;
  List<String> _newTrophies = const [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final p = Progress.instance;
    final today = DateTime.now();
    final alreadyVisited = p.lastVisitDate == dailyDateStr(today);
    final previous = p.consecutiveDays;

    final newConsecutive = computeConsecutiveDays(
      today: today,
      lastVisit: p.lastVisitDate,
      previousConsecutiveDays: previous,
    );
    final broken = !alreadyVisited && previous > 1 && newConsecutive == 1;

    if (!alreadyVisited) {
      p.consecutiveDays = newConsecutive;
      p.totalDaysPlayed += 1;
      p.lastVisitDate = dailyDateStr(today);
      await p.saveDailyVisit();
      _newTrophies = await checkAndPersistTrophies();
    }

    if (!mounted) return;
    setState(() {
      _consecutiveDays = newConsecutive;
      _previousConsecutiveDays = previous.clamp(1, 1 << 30);
      _broken = broken;
      _brokenAnimDone = !broken;
      _loaded = true;
    });
    if (_newTrophies.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showTrophyUnlockedDialog(context, ids: _newTrophies);
      });
    }
  }

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LevelMapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator(color: inkMuted))
            : SizedBox.expand(
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    Icon(Icons.event_available_rounded,
                        size: 26, color: inkMuted),
                    const SizedBox(height: 26),
                    _broken && !_brokenAnimDone
                        ? _StreakBrokenTransition(
                            previousDay:
                                displayDayFor(_previousConsecutiveDays),
                            newDay: displayDayFor(_consecutiveDays),
                            onDone: () {
                              if (mounted) {
                                setState(() => _brokenAnimDone = true);
                              }
                            },
                          )
                        : _dayRow(displayDayFor(_consecutiveDays)),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            size: 30, color: Color(0xFFE0883C)),
                        const SizedBox(width: 8),
                        Text(
                          '$_consecutiveDays',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: ink.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(flex: 4),
                    Material(
                      color: ink,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _continue,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 26, color: paper),
                        ),
                      ),
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Fileira de [kStreakRowLength] dias no dia [currentDay] atual (1-based).
/// Se [xStampDay] for dado, aquele dia recebe o selo de "streak perdido"
/// com opacidade [stampOpacity] (usado pela transição de streak quebrado).
Widget _dayRow(int currentDay, {int? xStampDay, double stampOpacity = 1}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var day = 1; day <= kStreakRowLength; day++) ...[
        _DaySlot(
          day: day,
          claimed: day < currentDay,
          isToday: day == currentDay,
          overlay: day == xStampDay
              ? Opacity(opacity: stampOpacity, child: const _LostBadge())
              : null,
        ),
        if (day < kStreakRowLength) const SizedBox(width: 9),
      ],
    ],
  );
}

/// Um dia da fileira — só o ícone, sem legenda: check para dias já
/// contados, contorno grosso + raio pro dia de hoje, contorno claro pros
/// dias futuros.
class _DaySlot extends StatelessWidget {
  final int day;
  final bool claimed;
  final bool isToday;
  final Widget? overlay;

  const _DaySlot({
    required this.day,
    required this.claimed,
    required this.isToday,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    const size = 38.0;
    final icon = claimed ? Icons.check_rounded : Icons.bolt_rounded;
    final Color bg;
    final Color border;
    final double borderWidth;
    final Color iconColor;
    if (claimed) {
      bg = accentGold;
      border = const Color(0xFFC79A0A);
      borderWidth = 1.5;
      iconColor = const Color(0xFF7A5C00);
    } else if (isToday) {
      bg = Colors.white;
      border = ink;
      borderWidth = 3;
      iconColor = ink;
    } else {
      bg = Colors.white;
      border = paperLine;
      borderWidth = 1.5;
      iconColor = inkMuted.withValues(alpha: 0.5);
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: borderWidth),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: iconColor),
        ),
        if (overlay != null) Positioned(top: -8, right: -8, child: overlay!),
      ],
    );
  }
}

/// Selo vermelho de "streak perdido" sobreposto ao dia interrompido.
class _LostBadge extends StatelessWidget {
  const _LostBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFFE24B4A),
        shape: BoxShape.circle,
        border: Border.all(color: paper, width: 2),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
    );
  }
}

/// Transição animada (5s) de streak quebrado: dissolve a fileira anterior
/// (com o dia interrompido marcado) num carinha triste passageiro e
/// reaparece já reiniciada no dia 1.
class _StreakBrokenTransition extends StatefulWidget {
  final int previousDay;
  final int newDay;
  final VoidCallback? onDone;

  const _StreakBrokenTransition({
    required this.previousDay,
    required this.newDay,
    this.onDone,
  });

  @override
  State<_StreakBrokenTransition> createState() =>
      _StreakBrokenTransitionState();
}

class _StreakBrokenTransitionState extends State<_StreakBrokenTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone?.call();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _windowed(double t, double start, double end) =>
      ((t - start) / (end - start)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final beforeOpacity = 1 - _windowed(t, 0.30, 0.55);
        final afterT = _windowed(t, 0.55, 0.85);
        final afterOpacity = afterT;
        final afterScale = 0.94 + 0.06 * Curves.easeOut.transform(afterT);
        final stampIn = _windowed(t, 0.22, 0.32);
        final stampOut = 1 - _windowed(t, 0.52, 0.58);
        final stampOpacity = t < 0.52 ? stampIn : stampOut;
        final sadIn = _windowed(t, 0.25, 0.40);
        final sadOut = 1 - _windowed(t, 0.58, 0.75);
        final sadOpacity = t < 0.58 ? sadIn : sadOut;

        return SizedBox(
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: beforeOpacity,
                child: _dayRow(
                  widget.previousDay,
                  xStampDay: stampOpacity > 0 ? widget.previousDay : null,
                  stampOpacity: stampOpacity,
                ),
              ),
              Opacity(
                opacity: afterOpacity,
                child: Transform.scale(
                  scale: afterScale,
                  child: _dayRow(widget.newDay),
                ),
              ),
              if (sadOpacity > 0)
                Opacity(
                  opacity: sadOpacity,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1EFE8),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.sentiment_dissatisfied_rounded,
                      size: 22,
                      color: Color(0xFF888780),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
