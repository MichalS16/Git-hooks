#!/usr/bin/env bats
# Tests for hooks/pre-applypatch and hooks/post-applypatch, the two
# hooks bookending applypatch-msg in the `git am` sequence. Exercised
# via `git am`, like tests/test_applypatch_msg.bats.

load helpers

setup() {
  common_setup
  init_client_repo -b main
  install_hook pre-applypatch
  install_hook post-applypatch
  seed_commit
}

teardown() {
  common_teardown
}

make_patch() {
  local CONTENT="$1"
  git checkout -q -b patch-source
  printf '%s\n' "$CONTENT" >> file.py
  git add file.py
  git commit -m "add patch content" -q
  git format-patch -1 --stdout HEAD > "$SCRATCH_DIR/patch.eml"
  git checkout -q main
  git branch -q -D patch-source
}

@test "pre-applypatch and post-applypatch both run during a successful git am" {
  make_patch "y = 2"
  run git am "$SCRATCH_DIR/patch.eml"

  [ "$status" -eq 0 ]
  [[ "$output" == *"HOOK - PRE-APPLYPATCH - START"* ]]
  [[ "$output" == *"HOOK - PRE-APPLYPATCH - END"* ]]
  [[ "$output" == *"HOOK - POST-APPLYPATCH - START"* ]]
  [[ "$output" == *"Patch applied via 'git am'"* ]]
}

@test "pre-applypatch skips the flake8 check when flake8 is not installed" {
  # Shadow `command -v flake8` by putting a stub-only directory with
  # every OTHER tool needed (git, coreutils) ahead of the real PATH,
  # minus flake8 - the same pattern tests/helpers.bash's stub_tool
  # uses, just confirming absence rather than presence.
  local FILTERED_PATH
  FILTERED_PATH="$(path_without_executable flake8 "bash git")"
  if [ -z "$FILTERED_PATH" ]; then
    skip "flake8 can't be hidden from PATH without also breaking bash/git here"
  fi

  make_patch "y = 2"
  run env PATH="$FILTERED_PATH" git am "$SCRATCH_DIR/patch.eml"

  [[ "$output" == *"skipping patch content checks"* ]]
}
