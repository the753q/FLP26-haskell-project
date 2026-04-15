-- | Discovering @.test@ files and their companion @.in@\/@.out@ files.
module SOLTest.Discovery (discoverTests) where

import SOLTest.Types
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
--
-- FLP: Implement this function. The following functions may come in handy:
--      @doesDirectoryExist@, @takeExtension@, @forM@ or @mapM@,
--      @findCompanionFiles@ (below).
discoverTests :: Bool -> FilePath -> IO [TestCaseFile]
discoverTests recursive dir = do
  entries <- listDirectory dir
  let fullPaths = map (dir </>) entries

  -- Filter paths based on whether we want dirs (True) or files (False)
  let filterPaths dirOrFile = filter (\path -> doesDirectoryExist path == dirOrFile)

  -- Get folder paths
  let getFolderPaths = filterPaths (pure True)
  -- Get test file paths, by getting all file paths ending with .test
  let getFilePaths paths = filter (\path -> takeExtension path == ".test") (filterPaths (pure False) paths)

  -- let recSearch = getFilePaths fullPaths ++ mapM (discoverTests recursive) getFolderPaths
  let allFiles = getFilePaths fullPaths

  -- let allFiles =
  --       if recursive
  --         then recSearch
  --         else getFilePaths fullPaths

  -- For each test file, create TestCaseFile
  tests <- mapM findCompanionFiles allFiles

  let callDiscover :: [TestCaseFile]
  -- callDiscover = foldr(\dir rest -> ) [] (getFolderPaths fullPaths)
  tests2 <- if recursive then callDiscover else pure tests

  return tests2

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
