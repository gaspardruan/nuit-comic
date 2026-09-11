#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$SCRIPT_DIR"

if [ -n "$(git status --porcelain)" ]; then
  echo "Commit your code changes first. This script only commits the version change." >&2
  exit 1
fi
BRANCH=$(git symbolic-ref --quiet --short HEAD) || {
  echo "Check out a branch before releasing." >&2
  exit 1
}
OLD_VERSION=$(python3 scripts/version.py)
printf 'Current version: %s\nNew version (e.g. 1.2.1): ' "$OLD_VERSION"
IFS= read -r NEW_VERSION
NEW_VERSION=${NEW_VERSION#v}
TAG="v$NEW_VERSION"
git check-ref-format "refs/tags/$TAG"

# Check the remote before making a version commit or creating a tag.
git fetch origin "refs/heads/$BRANCH:refs/remotes/origin/$BRANCH" --tags
if ! git merge-base --is-ancestor "refs/remotes/origin/$BRANCH" HEAD; then
  echo "Your branch is behind or has diverged from origin. Integrate remote changes first." >&2
  exit 1
fi
if git rev-parse --verify --quiet "refs/tags/$TAG" >/dev/null; then
  printf 'Tag %s already exists.\n' "$TAG" >&2
  exit 1
fi

python3 scripts/version.py "$NEW_VERSION" >/dev/null
git add -- ios/nuitcomic.xcodeproj/project.pbxproj android/version.properties
git commit -m "chore: release $TAG"
git tag -a "$TAG" -m "Release $TAG"

# Push only this branch and release tag, together or not at all.
if ! git push --atomic origin "HEAD:refs/heads/$BRANCH" "refs/tags/$TAG"; then
  echo "Push failed. The local version commit and tag are preserved. Retry with:" >&2
  printf "git push --atomic origin 'HEAD:refs/heads/%s' 'refs/tags/%s'\n" "$BRANCH" "$TAG" >&2
  exit 1
fi
printf '\nPushed %s. GitHub Actions will build the IPA and APK and create one draft release.\n' "$TAG"
