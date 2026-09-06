import 'package:flutter/material.dart';

/// Cores e tipografia — porte da paleta do ARCO (`ui/theme.dart`).
const cream = Color(0xFFF5F0E8);
const accentGold = Color(0xFFF1C40F);

// ── Telas de menu (splash/mapa) — estilo minimalista claro do ARCO ──
const paper = Color(0xFFFAF7F1); // fundo "papel"
const ink = Color(0xFF2C2C2C); // texto principal
const inkMuted = Color(0xFFB9B0A0); // texto secundário
const paperLine = Color(0xFFE2DACB); // traços/contornos suaves

// ── Diálogos e HUD do jogo — porte de `ArcoColors` do ARCO ──
const headerDark = Color(0xFF3A5F7A); // cabeçalho do detalhe da fase / toggles ligados
const playGreen = Color(0xFF5CB85C); // botão "jogar" e cabeçalho de vitória
const btnBg = Color(0xFFEDE8DF); // botões quadrados de ação nos diálogos
const gear = Color(0xFF7C8C95); // ícone de configurações do HUD
const bg = Color(0xFF4A7FA5); // fundo da tela de jogo
const defeatRed = Color(0xFFA8402F); // cabeçalho do diálogo de derrota

/// Nunito estática (mesmos 5 pesos empacotados no ARCO: 400/600/700/800/900).
TextStyle nunito(double size, double weight,
    {Color color = cream, double? letterSpacing, List<Shadow>? shadows}) {
  return TextStyle(
    fontFamily: 'Nunito',
    fontWeight: FontWeight.values[(weight.round() ~/ 100) - 1],
    fontSize: size,
    color: color,
    letterSpacing: letterSpacing,
    shadows: shadows,
  );
}
