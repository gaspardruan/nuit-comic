#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/nuitcomic-image-tests.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT

xcrun swiftc -swift-version 5 -O \
    "$PROJECT_DIR/nuitcomic/Utils/ImageDownsampler.swift" \
    "$PROJECT_DIR/Tests/ImageDownsamplerTests.swift" \
    -o "$TEST_DIR/image-downsampler-tests"

ulimit -c 0
"$TEST_DIR/image-downsampler-tests"
