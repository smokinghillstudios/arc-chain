# Arc Chain (Flutter)

Porte para Flutter/Android do protótipo HTML/CSS `arc-chain-game-v1.html`.

Puzzle de arcos: toque nas peças para alternar entre os dois tipos de curva
(A/B) e gire a seta de partida até que cada cadeia flua do início (seta) ao
fim (asterisco). O grid é toroidal — o fluxo atravessa as bordas. Cada fase
tem um limite de toques; menos toques = mais estrelas (até 3).

Configurações alinhadas ao ARCO (`C:\Jogos\ARCO\arco`): mesmas fontes
Nunito estáticas (400–900), mesmo ícone de launcher (adaptativo, fundo
`#4A7FA5`), SFX/músicas dos assets do ARCO e AdMob (banner no topo da tela
de jogo + vídeo premiado de +3 toques quando os toques esgotam). Os IDs de
anúncio são os **de teste do Google** — troque em `lib/ads_service.dart` e
no `AndroidManifest.xml` antes de publicar.

## Estrutura

- `lib/engine.dart` — lógica dos arcos, PRNG mulberry32 com seed (mesmas
  15 fases do protótipo, tabuleiros determinísticos) e geração procedural.
- `lib/game_screen.dart` — tela do jogo: animação do fluxo das cadeias,
  confete, estrelas, contador de toques, bloqueio do tabuleiro, banner e
  oferta de vídeo premiado.
- `lib/board_painter.dart` — renderização do tabuleiro (CustomPainter).
- `lib/audio.dart` + `lib/music.dart` — SFX (AudioPool lowLatency sobre
  assets/sfx/) e música em loop (assets/music/), no padrão do ARCO.
- `lib/ads_service.dart` — AdMob (rewarded + banner), portado do ARCO.
- `lib/progress.dart` — progresso e preferências de som (shared_preferences).
- `lib/main.dart` + `lib/ui_common.dart` — menu de fases e visual.

## Rodar

```sh
flutter run            # com um dispositivo/emulador Android conectado
flutter build apk      # gera build/app/outputs/flutter-apk/app-release.apk
flutter test           # testes do motor (geração determinística)
```
