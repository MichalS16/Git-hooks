#!/usr/bin/env bats
# Tests for hooks/fsmonitor-watchman.
# Invoked directly with (version, token) arguments, the same way Git's
# fsmonitor feature calls it.

load helpers

setup() {
  common_setup
}

teardown() {
  common_teardown
}

@test "fsmonitor-watchman echoes back the requested protocol version" {
  run bash "$REPO_ROOT/hooks/fsmonitor-watchman" 2 "1234567890"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "2" ]
}

@test "fsmonitor-watchman falls back to a full scan when watchman isn't installed" {
  # Run with an empty PATH (for the hook process only - bash itself is
  # invoked by absolute path so it doesn't need to resolve itself first)
  # so `command -v watchman` cannot possibly find a real watchman binary,
  # regardless of what's installed on this machine.
  local BASH_BIN
  BASH_BIN="$(command -v bash)"
  run env PATH="" "$BASH_BIN" "$REPO_ROOT/hooks/fsmonitor-watchman" 2 "1234567890"
  [ "$status" -eq 0 ]
  # No file list beyond the version line signals "full scan", not "no
  # changes" - the safe fallback this hook is documented to prefer.
  [ "${#lines[@]}" -eq 1 ]
}
