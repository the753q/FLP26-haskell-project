module ExecutorTest (executorTests) where

import Test.QuickCheck
import Test.QuickCheck.Monadic
import SOLTest.Executor (runDiff)
import System.Exit (ExitCode(..))

prop_executorDiffSameFile :: Property
prop_executorDiffSameFile = monadicIO $ do
  (code, out) <- run (runDiff "flp-fun.cabal" "flp-fun.cabal")
  assert (code == ExitSuccess && null out)

executorTests :: IO ()
executorTests = do
  putStrLn "\n=== Executor Tests ==="
  quickCheck prop_executorDiffSameFile
