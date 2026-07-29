#!/usr/bin/env bats
# Tests for hooks/pre-rebase.

load helpers

setup() {
  common_setup
  init_client_repo -b main
  install_hook pre-rebase
  seed_commit file.py 'x = 1' "initial commit on main"

  git checkout -q -b feature/test
  printf 'y = 2\n' >> file.py
  git add file.py
  git commit -m "feature commit" -q
}

teardown() {
  common_teardown
}

@test "pre-rebase blocks rebasing the protected main branch" {
  git checkout -q main
  run git rebase feature/test
  [ "$status" -ne 0 ]
  [[ "$output" == *"refusing to rebase protected branch"* ]]
}

@test "pre-rebase allows rebasing a feature branch" {
  git checkout -q feature/test
  run git rebase main
  [ "$status" -eq 0 ]
}
