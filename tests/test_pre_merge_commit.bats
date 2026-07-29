#!/usr/bin/env bats
# Tests for hooks/pre-merge-commit.

load helpers

setup() {
  common_setup
  init_client_repo -b main
  install_hook pre-merge-commit
  seed_commit file.py 'x = 1' "initial commit"
}

teardown() {
  common_teardown
}

@test "pre-merge-commit runs extra checks when merging into a protected branch" {
  git checkout -q -b feature
  printf 'y = 2\n' > other.py
  git add other.py
  git commit -m "feature commit" -q

  # Give main its own commit so the merge below is non-fast-forward and
  # actually produces a merge commit - a fast-forward merge never
  # triggers pre-merge-commit at all (covered by the test below).
  git checkout -q main
  printf 'z = 3\n' > main-only.py
  git add main-only.py
  git commit -m "unrelated main commit" -q

  run git merge feature --no-edit

  [ "$status" -eq 0 ]
  [[ "$output" == *"Merging into protected branch 'main'"* ]]
}

@test "pre-merge-commit stays quiet when merging into a non-protected branch" {
  git checkout -q -b integration
  printf 'z = 3\n' > integration-only.py
  git add integration-only.py
  git commit -m "integration-only commit" -q

  git checkout -q main
  git checkout -q -b feature
  printf 'y = 2\n' > other.py
  git add other.py
  git commit -m "feature commit" -q

  git checkout -q integration

  run git merge feature --no-edit

  [ "$status" -eq 0 ]
  [[ "$output" != *"Merging into protected branch"* ]]
}

@test "a fast-forward merge does not trigger pre-merge-commit at all" {
  git checkout -q -b feature
  printf 'y = 2\n' > other.py
  git add other.py
  git commit -m "feature commit" -q

  git checkout -q main

  run git merge feature --ff-only

  [ "$status" -eq 0 ]
  [[ "$output" != *"PRE-MERGE-COMMIT"* ]]
}
