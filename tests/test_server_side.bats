#!/usr/bin/env bats
# Tests for hooks/server-side/pre-receive and hooks/server-side/update.
# These are installed on a bare "server" repo, not a client's .git/hooks/,
# so tests push into a bare repo that has them installed, exactly as they
# would run for a real `git push`.

load helpers

setup() {
  common_setup
  init_push_scenario
  install_hook server-side/pre-receive "$REMOTE_DIR/hooks"
  install_hook server-side/update "$REMOTE_DIR/hooks"
  seed_commit
  git push -q origin main
}

teardown() {
  common_teardown
}

@test "update rejects a branch name that violates the naming convention" {
  git checkout -q -b random-name
  printf 'y = 2\n' >> file.py
  git add file.py
  git commit -m "second commit" -q

  run git push origin random-name

  [ "$status" -ne 0 ]
  [[ "$output" == *"does not follow the"* ]]
}

@test "update accepts a branch name that follows the naming convention" {
  git checkout -q -b feature/valid-name
  printf 'y = 2\n' >> file.py
  git add file.py
  git commit -m "second commit" -q

  run git push origin feature/valid-name

  [ "$status" -eq 0 ]
}

@test "pre-receive rejects a force-push (non-fast-forward) to main" {
  printf 'y = 2\n' >> file.py
  git add file.py
  git commit -m "second commit" -q
  git push -q origin main

  # Create a divergent history on main and try to force-push it.
  git reset -q --hard HEAD~1
  printf 'z = 3\n' >> file.py
  git add file.py
  git commit -m "divergent commit" -q

  run git push --force origin main

  [ "$status" -ne 0 ]
  [[ "$output" == *"rejecting non-fast-forward push to protected branch"* ]]
}
