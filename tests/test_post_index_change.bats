#!/usr/bin/env bats
# Tests for hooks/post-index-change.

load helpers

setup() {
  common_setup
  init_client_repo -b main
  install_hook post-index-change
  seed_commit
}

teardown() {
  common_teardown
}

@test "post-index-change reports the working tree as updated after a branch checkout" {
  git checkout -q -b other

  run git checkout main

  [ "$status" -eq 0 ]
  [[ "$output" == *"Working tree updated"* ]]
}

@test "post-index-change fires (without error) on a plain commit, which only updates the index" {
  printf 'y = 2\n' >> file.py
  git add file.py

  run git commit -m "second commit" -q

  [ "$status" -eq 0 ]
}
