#!/usr/bin/env bash

# Go to the root of the workspace
cd "$(dirname "$0")/.."

echo "Running AI Tests..."
# cabal exec allows us to use dependencies from the test suite like QuickCheck
cabal exec -- runghc -isrc -iAI_TESTS AI_TESTS/RunAll.hs
