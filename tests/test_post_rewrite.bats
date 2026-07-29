#!/usr/bin/env bats
# Tests for hooks/post-rewrite.

load helpers

setup() {
  common_setup
  init_client_repo -b main
  install_hook post-rewrite
  seed_commit
}

teardown() {
  common_teardown
}

@test "post-rewrite reports the amend that triggered it" {
  run git commit --amend -m "amended message" -q

  [ "$status" -eq 0 ]
  [[ "$output" == *"1 commit(s) rewritten via 'amend'"* ]]
  [[ "$output" != *"force-push"* ]]
}

@test "post-rewrite warns about force-pushing after a rebase rewrites commits" {
  git checkout -q -b feature/rebase-test
  printf 'y = 2\n' > feature-file.py
  git add feature-file.py
  git commit -m "feature commit" -q

  git checkout -q main
  printf 'z = 3\n' > main-file.py
  git add main-file.py
  git commit -m "unrelated main commit" -q

  git checkout -q feature/rebase-test
  run git rebase main

  [ "$status" -eq 0 ]
  [[ "$output" == *"commit(s) rewritten via 'rebase'"* ]]
  [[ "$output" == *"you'll need to force-push"* ]]
}
