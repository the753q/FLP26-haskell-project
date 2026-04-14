module Main where

import CLITest (cliTests)
import DiscoveryTest (discoveryTests)
import ExecutorTest (executorTests)
import FilterTest (filterTests)
import JSONTest (jsonTests)
import ParserTest (parserTests)
import ReportTest (reportTests)
import TypesTest (typesTests)

main :: IO ()
main = do
  putStrLn "Starting AI Tests..."
  cliTests
  discoveryTests
  executorTests
  filterTests
  jsonTests
  parserTests
  reportTests
  typesTests
  putStrLn "\nAll tasks finished."
