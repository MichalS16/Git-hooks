#!/usr/bin/env bats
# Tests for hooks/server-side/push-to-checkout.
# Unlike the other server-side hooks, this one runs on a non-bare
# server repo with receive.denyCurrentBranch=updateInstead, so the
# "remote" here is a plain (non-bare) init'd repo, not a --bare one.

load helpers

setup() {
  common_setup
  REMOTE_DIR="$SCRATCH_DIR/remote"
  git init -q -b main "$REMOTE_DIR"
  (
    cd "$REMOTE_DIR"
    git config user.email "test@example.com"
    git config user.name "Test User"
    git config receive.denyCurrentBranch updateInstead
  )
  install_hook server-side/push-to-checkout "$REMOTE_DIR/.git/hooks"

  cd "$SCRATCH_DIR"
  git clone -q "$REMOTE_DIR" work
  cd work
  git config user.email "test@example.com"
  git config user.name "Test User"
  seed_commit
  git push -q origin main
}

teardown() {
  common_teardown
}

@test "push-to-checkout updates the server's working tree to match the push" {
  printf 'y = 2\n' >> file.py
  git add file.py
  git commit -m "second commit" -q

  run git push origin main

  [ "$status" -eq 0 ]
  [[ "$output" == *"Working tree updated"* ]]
  grep -q "y = 2" "$REMOTE_DIR/file.py"
}

@test "push-to-checkout refuses to overwrite uncommitted local changes on the server" {
  printf 'uncommitted local edit\n' >> "$REMOTE_DIR/file.py"

  printf 'y = 2\n' >> file.py
  git add file.py
  git commit -m "second commit" -q

  run git push origin main

  [ "$status" -ne 0 ]
  [[ "$output" == *"uncommitted local changes"* ]]
}
