#!/usr/bin/env python3
"""Exercise releases against temporary local Git remotes, never GitHub."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
PROJECT = "ios/nuitcomic.xcodeproj/project.pbxproj"
ANDROID = "android/version.properties"


class ReleaseWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="nuitcomic-release-tests-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.repo = self.base / "work"
        self.remote = self.base / "origin.git"
        self.repo.mkdir()
        # Ignore personal signing, hooks, and push settings in these test repos.
        self.env = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")
        self.git("init", "--bare", str(self.remote))
        self.git("init", "-b", "main")
        self.git("config", "user.name", "Release Test")
        self.git("config", "user.email", "release-test@example.invalid")
        for name in ("release.sh", "scripts/version.py"):
            destination = self.repo / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / name, destination)
        (self.repo / PROJECT).parent.mkdir(parents=True)
        (self.repo / PROJECT).write_text(
            "MARKETING_VERSION = 1.2.0;\nCURRENT_PROJECT_VERSION = 1;\n" * 2
        )
        (self.repo / ANDROID).parent.mkdir()
        (self.repo / ANDROID).write_text("versionName=1.2.0\nversionCode=1\n")
        self.git("add", ".")
        self.git("commit", "-m", "Initial")
        self.git("remote", "add", "origin", str(self.remote))
        self.git("push", "-u", "origin", "main")
        self.initial = self.git("rev-parse", "HEAD")
        self.original = (self.repo / PROJECT).read_text()
        self.original_android = (self.repo / ANDROID).read_text()

    def git(self, *args):
        return subprocess.check_output(
            ["git", *args], cwd=self.repo, env=self.env, stderr=subprocess.PIPE, text=True
        ).strip()

    def release(self, version="1.2.1"):
        return subprocess.run(
            ["sh", "release.sh"], input=version + "\n", cwd=self.repo,
            env=self.env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
        )

    def assert_unchanged(self):
        self.assertEqual(self.git("rev-parse", "HEAD"), self.initial)
        self.assertEqual((self.repo / PROJECT).read_text(), self.original)
        self.assertEqual((self.repo / ANDROID).read_text(), self.original_android)
        self.assertEqual(self.git("--git-dir", str(self.remote), "rev-parse", "main"), self.initial)

    def test_release_only_commits_version_and_pushes_selected_tag(self):
        self.git("tag", "unrelated-local-tag")
        result = self.release("v1.2.1")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("Current version: 1.2.0", result.stdout)
        text = (self.repo / PROJECT).read_text()
        self.assertEqual(text.count("MARKETING_VERSION = 1.2.1;"), 2)
        self.assertEqual(text.count("CURRENT_PROJECT_VERSION = 2;"), 2)
        self.assertEqual((self.repo / ANDROID).read_text(), "versionName=1.2.1\nversionCode=2\n")
        self.assertEqual(set(self.git("diff", "--name-only", "HEAD^", "HEAD").splitlines()), {PROJECT, ANDROID})
        self.assertEqual(self.git("status", "--porcelain"), "")
        self.assertEqual(self.git("cat-file", "-t", "v1.2.1"), "tag")
        self.assertEqual(self.git("--git-dir", str(self.remote), "rev-parse", "v1.2.1^{}"), self.git("rev-parse", "HEAD"))
        self.assertEqual(self.git("--git-dir", str(self.remote), "tag"), "v1.2.1")

    def test_dirty_worktree_is_rejected(self):
        for staged in (False, True):
            with self.subTest(staged=staged):
                (self.repo / "code.swift").write_text("// Work in progress\n")
                if staged:
                    self.git("add", "code.swift")
                result = self.release()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Commit your code changes first", result.stdout)
                self.assert_unchanged()

    def test_invalid_or_non_increasing_versions_do_not_modify_project(self):
        for version in ("", "1.2.0", "1.1.9", "1.2", "01.2.1", "vv1.2.1", "1.2.1-beta"):
            with self.subTest(version=version):
                result = self.release(version)
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assert_unchanged()
                self.assertEqual(self.git("tag"), "")

    def test_remote_tag_collision_is_rejected(self):
        self.git("--git-dir", str(self.remote), "tag", "v1.2.1", "main")
        result = self.release()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("already exists", result.stdout)
        self.assert_unchanged()

    def test_remote_ahead_is_rejected(self):
        self.git("commit", "--allow-empty", "-m", "Remote change")
        self.git("push", "origin", "main")
        self.git("reset", "--hard", self.initial)
        result = self.release()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("behind or has diverged", result.stdout)
        self.assertEqual(self.git("rev-parse", "HEAD"), self.initial)
        self.assertEqual((self.repo / PROJECT).read_text(), self.original)
        self.assertEqual(self.git("tag"), "")

    def test_rejected_push_is_atomic_and_can_be_retried(self):
        hook = self.remote / "hooks/update"
        hook.write_text('#!/bin/sh\n[ "$1" != "refs/heads/main" ]\n')
        hook.chmod(0o755)
        result = self.release()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("local version commit and tag are preserved", result.stdout)
        self.assertEqual(self.git("--git-dir", str(self.remote), "rev-parse", "main"), self.initial)
        self.assertEqual(self.git("--git-dir", str(self.remote), "tag"), "")
        self.assertEqual(self.git("rev-parse", "v1.2.1^{}"), self.git("rev-parse", "HEAD"))
        hook.unlink()
        self.git("push", "--atomic", "origin", "HEAD:refs/heads/main", "refs/tags/v1.2.1")
        self.assertEqual(self.git("--git-dir", str(self.remote), "rev-parse", "main"), self.git("rev-parse", "HEAD"))

    def test_detached_head_is_rejected(self):
        self.git("checkout", "--detach")
        result = self.release()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Check out a branch", result.stdout)
        self.assert_unchanged()

    def test_inconsistent_configuration_versions_are_rejected(self):
        project = self.repo / PROJECT
        project.write_text(self.original.replace("1.2.0", "1.3.0", 1))
        result = subprocess.run(
            ["python3", "scripts/version.py", "1.4.0"], cwd=self.repo,
            capture_output=True, text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("same marketing version", result.stderr)
        self.assertEqual(project.read_text(), self.original.replace("1.2.0", "1.3.0", 1))
        self.assertEqual((self.repo / ANDROID).read_text(), self.original_android)

    def test_platform_version_mismatch_prevents_reads_and_updates(self):
        for content, message in (
            ("versionName=1.1.0\nversionCode=1\n", "same version"),
            ("versionName=1.2.0\nversionCode=2\n", "same build number"),
            ("versionName=1.2.0\nversionName=1.2.0\nversionCode=1\n", "same version"),
            ("versionName=1.2.0\nversionCode=abc\n", "same build number"),
        ):
            for arguments in ([], ["1.3.0"]):
                with self.subTest(content=content, arguments=arguments):
                    (self.repo / ANDROID).write_text(content)
                    result = subprocess.run(
                        ["python3", "scripts/version.py", *arguments], cwd=self.repo,
                        capture_output=True, text=True,
                    )
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn(message, result.stderr)
                    self.assertEqual((self.repo / PROJECT).read_text(), self.original)
                    self.assertEqual((self.repo / ANDROID).read_text(), content)

    def test_android_build_number_limit_prevents_partial_update(self):
        project = self.original.replace("CURRENT_PROJECT_VERSION = 1;", "CURRENT_PROJECT_VERSION = 2100000000;")
        android = "versionName=1.2.0\nversionCode=2100000000\n"
        (self.repo / PROJECT).write_text(project)
        (self.repo / ANDROID).write_text(android)
        result = subprocess.run(
            ["python3", "scripts/version.py", "1.3.0"], cwd=self.repo,
            capture_output=True, text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("versionCode limit", result.stderr)
        self.assertEqual((self.repo / PROJECT).read_text(), project)
        self.assertEqual((self.repo / ANDROID).read_text(), android)

    def test_missing_android_version_does_not_modify_ios(self):
        (self.repo / ANDROID).unlink()
        result = subprocess.run(
            ["python3", "scripts/version.py", "1.3.0"], cwd=self.repo,
            capture_output=True, text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.repo / PROJECT).read_text(), self.original)


if __name__ == "__main__":
    unittest.main()
