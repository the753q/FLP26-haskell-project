-- | Building the final test report and computing statistics.
--
-- This module assembles a 'TestReport' from the results of test execution,
-- computes aggregate statistics, and builds the per-category success-rate
-- histogram.
module SOLTest.Report
  ( buildReport,
    groupByCategory,
    computeStats,
    computeHistogram,
    rateToBin,
  )
where

import Data.List (find)
import Data.Map.Strict (Map)
import Data.Map.Strict qualified as Map
import SOLTest.Types
  ( CategoryReport (..),
    TestCaseDefinition (..),
    TestCaseReport (..),
    TestCategory,
    TestName,
    TestReport (..),
    TestResult (..),
    TestStats (..),
    UnexecutedReason,
  )

-- ---------------------------------------------------------------------------
-- Top-level report assembly
-- ---------------------------------------------------------------------------

-- | Assemble the complete 'TestReport'.
--
-- Parameters:
--
-- * @discovered@ – all 'TestCaseDefinition' values that were successfully parsed.
-- * @unexecuted@ – tests that were not executed for any reason (filtered, malformed, etc.).
-- * @executionResults@ – 'Nothing' in dry-run mode; otherwise the map of test
--   results keyed by test name.
-- * @selected@ – the tests that were selected for execution (used for stats).
-- * @foundCount@ – total number of @.test@ files discovered on disk.
buildReport ::
  [TestCaseDefinition] ->
  Map String UnexecutedReason ->
  Maybe (Map String TestCaseReport) ->
  [TestCaseDefinition] ->
  Int ->
  TestReport
buildReport discovered unexecuted mResults selected foundCount =
  let mCategoryResults = fmap (groupByCategory selected) mResults
      stats = computeStats foundCount (length discovered) (length selected) mCategoryResults
   in TestReport
        { trDiscoveredTestCases = discovered,
          trUnexecuted = unexecuted,
          trResults = mCategoryResults,
          trStats = stats
        }

-- ---------------------------------------------------------------------------
-- Grouping and category reports
-- ---------------------------------------------------------------------------

-- | Group a flat map of test results into a map of 'CategoryReport' values,
-- one per category.
--
-- The @definitions@ list is used to look up each test's category and points.
groupByCategory ::
  [TestCaseDefinition] ->
  Map String TestCaseReport ->
  Map String CategoryReport
groupByCategory definitions results = mCatReports
  where
    -- Calculate points awarded for test result
    pointsIfPassed :: TestCaseDefinition -> TestCaseReport -> Int
    pointsIfPassed def report =
      if tcrResult report == Passed
        then tcdPoints def
        else 0

    -- Update category report
    updateCatReport :: TestCaseDefinition -> TestCaseReport -> CategoryReport -> CategoryReport
    updateCatReport def report catReport =
      CategoryReport
        { crTotalPoints = crTotalPoints catReport + tcdPoints def,
          crPassedPoints = crPassedPoints catReport + pointsIfPassed def report,
          crTestResults = Map.insert (tcdName def) report (crTestResults catReport)
        }

    -- Initial empty category report
    emptyCatReport :: CategoryReport
    emptyCatReport =
      CategoryReport
        { crTotalPoints = 0,
          crPassedPoints = 0,
          crTestResults = Map.empty
        }

    -- Process each test report and update the accumulator
    step :: Map TestCategory CategoryReport -> TestName -> TestCaseReport -> Map TestCategory CategoryReport
    step acc testName report =
      -- Look for the test definition which corresponds to the reported test entry
      case find (\testDef -> tcdName testDef == testName) definitions of
        Nothing -> acc
        Just def ->
          -- Insert for the given category, the updated category report
          Map.insert category updatedCatReport acc
          where
            -- Get category from our test's definition
            category :: TestCategory
            category = tcdCategory def
            -- Get current report for this category or create a new empty one
            currentCatReport :: CategoryReport
            currentCatReport = case Map.lookup category acc of
              Just catReport -> catReport
              Nothing -> emptyCatReport
            -- Update the report with the new test result
            updatedCatReport :: CategoryReport
            updatedCatReport = updateCatReport def report currentCatReport

    -- Based on the names of the tests from test reports, yield the map of category reports
    mCatReports = Map.foldlWithKey' step Map.empty results

-- ---------------------------------------------------------------------------
-- Statistics
-- ---------------------------------------------------------------------------

-- | Compute the 'TestStats' from available information.
computeStats ::
  -- | Total @.test@ files found on disk.
  Int ->
  -- | Number of successfully parsed tests.
  Int ->
  -- | Number of tests selected after filtering.
  Int ->
  -- | Category reports (Nothing in dry-run mode).
  Maybe (Map String CategoryReport) ->
  TestStats
computeStats foundCount loadedCount selectedCount mCategoryResults =
  TestStats
    { tsFoundTestFiles = foundCount,
      tsLoadedTests = loadedCount,
      tsSelectedTests = selectedCount,
      tsPassedTests = passedTestsCount,
      tsHistogram = histogram
    }
  where
    -- Get number of passed tests, if any were ran
    passedTestsCount = case mCategoryResults of
      Nothing -> 0
      Just mCatResults -> length passedTests
        where
          -- Get all category reports
          catReports = Map.elems mCatResults
          -- Get all tests from every category report
          allTests = concatMap (Map.elems . crTestResults) catReports
          -- Filter all to get only passed tests
          passedTests = filter (\report -> tcrResult report == Passed) allTests

    -- Create histogram if category results are present
    histogram = case mCategoryResults of
      Just mCatResults -> computeHistogram mCatResults
      Nothing -> computeHistogram Map.empty

-- ---------------------------------------------------------------------------
-- Histogram
-- ---------------------------------------------------------------------------

-- | Compute the success-rate histogram from the category reports.
--
-- For each category, the relative pass rate is:
--
-- @rate = passed_test_count \/ total_test_count@
--
-- The rate is mapped to a bin key (@\"0.0\"@ through @\"0.9\"@) and the count
-- of categories in each bin is accumulated. All ten bins are always present in
-- the result, even if their count is 0.
computeHistogram :: Map String CategoryReport -> Map String Int
computeHistogram categories = Map.fromList allBinCounts
  where
    -- Get all category reports
    catReports :: [CategoryReport]
    catReports = Map.elems categories

    -- Get the totals and passes from each category report
    totalList :: [Double]
    totalList = map (fromIntegral . Map.size . crTestResults) catReports
    passList :: [Double]
    passList = map (fromIntegral . Map.size . Map.filter (\r -> tcrResult r == Passed) . crTestResults) catReports

    -- Calculate the pass rate for each pass - total pair
    rates :: [Double]
    rates =
      zipWith
        -- Division by zero check
        ( \passed total ->
            if total == 0 then 0.0 else passed / total
        )
        passList
        totalList

    -- Throw each rate into one of the bins
    bins :: [String]
    bins = map rateToBin rates

    -- Create initial list of tuples of bins and their sizes
    initBinCounts :: [(String, Int)]
    initBinCounts = [("0." ++ show x, 0) | x <- [0 .. 9 :: Int]]

    -- For each bin, calculate its size by counting bin occurences in the bins list
    allBinCounts :: [(String, Int)]
    allBinCounts =
      map
        ( \(name, _) -> (name, length (filter (== name) bins))
        )
        initBinCounts

-- | Map a pass rate in @[0, 1]@ to a histogram bin key.
--
-- Bins are defined as @[0.0, 0.1)@, @[0.1, 0.2)@, ..., @[0.9, 1.0]@.
-- A rate of exactly @1.0@ maps to the @\"0.9\"@ bin.
rateToBin :: Double -> String
rateToBin rate =
  let binIndex = min 9 (floor (rate * 10) :: Int)
      -- Format as "0.N" for bin index N
      whole = binIndex `div` 10
      frac = binIndex `mod` 10
   in show whole ++ "." ++ show frac
