module JSONTest (jsonTests) where

import Test.QuickCheck
import Data.Aeson (encode)
import qualified Data.ByteString.Lazy.Char8 as B
import SOLTest.Types
import SOLTest.JSON ()

prop_jsonParseOnly :: Bool
prop_jsonParseOnly = B.unpack (encode ParseOnly) == "0"

prop_jsonExecuteOnly :: Bool
prop_jsonExecuteOnly = B.unpack (encode ExecuteOnly) == "1"

prop_jsonCombined :: Bool
prop_jsonCombined = B.unpack (encode Combined) == "2"

jsonTests :: IO ()
jsonTests = do
  putStrLn "\n=== JSON Tests ==="
  quickCheck prop_jsonParseOnly
  quickCheck prop_jsonExecuteOnly
  quickCheck prop_jsonCombined
