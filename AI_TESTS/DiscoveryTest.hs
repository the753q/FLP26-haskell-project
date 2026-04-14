module DiscoveryTest (discoveryTests) where

import Test.QuickCheck
import Test.QuickCheck.Monadic
import SOLTest.Discovery (discoverTests)

prop_discoveryEmptyDir :: Property
prop_discoveryEmptyDir = monadicIO $ do
  -- running on "." should be safe and return a list
  res <- run (discoverTests False ".")
  assert True

discoveryTests :: IO ()
discoveryTests = do
  putStrLn "\n=== Discovery Tests ==="
  quickCheck prop_discoveryEmptyDir
