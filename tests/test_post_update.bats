#!/usr/bin/env bats
# Tests for hooks/server-side/post-update.
# Invoked directly with ref-name arguments, the same way Git calls it
# after a push has updated refs on the bare server repo.

load helpers

setup() {
  common_setup
  # A bare repo only (no clone) is enough here: the hook is invoked
  # directly rather than via `git push`, so there's no need for the
  # full clone+identity setup init_push_scenario provides for the
  # push-driven tests in test_server_side.bats.
  REMOTE_DIR="$SCRATCH_DIR/remote.git"
  git init -q --bare "$REMOTE_DIR"
  cd "$REMOTE_DIR"
}

teardown() {
  common_teardown
}

@test "post-update reports each updated ref and refreshes server info" {
  run bash "$REPO_ROOT/hooks/server-side/post-update" refs/heads/main refs/heads/feature/x

  [ "$status" -eq 0 ]
  [[ "$output" == *"Ref updated: refs/heads/main"* ]]
  [[ "$output" == *"Ref updated: refs/heads/feature/x"* ]]
  [ -f info/refs ]
}
