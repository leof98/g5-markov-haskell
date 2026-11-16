-- | Cadeia de Markov de clima com 3 estados.
-- Parte 1: estados, matriz de transicao e validacao.
-- Parte 2: simulacao (sorteio do proximo estado e geracao de sequencias).
-- Parte 3: frequencias observadas vs. distribuicao estacionaria teorica.
module Markov
  ( Estado (..)
  , Matriz
  , todosEstados
  , matriz
  , probTransicao
  , validarMatriz
  , proximoEstado
  , simular
  , frequencias
  , piTeorico
  ) where

import System.Random (StdGen, uniformR)

-- | Os estados possiveis da cadeia.
-- Enum permite converter Estado <-> Int (Sol=0, Nublado=1, Chuva=2),
-- e Bounded permite listar todos com [minBound .. maxBound].
data Estado = Sol | Nublado | Chuva
  deriving (Show, Eq, Ord, Enum, Bounded)

-- | Uma matriz e uma lista de linhas; cada linha e uma lista de probabilidades.
type Matriz = [[Double]]

-- | Lista de todos os estados, na ordem: [Sol, Nublado, Chuva].
todosEstados :: [Estado]
todosEstados = [minBound .. maxBound]

-- | Matriz de transicao P.
-- Linha i = estado atual; coluna j = proximo estado.
-- P !! i !! j = probabilidade de ir do estado i para o estado j.
matriz :: Matriz
matriz =
  --  Sol  Nublado Chuva
  [ [0.6,  0.3,    0.1]   -- saindo de Sol
  , [0.3,  0.4,    0.3]   -- saindo de Nublado
  , [0.2,  0.3,    0.5]   -- saindo de Chuva
  ]

-- | Probabilidade de ir do estado 'de' para o estado 'para'.
probTransicao :: Matriz -> Estado -> Estado -> Double
probTransicao p de para = (p !! fromEnum de) !! fromEnum para

-- | Uma matriz de transicao e valida (estocastica) quando:
--   1. e quadrada, com uma linha e uma coluna para cada estado;
--   2. todas as probabilidades estao entre 0 e 1;
--   3. cada linha soma 1 (o sistema sempre vai para ALGUM estado).
-- Usamos uma tolerancia (1e-9) porque somas de Double tem erro de arredondamento.
validarMatriz :: Matriz -> Bool
validarMatriz p = quadrada && entre0e1 && linhasSomam1
  where
    n            = length todosEstados
    quadrada     = length p == n && all (\linha -> length linha == n) p
    entre0e1     = all (\x -> x >= 0 && x <= 1) (concat p)
    linhasSomam1 = all (\linha -> abs (sum linha - 1) < 1e-9) p

-- ===================================================================
-- Parte 2: Simulacao
-- ===================================================================

-- | Sorteia o proximo estado, dado o estado atual e um numero u entre 0 e 1.
--
-- Ideia: transformamos a linha do estado atual em probabilidades ACUMULADAS
-- e vemos em qual intervalo o numero u cai.
--
-- Exemplo, saindo de Sol: linha = [0.6, 0.3, 0.1]
--   acumuladas = [0.6, 0.9, 1.0]
--   u em [0.0, 0.6) -> Sol       (tamanho 0.6 = 60%)
--   u em [0.6, 0.9) -> Nublado   (tamanho 0.3 = 30%)
--   u em [0.9, 1.0] -> Chuva     (tamanho 0.1 = 10%)
-- Como u e uniforme, a chance de cair em cada intervalo e exatamente
-- o tamanho do intervalo, ou seja, a probabilidade da matriz.
proximoEstado :: Matriz -> Estado -> Double -> Estado
proximoEstado p atual u = escolher (zip todosEstados acumuladas)
  where
    linha      = p !! fromEnum atual
    acumuladas = scanl1 (+) linha          -- [0.6, 0.3, 0.1] -> [0.6, 0.9, 1.0]

    -- Percorre os intervalos ate achar o primeiro cujo limite e maior que u.
    -- O ultimo estado e escolhido por seguranca, caso a soma acumulada
    -- fique um pouco abaixo de 1 por arredondamento (ex.: 0.9999999999).
    escolher []                = atual   -- nunca acontece com matriz valida
    escolher [(e, _)]          = e
    escolher ((e, limite) : resto)
      | u < limite             = e
      | otherwise              = escolher resto

-- | Gera uma sequencia de n estados, comecando pelo estado inicial.
--
-- A cada passo: sorteia u ~ Uniforme(0,1), escolhe o proximo estado com
-- 'proximoEstado' e continua a partir dele. So o estado ATUAL e usado para
-- decidir o proximo -- essa e a propriedade de Markov no codigo.
--
-- O gerador aleatorio (StdGen) e passado adiante a cada passo: em Haskell
-- nao existe estado global, entao cada sorteio devolve um gerador novo.
simular :: Matriz -> Int -> Estado -> StdGen -> [Estado]
simular p n atual gen
  | n <= 0    = []
  | otherwise = atual : simular p (n - 1) proximo gen'
  where
    (u, gen') = uniformR (0, 1) gen
    proximo   = proximoEstado p atual u

-- ===================================================================
-- Parte 3: Frequencias
-- ===================================================================

-- | Proporcao de vezes que cada estado aparece numa sequencia simulada.
-- Ex.: 100 dias com 40 de Sol -> (Sol, 0.40).
frequencias :: [Estado] -> [(Estado, Double)]
frequencias xs = [ (e, contar e / total) | e <- todosEstados ]
  where
    total   = fromIntegral (length xs)
    contar e = fromIntegral (length (filter (== e) xs))

-- | Distribuicao estacionaria teorica: o vetor pi que satisfaz pi = pi * P
-- (e cujos valores somam 1). Resolvido a mao para esta matriz:
--   pi = (7/18, 6/18, 5/18) ~ (0.389, 0.333, 0.278)
-- Significa: no longo prazo, ~38,9% dos dias sao de Sol, ~33,3% Nublados
-- e ~27,8% de Chuva, nao importa o clima do primeiro dia.
-- (Na parte 4 o programa vai calcular esse vetor sozinho, para conferir.)
piTeorico :: [(Estado, Double)]
piTeorico = zip todosEstados [7 / 18, 6 / 18, 5 / 18]
