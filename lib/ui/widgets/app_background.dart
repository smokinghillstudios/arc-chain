import 'package:flutter/material.dart';

/// Fundo do jogo: gradiente linear + dois brilhos radiais, como no CSS
/// original do protótipo.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF558CB2), Color(0xFF3F6A88)],
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -1.0),
            radius: 1.1,
            colors: [Color(0xFF5B93B8), Color(0x005B93B8)],
            stops: [0.0, 0.55],
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.7, 0.8),
              radius: 1.0,
              colors: [Color(0xFF3E6785), Color(0x003E6785)],
              stops: [0.0, 0.5],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
