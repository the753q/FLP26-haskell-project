-- | Filtering test cases by include and exclude criteria.
--
-- The filtering algorithm is a two-phase set operation:
--
-- 1. __Include__: if no include criteria are given, all tests are included;
--    otherwise only tests matching at least one include criterion are kept.
--
-- 2. __Exclude__: tests matching any exclude criterion are removed from the
--    included set.
module SOLTest.Filter
  ( filterTests,
    matchesCriterion,
    matchesAny,
    trimFilterId,
  )
where

import Data.Char (isSpace)
import SOLTest.Types

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

-- | Apply a 'FilterSpec' to a list of test definitions.
--
-- Returns a pair @(selected, filteredOut)@ where:
--
-- * @selected@ are the tests that passed both include and exclude checks.
-- * @filteredOut@ are the tests that were removed by filtering.
--
-- The union of @selected@ and @filteredOut@ always equals the input list.
--
-- FLP: Implement this function using @matchesAny@ and @matchesCriterion@.
filterTests ::
  FilterSpec ->
  [TestCaseDefinition] ->
  ([TestCaseDefinition], [TestCaseDefinition])
filterTests spec tests = (selected, filteredOut)
  where
    isRegex = fsUseRegex spec

    -- Check if a test is within the included list of the spec
    isIncluded :: TestCaseDefinition -> Bool
    isIncluded test = null (fsIncludes spec) || matchesAny isRegex (fsIncludes spec) test
    -- Check if a test is within the excluded list of the spec
    isExcluded :: TestCaseDefinition -> Bool
    isExcluded = matchesAny isRegex (fsExcludes spec)

    -- Get all tests included within the spec
    includedTests = foldr (\test rest -> if isIncluded test then test : rest else rest) [] tests
    -- Filter included tests if excluded, as given by the spec
    excludedTests = foldr (\test rest -> if isExcluded test then rest else test : rest) [] includedTests

    selected = excludedTests
    -- Build the 'filteredOut' list as having every test not already in the selected list
    filteredOut = foldr (\test rest -> if test `elem` selected then rest else test : rest) [] tests

-- | Check whether a test matches at least one criterion in the list.
matchesAny :: Bool -> [FilterCriterion] -> TestCaseDefinition -> Bool
matchesAny useRegex criteria test =
  any (matchesCriterion useRegex test) criteria

-- | Check whether a test matches a single 'FilterCriterion'.
--
-- When @useRegex@ is 'False', matching is case-sensitive string equality.
-- When @useRegex@ is 'True', the criterion value is treated as a POSIX
-- regular expression matched against the relevant field(s).
matchesCriterion :: Bool -> TestCaseDefinition -> FilterCriterion -> Bool
matchesCriterion _ test criterion =
  -- Based on criterion type, test whether the given test matches the criteria
  case criterion of
    (ByTag val) -> testByTag val
    (ByCategory val) -> testByCategory val
    (ByAny val) -> testByAny val
  where
    -- Test match for each criterion type
    testByTag val = val `elem` map trimFilterId (tcdTags test)
    testByCategory val = val == trimFilterId (tcdCategory test)
    testByAny val = (val == trimFilterId (tcdName test)) || testByCategory val || testByTag val

-- | Trim leading and trailing whitespace from a filter identifier.
trimFilterId :: String -> String
trimFilterId = reverse . dropWhile isSpace . reverse . dropWhile isSpace
