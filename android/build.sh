#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
cd "$REPO_ROOT"

case "${1:-}" in
  --help|-h)
    cat <<'HELP'
Usage: ./android/build.sh

Run Android unit tests and build a signed release APK at build/exported/nuitcomic.apk.
Requires JDK 17 and the Android SDK (ANDROID_HOME or android/local.properties).

Local builds automatically create and reuse ~/.config/nuitcomic/android-release.jks.
Back up this key and android-signing.env; updates must use the same signing key.

To supply an existing key, set all four variables:
  ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD
CI requires these variables and never generates a new signing key.
HELP
    exit 0
    ;;
  "") ;;
  *) echo "Unknown argument. Use --help for usage." >&2; exit 1 ;;
esac

# Android Studio and Gradle can keep a JDK outside macOS's registered Java homes.
if [ -z "${JAVA_HOME:-}" ] && [ "$(uname -s)" = "Darwin" ]; then
  JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || true)
  if [ -z "$JAVA_HOME" ]; then
    JAVA_HOME=$(python3 - <<'PY'
from pathlib import Path
homes = sorted((Path.home() / ".gradle/jdks").glob("*/jdk-17*/Contents/Home"))
print(next((str(home) for home in homes if (home / "bin/java").is_file()), ""))
PY
    )
  fi
  if [ -n "$JAVA_HOME" ]; then
    export JAVA_HOME
    PATH="$JAVA_HOME/bin:$PATH"
    export PATH
  else
    unset JAVA_HOME
  fi
fi

python3 scripts/version.py >/dev/null
if [ -z "${ANDROID_KEYSTORE_PATH:-}" ]; then
  if [ "${CI:-false}" = "true" ] || [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "CI requires a persistent Android release signing key. Configure the ANDROID_KEYSTORE_* and ANDROID_KEY_* secrets." >&2
    exit 1
  fi
  if [ -n "${ANDROID_KEYSTORE_PASSWORD:-}${ANDROID_KEY_ALIAS:-}${ANDROID_KEY_PASSWORD:-}" ]; then
    echo "Set all four Android signing variables, including ANDROID_KEYSTORE_PATH." >&2
    exit 1
  fi
  sh "$SCRIPT_DIR/scripts/setup-signing.sh"
  . "$HOME/.config/nuitcomic/android-signing.env"
fi
: "${ANDROID_KEYSTORE_PASSWORD:?Missing ANDROID_KEYSTORE_PASSWORD}"
: "${ANDROID_KEY_ALIAS:?Missing ANDROID_KEY_ALIAS}"
: "${ANDROID_KEY_PASSWORD:?Missing ANDROID_KEY_PASSWORD}"
if [ ! -f "$ANDROID_KEYSTORE_PATH" ]; then
  echo "The Android release keystore does not exist at ANDROID_KEYSTORE_PATH." >&2
  exit 1
fi
ANDROID_KEYSTORE_PATH=$(python3 -c 'import os; print(os.path.abspath(os.environ["ANDROID_KEYSTORE_PATH"]))')
export ANDROID_KEYSTORE_PATH ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD

# Keep the IPA when building both platforms in the same workspace.
mkdir -p build/exported
rm -f build/exported/nuitcomic.apk
cd "$SCRIPT_DIR"
./gradlew --no-daemon testDebugUnitTest assembleRelease
cp app/build/outputs/apk/release/app-release.apk "$REPO_ROOT/build/exported/nuitcomic.apk"
printf '\nSigned APK: %s/build/exported/nuitcomic.apk\n' "$REPO_ROOT"
du -h "$REPO_ROOT/build/exported/nuitcomic.apk"
