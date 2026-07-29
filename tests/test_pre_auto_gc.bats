#!/usr/bin/env bats
# Tests for hooks/pre-auto-gc and hooks/lib/maintenance-window.sh.
#
# The maintenance-window check itself is a pure function
# (in_maintenance_window) taking the hour as an argument, so it's unit
# tested directly below with arbitrary hours - no need to fake the clock.
# The hook-level tests confirm pre-auto-gc is wired to that function
# correctly by stubbing `date` on PATH, the one piece of real-world state
# (today's actual hour) a test can't control any other way.

load helpers

setup() {
  common_setup
}

teardown() {
  common_teardown
}

@test "in_maintenance_window is true for an hour inside the window" {
  source "$REPO_ROOT/hooks/lib/maintenance-window.sh"
  run in_maintenance_window 2 1 5
  [ "$status" -eq 0 ]
}

@test "in_maintenance_window is false for an hour outside the window" {
  source "$REPO_ROOT/hooks/lib/maintenance-window.sh"
  run in_maintenance_window 14 1 5
  [ "$status" -ne 0 ]
}

@test "in_maintenance_window treats the start hour as inclusive and the end hour as exclusive" {
  source "$REPO_ROOT/hooks/lib/maintenance-window.sh"
  run in_maintenance_window 1 1 5
  [ "$status" -eq 0 ]
  run in_maintenance_window 5 1 5
  [ "$status" -ne 0 ]
}

@test "pre-auto-gc allows gc to proceed inside the maintenance window" {
  stub_tool date "echo 02"

  run bash "$REPO_ROOT/hooks/pre-auto-gc"
  [ "$status" -eq 0 ]
  [[ "$output" == *"allowing auto-gc to proceed"* ]]
}

@test "pre-auto-gc skips gc outside the maintenance window" {
  stub_tool date "echo 14"

  run bash "$REPO_ROOT/hooks/pre-auto-gc"
  [ "$status" -ne 0 ]
  [[ "$output" == *"skipping auto-gc"* ]]
}
