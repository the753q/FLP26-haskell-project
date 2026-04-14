module TypesTest (typesTests) where

import Test.QuickCheck
import SOLTest.Types

prop_filterCriterionValue_Any :: String -> Bool
prop_filterCriterionValue_Any s = filterCriterionValue (ByAny s) == s

prop_filterCriterionValue_Tag :: String -> Bool
prop_filterCriterionValue_Tag s = filterCriterionValue (ByTag s) == s

prop_filterCriterionValue_Category :: String -> Bool
prop_filterCriterionValue_Category s = filterCriterionValue (ByCategory s) == s

typesTests :: IO ()
typesTests = do
  putStrLn "\n=== Types Tests ==="
  quickCheck prop_filterCriterionValue_Any
  quickCheck prop_filterCriterionValue_Tag
  quickCheck prop_filterCriterionValue_Category
