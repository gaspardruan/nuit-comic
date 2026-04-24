#!/bin/sh

#  build.sh
#  NuitComic
#
#  Created by Gaspard Ruan on 2026/4/24.
#
set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR"

PROJECT_NAME="nuitcomic"
PROJECT_PATH="$SCRIPT_DIR/${PROJECT_NAME}.xcodeproj"
SCHEME="nuitcomic"
CONFIGURATION="Release"
EXPORT_METHOD="${EXPORT_METHOD:-development}"
DERIVED_DATA="$SCRIPT_DIR/build"
ARCHIVE_PATH="$DERIVED_DATA/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="$DERIVED_DATA/exported"
EXPORT_OPTIONS_PLIST="$DERIVED_DATA/ExportOptions.plist"

rm -rf "$DERIVED_DATA"
mkdir -p "$DERIVED_DATA"

# create plist
cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${EXPORT_METHOD}</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
EOF

# archive
xcodebuild -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=iOS" \
  -allowProvisioningUpdates \
  clean archive

# export ipa
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
  -exportPath "$EXPORT_PATH" \
  -allowProvisioningUpdates
