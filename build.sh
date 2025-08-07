#!/bin/sh

#  build.sh
#  NuitComic
#
#  Created by Zhongqiu Ruan on 2025/8/8.
#
set -e

PROJECT_NAME="NuitComic"
SCHEME="NuitComic"
CONFIGURATION="Release"
DERIVED_DATA="./build"
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
    <string>development</string>
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
xcodebuild -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=iOS" \
  clean archive

# export ipa
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
  -exportPath "$EXPORT_PATH"
