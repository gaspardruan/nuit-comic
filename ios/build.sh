#!/bin/sh

#  build.sh
#  NuitComic
#
#  Created by Gaspard Ruan on 2026/4/24.
#
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
cd "$SCRIPT_DIR"

PROJECT_NAME="nuitcomic"
BUILD_DIR="$SCRIPT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="$REPO_ROOT/build/exported"
PAYLOAD_PATH="$BUILD_DIR/Payload"

# Keep DerivedData between builds, but never package an old archive or IPA.
rm -rf "$ARCHIVE_PATH" "$PAYLOAD_PATH"
rm -f "$EXPORT_PATH/${PROJECT_NAME}.ipa"
mkdir -p "$EXPORT_PATH"

xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
  -scheme "$PROJECT_NAME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=iOS" \
  -onlyUsePackageVersionsFromResolvedFile \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  archive

# An unsigned IPA is a ZIP containing Payload/<app>.app.
mkdir -p "$PAYLOAD_PATH"
ditto "$ARCHIVE_PATH/Products/Applications/${PROJECT_NAME}.app" "$PAYLOAD_PATH/${PROJECT_NAME}.app"
ditto -c -k --keepParent --norsrc "$PAYLOAD_PATH" "$EXPORT_PATH/${PROJECT_NAME}.ipa"
rm -rf "$PAYLOAD_PATH"

printf '\nUnsigned IPA: %s\n' "$EXPORT_PATH/${PROJECT_NAME}.ipa"
du -h "$EXPORT_PATH/${PROJECT_NAME}.ipa"
