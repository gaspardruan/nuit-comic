#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/nuitcomic-search-tests.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT

xcrun swiftc -swift-version 5 \
    "$PROJECT_DIR/nuitcomic/Models/State/AppState.swift" \
    "$PROJECT_DIR/nuitcomic/Models/Store/ComicSearchStore.swift" \
    "$PROJECT_DIR/nuitcomic/Models/Store/StoredComicStore.swift" \
    "$PROJECT_DIR/nuitcomic/Models/Store/StoredComic.swift" \
    "$PROJECT_DIR/nuitcomic/Models/Mapping/Comic.swift" \
    "$PROJECT_DIR/nuitcomic/Models/Mapping/Chapter.swift" \
    "$PROJECT_DIR/nuitcomic/Models/State/ReaderState.swift" \
    "$PROJECT_DIR/nuitcomic/Utils/Utils.swift" \
    "$PROJECT_DIR/nuitcomic/Utils/Localization.swift" \
    "$PROJECT_DIR/Tests/SearchIndexRegressionTests.swift" \
    -o "$TEST_DIR/search-index-tests"

ulimit -c 0
"$TEST_DIR/search-index-tests"
