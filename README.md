# Cadeia de Markov em Haskell: Previsão do Tempo

Trabalho do tema **2.5 Modelo de Markov**: implementação de uma cadeia de Markov em Haskell, simulação de transições e análise das frequências e probabilidades dos estados.

## Objetivo

Modelar o clima como um processo estocástico com a **propriedade de Markov** (o clima de amanhã depende apenas do clima de hoje) e mostrar, por dois caminhos independentes, que a cadeia converge para uma **distribuição estacionária**:

1. **Simulação:** sortear muitos dias e contar a frequência de cada estado.
2. **Cálculo exato:** evoluir o vetor de probabilidades com π(t+1) = π(t) · P.

Os dois caminhos chegam ao mesmo resultado: π ≈ (0,389; 0,333; 0,278).

## O modelo

**Estados:** `Sol`, `Nublado`, `Chuva`.

**Matriz de transição P** (linha = clima hoje, coluna = clima amanhã):

|             | → Sol | → Nublado | → Chuva |
|-------------|:-----:|:---------:|:-------:|
| **Sol**     |  0.6  |    0.3    |   0.1   |
| **Nublado** |  0.3  |    0.4    |   0.3   |
| **Chuva**   |  0.2  |    0.3    |   0.5   |

Cada linha soma 1. A distribuição estacionária, resolvendo π = π · P com π somando 1, é **π = (7/18, 6/18, 5/18)**.

## Estrutura do projeto

```
g5-markov-haskell/
├── app/Main.hs      -- programa principal: executa e imprime a demonstração
├── src/Markov.hs    -- a cadeia de Markov (tipos, simulação, cálculos)
├── markov.cabal     -- configuração do projeto e dependências
└── README.md
```

## Como executar

**Requisitos:** GHC e Cabal, instalados pelo [GHCup](https://www.haskell.org/ghcup/).

```
git clone https://github.com/leof98/g5-markov-haskell.git
cd g5-markov-haskell
cabal update
cabal run
```

Na primeira execução, o Cabal baixa a biblioteca `random`. Depois disso, `cabal run` roda direto.

## Funcionamento

O código em `src/Markov.hs` é dividido em quatro partes.

### Parte 1: Estados e matriz
| Função | O que faz |
|---|---|
| `Estado` | Tipo com os 3 estados. `Enum` liga cada estado a um índice (Sol=0, Nublado=1, Chuva=2). |
| `matriz` | A matriz de transição P. |
| `probTransicao` | Devolve P(i → j). |
| `validarMatriz` | Confere se a matriz é estocástica: quadrada, valores entre 0 e 1, linhas somando 1. |

### Parte 2: Simulação
| Função | O que faz |
|---|---|
| `proximoEstado` | Sorteia o próximo estado. Transforma a linha do estado atual em probabilidades acumuladas (ex.: `[0.6, 0.9, 1.0]`) e verifica em que intervalo cai um número uniforme `u ∈ [0,1]`. |
| `simular` | Gera uma sequência de N dias. Usa **apenas o estado atual** para sortear o próximo (propriedade de Markov). O gerador aleatório é passado adiante a cada passo, e a seed fixa torna a simulação reproduzível. |

### Parte 3: Frequências
| Função | O que faz |
|---|---|
| `frequencias` | Proporção de cada estado numa sequência simulada. |
| `piTeorico` | Distribuição estacionária calculada à mão: (7/18, 6/18, 5/18). |

### Parte 4: Evolução das probabilidades
| Função | O que faz |
|---|---|
| `passo` | Um passo no tempo: π(t+1) = π(t) · P. |
| `evolucao` | Lista π₀, π₁, π₂, … (aplicando `passo` repetidamente). |
| `estacionaria` | Aplica `passo` até o vetor parar de mudar e encontra π sozinho. |
| `multiplicar`, `potencia` | Multiplicação de matrizes e Pⁿ, a matriz de transição em n passos. |

## Resultados e interpretação

**Frequências (simulação a partir de Sol, seed 42):**

```
       N |    Sol  Nublado    Chuva | maior erro
     100 |  0.360    0.320    0.320 |   0.0422
    1000 |  0.392    0.321    0.287 |   0.0123
   10000 |  0.395    0.328    0.276 |   0.0063
  100000 |  0.390    0.333    0.276 |   0.0016
 teorico |  0.389    0.333    0.278 |
```

Quanto maior N, mais as frequências se aproximam de π. A convergência é uma tendência, não é garantida a cada linha: com poucas amostras o acaso pesa mais. Os números exatos podem variar conforme a versão da biblioteca `random`.

**Evolução de π** (começando com Sol, `[1,0,0]`, ou com Chuva, `[0,0,1]`): em cerca de 10 passos, os dois chegam a `[0.3889, 0.3333, 0.2778]`. O estado inicial é "esquecido".

**Probabilidade em n passos:** hoje Sol → Chuva amanhã = 0,10, e daqui a 3 dias (P³) = 0,246. Em P²⁰, todas as linhas são iguais a π.

**Conclusão:** a simulação (frequências) e o cálculo exato (evolução de π) concordam com a distribuição estacionária obtida à mão.

## Limitações do modelo

- **Memória curta:** só o dia atual influencia o próximo. O clima real depende de mais fatores e de mais dias anteriores.
- **Probabilidades fixas:** a matriz não muda com a estação do ano (cadeia homogênea).
- **Matriz definida manualmente:** num caso real, ela seria estimada a partir de dados históricos.
- **Poucos estados:** modelos reais podem ter muitos estados, e a matriz cresce rapidamente.
