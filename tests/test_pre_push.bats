#!/usr/bin/env bats
# Tests for hooks/pre-push.
# Uses a local bare repo as the "remote" so pushes can actually run.

load helpers

setup() {
  common_setup
  init_push_scenario
  install_hook pre-push
  seed_commit
}

teardown() {
  common_teardown
}

@test "pre-push warns when pushing directly to a protected branch" {
  git branch -M main
  run git push origin main

  [ "$status" -eq 0 ]
  [[ "$output" == *"pushing directly to protected branch 'main'"* ]]
}

@test "pre-push stays quiet when pushing a feature branch" {
  git checkout -q -b feature/safe-branch
  run git push origin feature/safe-branch

  [ "$status" -eq 0 ]
  [[ "$output" != *"protected branch"* ]]
}
