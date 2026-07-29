#!/usr/bin/env bats
# Tests for hooks/server-side/proc-receive.
# Only invoked by Git for refs matching receive.procReceiveRefs
# (configured on the bare server repo); anything else goes through the
# normal pre-receive/update/post-receive path untouched.

load helpers

setup() {
  common_setup
  REMOTE_DIR="$SCRATCH_DIR/remote.git"
  git init -q --bare -b main "$REMOTE_DIR"
  (
    cd "$REMOTE_DIR"
    git config --add receive.procReceiveRefs "refs/for"
    git config --add receive.procReceiveRefs "refs/drafts"
  )
  install_hook server-side/proc-receive "$REMOTE_DIR/hooks"

  cd "$SCRATCH_DIR"
  git clone -q "$REMOTE_DIR" work
  cd work
  git config user.email "test@example.com"
  git config user.name "Test User"
  seed_commit
}

teardown() {
  common_teardown
}

@test "proc-receive accepts a refs/for/* push and reports it as a review" {
  run git push origin "HEAD:refs/for/main"

  [ "$status" -eq 0 ]
  [[ "$output" == *"would open a code review against 'main'"* ]]
}

@test "proc-receive rejects a matched ref it doesn't recognize" {
  run git push origin "HEAD:refs/drafts/main"

  [ "$status" -ne 0 ]
  [[ "$output" == *"proc-receive example only handles refs/for/* pushes"* ]]
}

@test "a normal branch push (not matching receive.procReceiveRefs) bypasses proc-receive entirely" {
  run git push origin main

  [ "$status" -eq 0 ]
  [[ "$output" != *"PROC-RECEIVE"* ]]
}
