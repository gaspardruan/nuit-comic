#!/bin/sh
set -eu

case "${1:-}" in
  --help|-h)
    cat <<'HELP'
Usage: android/scripts/setup-signing.sh

Create a persistent local Android release key in ~/.config/nuitcomic.
Existing keys are reused. Back up both android-release.jks and android-signing.env.

For GitHub Actions, configure these repository secrets using this same key:
  ANDROID_KEYSTORE_BASE64    Base64 contents of android-release.jks
  ANDROID_KEYSTORE_PASSWORD ANDROID_KEYSTORE_PASSWORD from android-signing.env
  ANDROID_KEY_ALIAS         ANDROID_KEY_ALIAS from android-signing.env
  ANDROID_KEY_PASSWORD      ANDROID_KEY_PASSWORD from android-signing.env

Keys and passwords must never be committed to the repository.
HELP
    exit 0
    ;;
  "") ;;
  *) echo "Unknown argument. Use --help for usage." >&2; exit 1 ;;
esac

python3 - <<'PY'
import os
from pathlib import Path
import secrets
import shlex
import shutil
import subprocess
import tempfile

directory = Path.home() / ".config/nuitcomic"
directory.mkdir(parents=True, exist_ok=True, mode=0o700)
key = directory / "android-release.jks"
config = directory / "android-signing.env"
if key.exists() != config.exists():
    raise SystemExit("Incomplete signing setup. Restore both the key and environment file from your backup.")
if not key.exists():
    os.umask(0o077)
    password = secrets.token_hex(24)
    environment = {
        "ANDROID_KEYSTORE_PATH": str(key),
        "ANDROID_KEYSTORE_PASSWORD": password,
        "ANDROID_KEY_ALIAS": "nuitcomic",
        "ANDROID_KEY_PASSWORD": password,
    }
    with tempfile.TemporaryDirectory(prefix="signing-", dir=directory) as temporary:
        temporary_key = Path(temporary) / key.name
        subprocess.run([
            "keytool", "-genkeypair", "-noprompt", "-keystore", str(temporary_key),
            "-storetype", "JKS", "-storepass:env", "ANDROID_KEYSTORE_PASSWORD",
            "-keypass:env", "ANDROID_KEY_PASSWORD", "-alias", "nuitcomic",
            "-keyalg", "RSA", "-keysize", "3072", "-validity", "36500",
            "-dname", "CN=NuitComic, OU=Personal Development",
        ], env=dict(os.environ, **environment), check=True)
        temporary_config = Path(temporary) / config.name
        temporary_config.write_text("".join(
            f"export {name}={shlex.quote(value)}\n" for name, value in environment.items()
        ))
        shutil.move(temporary_key, key)
        shutil.move(temporary_config, config)
    print("Created the persistent Android release signing key.")
else:
    print("Using the existing Android release signing key.")
print(f"Back up both files in: {directory}")
print("Use --help for the GitHub Actions signing secret names.")
PY
