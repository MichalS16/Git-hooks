#!/usr/bin/env bats
# Tests for hooks/post-merge.

load helpers

setup() {
  common_setup
  init_client_repo -b main
  install_hook post-merge
  seed_commit
}

teardown() {
  common_teardown
}

@test "post-merge warns when a merge changes a dependency file" {
  git checkout -q -b feature/deps
  printf 'flake8\n' > requirements.txt
  git add requirements.txt
  git commit -m "add dependency" -q

  git checkout -q main
  run git merge feature/deps --no-edit

  [ "$status" -eq 0 ]
  [[ "$output" == *"dependency files changed"* ]]
}

@test "post-merge stays quiet when no dependency file changed" {
  git checkout -q -b feature/unrelated
  printf 'y = 2\n' >> file.py
  git add file.py
  git commit -m "unrelated change" -q

  git checkout -q main
  run git merge feature/unrelated --no-edit

  [ "$status" -eq 0 ]
  [[ "$output" != *"dependency files changed"* ]]
}
