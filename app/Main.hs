module Main (main) where

import Markov
import System.Random (mkStdGen)
import Text.Printf (printf)

main :: IO ()
main = do
  putStrLn "=== Cadeia de Markov: Clima ==="

  -- ---------------- Parte 1: matriz ----------------
  putStrLn ""
  putStrLn "--- 1. Matriz de transicao ---"
  putStrLn "Linha = hoje, coluna = amanha:"
  mapM_ imprimirLinha todosEstados
  putStrLn ("Matriz valida? " ++ show (validarMatriz matriz))
  putStrLn ("P(Sol -> Chuva) = " ++ show (probTransicao matriz Sol Chuva))
  let invalida = [[0.6, 0.4, 0.1], [0.3, 0.4, 0.3], [0.2, 0.3, 0.5]]
  putStrLn ("Matriz invalida passa? " ++ show (validarMatriz invalida))

  -- ---------------- Parte 2: simulacao ----------------
  putStrLn ""
  putStrLn "--- 2. Como o proximo estado e sorteado (saindo de Sol) ---"
  putStrLn "Acumuladas de Sol: [0.6, 0.9, 1.0]"
  mapM_ (\u -> putStrLn ("  u = " ++ show u ++ " -> " ++ show (proximoEstado matriz Sol u)))
        [0.10, 0.59, 0.60, 0.75, 0.95]

  putStrLn ""
  putStrLn "--- 3. Simulacao de 20 dias (comecando com Sol, seed 42) ---"
  let dias = simular matriz 20 Sol (mkStdGen 42)
  mapM_ (\(d, e) -> putStrLn ("  Dia " ++ show d ++ ": " ++ show e)) (zip [1 :: Int ..] dias)

  -- ---------------- Parte 3: frequencias ----------------
  putStrLn ""
  putStrLn "--- 4. Frequencias observadas x distribuicao estacionaria ---"
  putStrLn "       N |    Sol  Nublado    Chuva | maior erro"
  mapM_ linhaFrequencia [100, 1000, 10000, 100000]
  printf " teorico | %6.3f   %6.3f   %6.3f |\n"
         (snd (piTeorico !! 0)) (snd (piTeorico !! 1)) (snd (piTeorico !! 2))

-- | Simula n dias e imprime a frequencia de cada estado e o maior erro
-- em relacao ao valor teorico.
linhaFrequencia :: Int -> IO ()
linhaFrequencia n = do
  let fs   = map snd (frequencias (simular matriz n Sol (mkStdGen 42)))
      erro = maximum (zipWith (\f t -> abs (f - t)) fs (map snd piTeorico))
  case fs of
    [s, nb, c] -> printf "  %6d | %6.3f   %6.3f   %6.3f |   %.4f\n" n s nb c erro
    _          -> putStrLn "erro: numero de estados inesperado"

-- | Imprime uma linha da matriz com o nome do estado.
imprimirLinha :: Estado -> IO ()
imprimirLinha e =
  putStrLn ("  " ++ show e ++ ": " ++ show [probTransicao matriz e j | j <- todosEstados])
