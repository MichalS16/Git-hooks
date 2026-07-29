#!/usr/bin/env bats
# Tests for hooks/post-checkout.

load helpers

setup() {
  common_setup
  init_client_repo -b main
  install_hook post-checkout

  mkdir -p hooks
  printf 'x = 1\n' > file.py
  printf '#!/bin/bash\necho hi\n' > hooks/pre-commit
  git add file.py hooks/pre-commit
  git commit -m "initial commit" -q
}

teardown() {
  common_teardown
}

@test "post-checkout warns when hooks/ changed on the branch being switched to" {
  git checkout -q -b feature/hooks-change
  printf '#!/bin/bash\necho changed\n' > hooks/pre-commit
  git add hooks/pre-commit
  git commit -m "change a hook" -q

  git checkout -q main
  run git checkout feature/hooks-change

  [ "$status" -eq 0 ]
  [[ "$output" == *"hooks/ changed on this branch"* ]]
}

@test "post-checkout stays quiet when hooks/ did not change" {
  git checkout -q -b feature/no-hooks-change
  printf 'y = 2\n' >> file.py
  git add file.py
  git commit -m "unrelated change" -q

  git checkout -q main
  run git checkout feature/no-hooks-change

  [ "$status" -eq 0 ]
  [[ "$output" != *"hooks/ changed"* ]]
}

@test "post-checkout exits silently on a file-level checkout (not a branch switch)" {
  # A file checkout (`git checkout -- <file>`) passes IS_BRANCH_CHECKOUT=0,
  # which the hook's early-exit guard (line 17) is supposed to catch -
  # it must not print any banner or run the hooks/-changed check at all.
  printf 'y = 2\n' >> file.py

  run git checkout -- file.py

  [ "$status" -eq 0 ]
  [[ "$output" != *"POST-CHECKOUT"* ]]
  [[ "$output" != *"Switched branches"* ]]
}
