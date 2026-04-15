-- | Discovering @.test@ files and their companion @.in@\/@.out@ files.
module SOLTest.Discovery (discoverTests) where

-- Added Control.Monad library for filterM function
import Control.Monad (filterM)
import SOLTest.Types (TestCaseFile (..))
import System.Directory
  ( doesDirectoryExist,
    doesFileExist,
    listDirectory,
  )
import System.FilePath (replaceExtension, takeBaseName, takeExtension, (</>))

-- | Discover all @.test@ files in a directory.
--
-- When @recursive@ is 'True', subdirectories are searched recursively.
-- Returns a list of 'TestCaseFile' records, one per @.test@ file found.
-- The list is ordered by the file system traversal order (not sorted).
discoverTests :: Bool -> FilePath -> IO [TestCaseFile]
discoverTests recursive dir = do
  entries <- listDirectory dir
  let fullPaths = map (dir </>) entries

  -- Get test file paths, known by their extensions .test
  let testFiles = filter (\path -> takeExtension path == ".test") fullPaths
  -- For each test file, create TestCaseFile
  currentTests <- mapM findCompanionFiles testFiles

  if recursive
    then do
      -- Get subdir paths in current folder
      subdirs <- filterM doesDirectoryExist fullPaths
      -- Recursively get testCases lists from subdir
      subdirTestsLists <- mapM (discoverTests recursive) subdirs
      -- Concat list of lists
      let allSubdirTests = concat subdirTestsLists
      return (currentTests ++ allSubdirTests)
    else
      return currentTests

-- | Build a 'TestCaseFile' for a given @.test@ file path, checking for
-- companion @.in@ and @.out@ files in the same directory.
findCompanionFiles :: FilePath -> IO TestCaseFile
findCompanionFiles testPath = do
  let baseName = takeBaseName testPath
      inFile = replaceExtension testPath ".in"
      outFile = replaceExtension testPath ".out"
  hasIn <- doesFileExist inFile
  hasOut <- doesFileExist outFile
  return
    TestCaseFile
      { tcfName = baseName,
        tcfTestSourcePath = testPath,
        tcfStdinFile = if hasIn then Just inFile else Nothing,
        tcfExpectedStdout = if hasOut then Just outFile else Nothing
      }
