#!/usr/bin/env bats
# Tests for hooks/server-side/reference-transaction.
# Unlike the other server-side hooks, this one works in a plain local
# repo (not a bare/receiving one) - it fires on any ref update, not
# just pushes - so it's installed into a normal client-style repo here.

load helpers

setup() {
  common_setup
  init_client_repo -b main
  install_hook server-side/reference-transaction ".git/hooks"
  seed_commit
}

teardown() {
  common_teardown
}

@test "reference-transaction logs a ref update on an ordinary commit" {
  printf 'y = 2\n' >> file.py
  git add file.py

  run git commit -m "second commit" -q

  [ "$status" -eq 0 ]
  [[ "$output" == *"HOOK - REFERENCE-TRANSACTION"* ]]
  [[ "$output" == *"refs/heads/main"* ]]
}

@test "reference-transaction blocks deleting the protected main branch" {
  git checkout -q -b other

  run git branch -D main

  [ "$status" -ne 0 ]
  [[ "$output" == *"refusing to delete protected branch 'main'"* ]]
}

@test "reference-transaction allows deleting a non-protected branch" {
  git checkout -q -b throwaway
  git checkout -q main

  run git branch -D throwaway

  [ "$status" -eq 0 ]
}
