#!/usr/bin/env bats
# Tests for hooks/commit-msg.

load helpers

setup() {
  common_setup
  init_client_repo
  install_hook commit-msg

  printf 'x = 1\n' > file.py
  git add file.py
}

teardown() {
  common_teardown
}

@test "commit-msg rejects a message that is too short" {
  run git commit -m "fix"
  [ "$status" -ne 0 ]
  [[ "$output" == *"too short"* ]]
}

@test "commit-msg rejects a WIP placeholder message" {
  run git commit -m "WIP: placeholder"
  [ "$status" -ne 0 ]
  [[ "$output" == *"starts with 'WIP'"* ]]
}

@test "commit-msg accepts a descriptive message" {
  run git commit -m "Add initial project scaffolding"
  [ "$status" -eq 0 ]
}
