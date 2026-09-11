#!/usr/bin/env python3
"""Read the shared release version, or update both apps and their build numbers."""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "ios/nuitcomic.xcodeproj/project.pbxproj"
ANDROID = ROOT / "android/version.properties"
VERSION_PATTERN = r"MARKETING_VERSION = ([^;]+);"
BUILD_PATTERN = r"CURRENT_PROJECT_VERSION = ([^;]+);"
ANDROID_VERSION_PATTERN = r"(?m)^versionName=(.+)$"
ANDROID_BUILD_PATTERN = r"(?m)^versionCode=(.+)$"


def version_tuple(value):
    if not re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", value):
        raise ValueError("Use a version such as 1.2.1 (major.minor.patch).")
    return tuple(map(int, value.split(".")))


def main():
    if len(sys.argv) > 2:
        raise ValueError("Usage: python3 scripts/version.py [NEW_VERSION]")
    text = PROJECT.read_text()
    versions = set(re.findall(VERSION_PATTERN, text))
    if len(versions) != 1:
        raise ValueError("Project configurations must have the same marketing version.")
    current = versions.pop()
    version_tuple(current)
    builds = set(re.findall(BUILD_PATTERN, text))
    if len(builds) != 1 or not next(iter(builds)).isdigit():
        raise ValueError("Project configurations must have the same numeric build number.")
    current_build = int(builds.pop())
    android = ANDROID.read_text()
    if re.findall(ANDROID_VERSION_PATTERN, android) != [current]:
        raise ValueError("iOS and Android must have the same version before releasing.")
    if re.findall(ANDROID_BUILD_PATTERN, android) != [str(current_build)]:
        raise ValueError("iOS and Android must have the same build number before releasing.")
    if not 1 <= current_build <= 2100000000:
        raise ValueError("The shared build number must be within Android's versionCode range.")
    if len(sys.argv) == 1:
        print(current)
        return

    new = sys.argv[1]
    if version_tuple(new) <= version_tuple(current):
        raise ValueError(f"New version must be greater than {current}.")
    build = current_build + 1
    if build > 2100000000:
        raise ValueError("The next build number exceeds Android's versionCode limit.")
    text = re.sub(VERSION_PATTERN, f"MARKETING_VERSION = {new};", text)
    text = re.sub(BUILD_PATTERN, f"CURRENT_PROJECT_VERSION = {build};", text)
    android = re.sub(ANDROID_VERSION_PATTERN, f"versionName={new}", android)
    android = re.sub(ANDROID_BUILD_PATTERN, f"versionCode={build}", android)
    PROJECT.write_text(text)
    ANDROID.write_text(android)
    print(new)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError) as error:
        sys.exit(str(error))
