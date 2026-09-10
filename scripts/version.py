#!/usr/bin/env python3
"""Read the project version, or update it and increment the build number."""

import re
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1] / "nuitcomic.xcodeproj/project.pbxproj"
VERSION_PATTERN = r"MARKETING_VERSION = ([^;]+);"
BUILD_PATTERN = r"CURRENT_PROJECT_VERSION = ([^;]+);"


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
    if len(sys.argv) == 1:
        print(current)
        return

    new = sys.argv[1]
    if version_tuple(new) <= version_tuple(current):
        raise ValueError(f"New version must be greater than {current}.")
    builds = set(re.findall(BUILD_PATTERN, text))
    if len(builds) != 1 or not next(iter(builds)).isdigit():
        raise ValueError("Project configurations must have the same numeric build number.")
    build = int(builds.pop()) + 1
    text = re.sub(VERSION_PATTERN, f"MARKETING_VERSION = {new};", text)
    text = re.sub(BUILD_PATTERN, f"CURRENT_PROJECT_VERSION = {build};", text)
    PROJECT.write_text(text)
    print(new)


if __name__ == "__main__":
    try:
        main()
    except ValueError as error:
        sys.exit(str(error))
