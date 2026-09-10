#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/nuitcomic-reader-tests.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT

# Run the production state machine on macOS without an iOS simulator or network requests.
xcrun swiftc -swift-version 5 \
    "$PROJECT_DIR/nuitcomic/Models/State/ReaderState.swift" \
    "$PROJECT_DIR/nuitcomic/Models/Mapping/Comic.swift" \
    "$PROJECT_DIR/nuitcomic/Models/Mapping/Chapter.swift" \
    "$PROJECT_DIR/nuitcomic/Models/Store/StoredComic.swift" \
    "$PROJECT_DIR/nuitcomic/Utils/Utils.swift" \
    "$PROJECT_DIR/Tests/ReaderImagePrefetcherDouble.swift" \
    "$PROJECT_DIR/Tests/ReaderStateRegressionTests.swift" \
    -o "$TEST_DIR/reader-state-tests"

ulimit -c 0
"$TEST_DIR/reader-state-tests"
