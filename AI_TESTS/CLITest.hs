module CLITest (cliTests) where

import Test.QuickCheck
import Options.Applicative
import SOLTest.CLI (optionsParserInfo)
import SOLTest.Types

-- A simple test checking if default fields are correctly filled when basic required options are given.
prop_cliParsesTestDir :: String -> Property
prop_cliParsesTestDir dir =
  not (null dir) && not ('-' `elem` dir) ==>
    case execParserPure defaultPrefs optionsParserInfo [dir] of
      Options.Applicative.Success opts -> optTestDir opts == dir
      _ -> False

cliTests :: IO ()
cliTests = do
  putStrLn "\n=== CLI Tests ==="
  quickCheck prop_cliParsesTestDir
