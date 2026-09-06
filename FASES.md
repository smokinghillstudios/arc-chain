# Fases do Arc Chain

Lista gerada automaticamente a partir da fórmula de dificuldade em [`lib/core/engine.dart`](lib/core/engine.dart) (`_buildLevels`/`_levelFor`) — não é uma lista escrita à mão, é exatamente o que o app calcula em tempo de execução para as 100 fases.

## Colunas

- **Fase**: número da fase (1–100).
- **Tabuleiro**: colunas×linhas do grid (retangular, mais alto que largo nas fases avançadas). Teto de **8×12** — acima disso fica ruim de jogar (células pequenas demais).
- **Cadeias**: quantas cadeias simultâneas (cores distintas) a fase tem — teto de 5 (limite de cores disponíveis).
- **Toques p/ 3★**: `minTaps` — toques mínimos possíveis; jogar com até esse número dá 3 estrelas.
- **Toques máx.**: `maxTaps` — toques disponíveis antes de perder a fase. **Teto de 50** em qualquer fase: `GameBoard.generate` tenta até 300 vezes (mesma seed, sementes internas diferentes) até achar um tabuleiro dentro desse limite; se nenhuma tentativa couber, fica com a melhor encontrada.
- **Seed**: semente do gerador determinístico (`10000 + id`) — mesma fase sempre gera o mesmo tabuleiro.

A dificuldade sobe em duas ondas sobrepostas: a altura do tabuleiro cresce com respiros periódicos (grupos 4, 9 e 14 de cada bloco de 5 fases) até o teto de 12 linhas, a largura cresce mais devagar até o teto de 8 colunas, e o número de cadeias oscila dentro de cada grupo de 5 fases (pico nas fases que fecham o grupo, antes de cada parada de vídeo). `minTaps`/`maxTaps` variam com a semente de cada fase dentro da faixa de dificuldade do momento — não são estritamente crescentes fase a fase, mas nunca passam de 50 toques máximos.

| Fase | Tabuleiro | Cadeias | Toques p/ 3★ | Toques máx. | Seed |
|---|---|---|---|---|---|
| 1 | 6x6 | 1 | 6 | 9 | 10001 |
| 2 | 6x6 | 1 | 1 | 4 | 10002 |
| 3 | 6x6 | 2 | 15 | 23 | 10003 |
| 4 | 6x6 | 1 | 10 | 15 | 10004 |
| 5 | 6x6 | 2 | 11 | 17 | 10005 |
| 6 | 6x6 | 1 | 1 | 4 | 10006 |
| 7 | 6x6 | 1 | 6 | 9 | 10007 |
| 8 | 6x6 | 2 | 7 | 11 | 10008 |
| 9 | 6x6 | 1 | 5 | 8 | 10009 |
| 10 | 6x6 | 2 | 14 | 21 | 10010 |
| 11 | 6x6 | 1 | 2 | 5 | 10011 |
| 12 | 6x6 | 1 | 5 | 8 | 10012 |
| 13 | 6x6 | 2 | 7 | 11 | 10013 |
| 14 | 6x6 | 1 | 9 | 14 | 10014 |
| 15 | 6x6 | 2 | 13 | 20 | 10015 |
| 16 | 6x7 | 1 | 9 | 14 | 10016 |
| 17 | 6x7 | 1 | 8 | 12 | 10017 |
| 18 | 6x7 | 2 | 14 | 21 | 10018 |
| 19 | 6x7 | 1 | 3 | 6 | 10019 |
| 20 | 6x7 | 2 | 25 | 38 | 10020 |
| 21 | 6x6 | 1 | 8 | 12 | 10021 |
| 22 | 6x6 | 1 | 4 | 7 | 10022 |
| 23 | 6x6 | 2 | 11 | 17 | 10023 |
| 24 | 6x6 | 1 | 14 | 21 | 10024 |
| 25 | 6x6 | 2 | 9 | 14 | 10025 |
| 26 | 6x7 | 2 | 9 | 14 | 10026 |
| 27 | 6x7 | 2 | 11 | 17 | 10027 |
| 28 | 6x7 | 3 | 27 | 41 | 10028 |
| 29 | 6x7 | 2 | 8 | 12 | 10029 |
| 30 | 6x7 | 3 | 15 | 23 | 10030 |
| 31 | 7x8 | 2 | 13 | 20 | 10031 |
| 32 | 7x8 | 2 | 17 | 26 | 10032 |
| 33 | 7x8 | 3 | 9 | 14 | 10033 |
| 34 | 7x8 | 2 | 15 | 23 | 10034 |
| 35 | 7x8 | 3 | 29 | 44 | 10035 |
| 36 | 7x8 | 2 | 12 | 18 | 10036 |
| 37 | 7x8 | 2 | 11 | 17 | 10037 |
| 38 | 7x8 | 3 | 25 | 38 | 10038 |
| 39 | 7x8 | 2 | 13 | 20 | 10039 |
| 40 | 7x8 | 3 | 15 | 23 | 10040 |
| 41 | 7x8 | 3 | 19 | 29 | 10041 |
| 42 | 7x8 | 3 | 30 | 45 | 10042 |
| 43 | 7x8 | 4 | 33 | 50 | 10043 |
| 44 | 7x8 | 3 | 15 | 23 | 10044 |
| 45 | 7x8 | 4 | 30 | 45 | 10045 |
| 46 | 7x8 | 2 | 18 | 27 | 10046 |
| 47 | 7x8 | 2 | 14 | 21 | 10047 |
| 48 | 7x8 | 3 | 27 | 41 | 10048 |
| 49 | 7x8 | 2 | 9 | 14 | 10049 |
| 50 | 7x8 | 3 | 33 | 50 | 10050 |
| 51 | 7x9 | 3 | 21 | 32 | 10051 |
| 52 | 7x9 | 3 | 25 | 38 | 10052 |
| 53 | 7x9 | 4 | 32 | 48 | 10053 |
| 54 | 7x9 | 3 | 32 | 48 | 10054 |
| 55 | 7x9 | 4 | 26 | 39 | 10055 |
| 56 | 7x9 | 3 | 24 | 36 | 10056 |
| 57 | 7x9 | 3 | 19 | 29 | 10057 |
| 58 | 7x9 | 4 | 19 | 29 | 10058 |
| 59 | 7x9 | 3 | 31 | 47 | 10059 |
| 60 | 7x9 | 4 | 23 | 35 | 10060 |
| 61 | 8x10 | 4 | 32 | 48 | 10061 |
| 62 | 8x10 | 4 | 32 | 48 | 10062 |
| 63 | 8x10 | 5 | 33 | 50 | 10063 |
| 64 | 8x10 | 4 | 24 | 36 | 10064 |
| 65 | 8x10 | 5 | 28 | 42 | 10065 |
| 66 | 8x10 | 4 | 22 | 33 | 10066 |
| 67 | 8x10 | 4 | 29 | 44 | 10067 |
| 68 | 8x10 | 5 | 31 | 47 | 10068 |
| 69 | 8x10 | 4 | 29 | 44 | 10069 |
| 70 | 8x10 | 5 | 33 | 50 | 10070 |
| 71 | 8x9 | 3 | 29 | 44 | 10071 |
| 72 | 8x9 | 3 | 16 | 24 | 10072 |
| 73 | 8x9 | 4 | 25 | 38 | 10073 |
| 74 | 8x9 | 3 | 26 | 39 | 10074 |
| 75 | 8x9 | 4 | 24 | 36 | 10075 |
| 76 | 8x11 | 4 | 17 | 26 | 10076 |
| 77 | 8x11 | 4 | 32 | 48 | 10077 |
| 78 | 8x11 | 5 | 23 | 35 | 10078 |
| 79 | 8x11 | 4 | 30 | 45 | 10079 |
| 80 | 8x11 | 5 | 29 | 44 | 10080 |
| 81 | 8x11 | 5 | 32 | 48 | 10081 |
| 82 | 8x11 | 5 | 27 | 41 | 10082 |
| 83 | 8x11 | 5 | 27 | 41 | 10083 |
| 84 | 8x11 | 5 | 24 | 36 | 10084 |
| 85 | 8x11 | 5 | 28 | 42 | 10085 |
| 86 | 8x11 | 5 | 25 | 38 | 10086 |
| 87 | 8x11 | 5 | 31 | 47 | 10087 |
| 88 | 8x11 | 5 | 32 | 48 | 10088 |
| 89 | 8x11 | 5 | 33 | 50 | 10089 |
| 90 | 8x11 | 5 | 21 | 32 | 10090 |
| 91 | 8x12 | 5 | 28 | 42 | 10091 |
| 92 | 8x12 | 5 | 28 | 42 | 10092 |
| 93 | 8x12 | 5 | 25 | 38 | 10093 |
| 94 | 8x12 | 5 | 23 | 35 | 10094 |
| 95 | 8x12 | 5 | 27 | 41 | 10095 |
| 96 | 8x12 | 5 | 28 | 42 | 10096 |
| 97 | 8x12 | 5 | 33 | 50 | 10097 |
| 98 | 8x12 | 5 | 33 | 50 | 10098 |
| 99 | 8x12 | 5 | 27 | 41 | 10099 |
| 100 | 8x12 | 5 | 23 | 35 | 10100 |

