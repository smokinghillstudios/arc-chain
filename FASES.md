# Fases do Arc Chain

Lista gerada automaticamente a partir da fórmula de dificuldade em [`lib/core/engine.dart`](lib/core/engine.dart) (`levelForId`) — não é uma lista escrita à mão, é exatamente o que o app calcula em tempo de execução. Não tem fim: depois da fase 100 entra o **modo infinito** (seção própria abaixo), que repete um ciclo pra sempre.

Como cada fase é gerada por uma função pura do `id` (seed `10000 + id`, PRNG determinístico `Mulberry32`), o mesmo `id` sempre produz exatamente o mesmo tabuleiro em qualquer aparelho — não depende de servidor nem de conexão.

## Colunas

- **Fase**: número da fase.
- **Tabuleiro**: colunas×linhas do grid (retangular, mais alto que largo). Teto de **8×10** — acima disso fica ruim de jogar (células pequenas demais).
- **Cadeias**: quantas cadeias simultâneas (cores distintas) a fase tem — teto de 5 (limite de cores disponíveis). A posição de início de cada cadeia segue um layout fixo por quantidade (topo/centro/base × esquerda/direita) — ver `_startLayouts` em `engine.dart`.
- **Toques p/ 3★**: `minTaps` — o número **real** mínimo de toques pra resolver a fase (não só o da rota pretendida na geração — o tabuleiro é toroidal, então às vezes existe um atalho mais barato; `GameBoard.generate` acha esse mínimo de verdade via busca em `_realMinTapsForChain` e é isso que aparece aqui). Jogar com até esse número dá 3 estrelas. Tem um piso por faixa de fase: **1** (fases 1–3), **3** (fases 4–20), **5** (fases 21 em diante, incluindo todo o modo infinito) — exceto fases de **1 cadeia só**, cujo piso é **2**: num tabuleiro pequeno e toroidal, uma cadeia sozinha quase sempre tem um atalho de 2 toques, então pedir mais que isso esgotaria as 300 tentativas de geração à toa.
- **Toques máx.**: `maxTaps` — toques disponíveis antes de perder a fase. Teto de **50** em qualquer fase.
- **Seed**: semente do gerador determinístico (`10000 + id`).

`GameBoard.generate` tenta até 300 vezes (mesma seed, avançando o PRNG a cada tentativa) até achar um tabuleiro cujo mínimo real fique ao mesmo tempo acima do piso e abaixo do teto de toques; se nenhuma tentativa couber nos dois, fica com a mais próxima de conseguir.

## Fases 1–100 (rampa inicial)

A dificuldade sobe em duas ondas sobrepostas: a altura do tabuleiro cresce com respiros periódicos (grupos 4, 9 e 14 de cada bloco de 5 fases) até o teto de 10 linhas, a largura cresce mais devagar até o teto de 8 colunas, e o número de cadeias oscila dentro de cada grupo de 5 fases (pico nas fases que fecham o grupo, antes de cada parada de vídeo).

| Fase | Tabuleiro | Cadeias | Toques p/ 3★ | Toques máx. | Seed |
|---|---|---|---|---|---|
| 1 | 6x6 | 1 | 1 | 4 | 10001 |
| 2 | 6x6 | 1 | 1 | 4 | 10002 |
| 3 | 6x6 | 2 | 3 | 6 | 10003 |
| 4 | 6x6 | 1 | 2 | 5 | 10004 |
| 5 | 6x6 | 2 | 4 | 7 | 10005 |
| 6 | 6x6 | 1 | 2 | 5 | 10006 |
| 7 | 6x6 | 1 | 2 | 5 | 10007 |
| 8 | 6x6 | 2 | 3 | 6 | 10008 |
| 9 | 6x6 | 1 | 2 | 5 | 10009 |
| 10 | 6x6 | 2 | 3 | 6 | 10010 |
| 11 | 6x6 | 1 | 2 | 5 | 10011 |
| 12 | 6x6 | 1 | 2 | 5 | 10012 |
| 13 | 6x6 | 2 | 3 | 6 | 10013 |
| 14 | 6x6 | 1 | 2 | 5 | 10014 |
| 15 | 6x6 | 2 | 3 | 6 | 10015 |
| 16 | 6x7 | 1 | 2 | 5 | 10016 |
| 17 | 6x7 | 1 | 2 | 5 | 10017 |
| 18 | 6x7 | 2 | 4 | 7 | 10018 |
| 19 | 6x7 | 1 | 2 | 5 | 10019 |
| 20 | 6x7 | 2 | 4 | 7 | 10020 |
| 21 | 6x6 | 1 | 2 | 5 | 10021 |
| 22 | 6x6 | 1 | 2 | 5 | 10022 |
| 23 | 6x6 | 2 | 5 | 8 | 10023 |
| 24 | 6x6 | 1 | 2 | 5 | 10024 |
| 25 | 6x6 | 2 | 5 | 8 | 10025 |
| 26 | 6x7 | 2 | 5 | 8 | 10026 |
| 27 | 6x7 | 2 | 5 | 8 | 10027 |
| 28 | 6x7 | 3 | 5 | 8 | 10028 |
| 29 | 6x7 | 2 | 5 | 8 | 10029 |
| 30 | 6x7 | 3 | 5 | 8 | 10030 |
| 31 | 7x8 | 2 | 5 | 8 | 10031 |
| 32 | 7x8 | 2 | 5 | 8 | 10032 |
| 33 | 7x8 | 3 | 5 | 8 | 10033 |
| 34 | 7x8 | 2 | 5 | 8 | 10034 |
| 35 | 7x8 | 3 | 5 | 8 | 10035 |
| 36 | 7x8 | 2 | 5 | 8 | 10036 |
| 37 | 7x8 | 2 | 5 | 8 | 10037 |
| 38 | 7x8 | 3 | 5 | 8 | 10038 |
| 39 | 7x8 | 2 | 5 | 8 | 10039 |
| 40 | 7x8 | 3 | 5 | 8 | 10040 |
| 41 | 7x8 | 3 | 5 | 8 | 10041 |
| 42 | 7x8 | 3 | 7 | 11 | 10042 |
| 43 | 7x8 | 4 | 6 | 9 | 10043 |
| 44 | 7x8 | 3 | 6 | 9 | 10044 |
| 45 | 7x8 | 4 | 10 | 15 | 10045 |
| 46 | 7x8 | 2 | 5 | 8 | 10046 |
| 47 | 7x8 | 2 | 5 | 8 | 10047 |
| 48 | 7x8 | 3 | 7 | 11 | 10048 |
| 49 | 7x8 | 2 | 5 | 8 | 10049 |
| 50 | 7x8 | 3 | 5 | 8 | 10050 |
| 51 | 7x9 | 3 | 5 | 8 | 10051 |
| 52 | 7x9 | 3 | 5 | 8 | 10052 |
| 53 | 7x9 | 4 | 10 | 15 | 10053 |
| 54 | 7x9 | 3 | 6 | 9 | 10054 |
| 55 | 7x9 | 4 | 6 | 9 | 10055 |
| 56 | 7x9 | 3 | 5 | 8 | 10056 |
| 57 | 7x9 | 3 | 6 | 9 | 10057 |
| 58 | 7x9 | 4 | 9 | 14 | 10058 |
| 59 | 7x9 | 3 | 5 | 8 | 10059 |
| 60 | 7x9 | 4 | 8 | 12 | 10060 |
| 61 | 8x10 | 4 | 8 | 12 | 10061 |
| 62 | 8x10 | 4 | 9 | 14 | 10062 |
| 63 | 8x10 | 5 | 7 | 11 | 10063 |
| 64 | 8x10 | 4 | 9 | 14 | 10064 |
| 65 | 8x10 | 5 | 11 | 17 | 10065 |
| 66 | 8x10 | 4 | 10 | 15 | 10066 |
| 67 | 8x10 | 4 | 7 | 11 | 10067 |
| 68 | 8x10 | 5 | 12 | 18 | 10068 |
| 69 | 8x10 | 4 | 9 | 14 | 10069 |
| 70 | 8x10 | 5 | 11 | 17 | 10070 |
| 71 | 8x9 | 3 | 5 | 8 | 10071 |
| 72 | 8x9 | 3 | 5 | 8 | 10072 |
| 73 | 8x9 | 4 | 10 | 15 | 10073 |
| 74 | 8x9 | 3 | 6 | 9 | 10074 |
| 75 | 8x9 | 4 | 10 | 15 | 10075 |
| 76 | 8x10 | 4 | 7 | 11 | 10076 |
| 77 | 8x10 | 4 | 10 | 15 | 10077 |
| 78 | 8x10 | 5 | 12 | 18 | 10078 |
| 79 | 8x10 | 4 | 11 | 17 | 10079 |
| 80 | 8x10 | 5 | 15 | 23 | 10080 |
| 81 | 8x10 | 5 | 11 | 17 | 10081 |
| 82 | 8x10 | 5 | 8 | 12 | 10082 |
| 83 | 8x10 | 5 | 10 | 15 | 10083 |
| 84 | 8x10 | 5 | 11 | 17 | 10084 |
| 85 | 8x10 | 5 | 10 | 15 | 10085 |
| 86 | 8x10 | 5 | 12 | 18 | 10086 |
| 87 | 8x10 | 5 | 9 | 14 | 10087 |
| 88 | 8x10 | 5 | 7 | 11 | 10088 |
| 89 | 8x10 | 5 | 12 | 18 | 10089 |
| 90 | 8x10 | 5 | 13 | 20 | 10090 |
| 91 | 8x10 | 5 | 11 | 17 | 10091 |
| 92 | 8x10 | 5 | 9 | 14 | 10092 |
| 93 | 8x10 | 5 | 12 | 18 | 10093 |
| 94 | 8x10 | 5 | 15 | 23 | 10094 |
| 95 | 8x10 | 5 | 15 | 23 | 10095 |
| 96 | 8x10 | 5 | 8 | 12 | 10096 |
| 97 | 8x10 | 5 | 9 | 14 | 10097 |
| 98 | 8x10 | 5 | 11 | 17 | 10098 |
| 99 | 8x10 | 5 | 12 | 18 | 10099 |
| 100 | 8x10 | 5 | 10 | 15 | 10100 |

## Fase 101 em diante (modo infinito)

Em vez de ficar travado no teto (8×10, 5 cadeias) pra sempre, cadeias **e** tabuleiro oscilam juntos num ciclo de 8 grupos de 5 fases (**40 fases por volta completa**) — o tabuleiro encolhe junto quando as cadeias caem pra 3, não só as cadeias sozinhas. A fase 0 do ciclo (fase 101) bate exatamente com o teto da rampa (8×10, 5 cadeias) — a virada 100→101 é suave, sem degrau. O ciclo então se repete pra sempre: fase 141 é idêntica em tabuleiro/cadeias à fase 101, fase 181 à 141, e assim por diante (a seed continua diferente a cada fase, então os tabuleiros nunca se repetem de verdade, só o "tamanho" da dificuldade).

```
índice do ciclo:  0    1    2    3    4    5    6    7
cadeias:          5    4    4    3    3    4    4    5
tabuleiro (col×lin): 8×10  8×9  7×9  7×8  7×8  7×9  8×9  8×10
```

Amostra das 10 primeiras fases do modo infinito:

| Fase | Tabuleiro | Cadeias | Toques p/ 3★ | Toques máx. | Seed |
|---|---|---|---|---|---|
| 101 | 8x10 | 5 | 12 | 18 | 10101 |
| 102 | 8x10 | 5 | 5 | 8 | 10102 |
| 103 | 8x10 | 5 | 15 | 23 | 10103 |
| 104 | 8x10 | 5 | 10 | 15 | 10104 |
| 105 | 8x10 | 5 | 11 | 17 | 10105 |
| 106 | 8x9 | 4 | 7 | 11 | 10106 |
| 107 | 8x9 | 4 | 8 | 12 | 10107 |
| 108 | 8x9 | 5 | 13 | 20 | 10108 |
| 109 | 8x9 | 4 | 10 | 15 | 10109 |
| 110 | 8x9 | 5 | 10 | 15 | 10110 |
