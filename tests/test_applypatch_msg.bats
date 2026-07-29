#!/usr/bin/env bats
# Tests for hooks/applypatch-msg.
# Exercised via `git am`, which is what actually triggers this hook.

load helpers

setup() {
  common_setup
  init_client_repo -b main
  install_hook applypatch-msg
  seed_commit
}

teardown() {
  common_teardown
}

make_patch() {
  local SUBJECT="$1"
  git checkout -q -b patch-source
  printf 'y = 2\n' >> file.py
  git add file.py
  git commit -m "$SUBJECT" -q
  git format-patch -1 --stdout HEAD > "$SCRATCH_DIR/patch.eml"
  git checkout -q main
  git branch -q -D patch-source
}

@test "applypatch-msg rejects a patch with a too-short subject line" {
  make_patch "fix"
  run git am "$SCRATCH_DIR/patch.eml"

  [ "$status" -ne 0 ]
  [[ "$output" == *"too short"* ]]

  git am --abort 2>/dev/null || true
}

@test "applypatch-msg accepts a patch with a descriptive subject line" {
  make_patch "Add a properly described change"
  run git am "$SCRATCH_DIR/patch.eml"

  [ "$status" -eq 0 ]
}
