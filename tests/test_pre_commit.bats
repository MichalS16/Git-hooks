#!/usr/bin/env bats
# Tests for hooks/pre-commit.
# Run with: bats tests/
#
# flake8/pytest/coverage are stubbed out as tiny scripts on a private PATH
# directory so these tests exercise the hook's own logic (how it reacts to
# tool exit codes) rather than depending on those tools being installed,
# on any particular version, or on real lint/test results of stub files.

load helpers

setup() {
  common_setup
  init_client_repo
  mkdir -p hooks-accessories
  install_hook pre-commit

  # Stub tools: exit 0 (success / "no issues") by default.
  stub_tool flake8
  stub_tool pytest
  stub_tool coverage
}

teardown() {
  common_teardown
}

@test "pre-commit aborts the commit when flake8 reports an issue" {
  printf '#!/bin/bash\nexit 1\n' > "$STUB_DIR/flake8"

  printf 'x = 1\n' > file.py
  git add file.py

  run git commit -m "should be blocked"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Aborting the commit"* ]]
}

@test "pre-commit allows the commit through when all tools report success" {
  printf 'x = 1\n' > file.py
  git add file.py

  run git commit -m "should succeed"

  [ "$status" -eq 0 ]
}

@test "pre-commit treats pytest exit code 5 (no tests collected) as success" {
  printf '#!/bin/bash\nexit 5\n' > "$STUB_DIR/coverage"

  printf 'x = 1\n' > file.py
  git add file.py

  run git commit -m "no tests found"

  [ "$status" -eq 0 ]
  [[ "$output" == *"No Pytest test was found"* ]]
}

@test "pre-commit aborts the commit when pytest fails with a generic error" {
  printf '#!/bin/bash\nexit 1\n' > "$STUB_DIR/coverage"

  printf 'x = 1\n' > file.py
  git add file.py

  run git commit -m "pytest failure"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Pytest unit tests failed with exit code 1"* ]]
  [[ "$output" == *"Aborting the commit"* ]]
}

@test "pre-commit treats coverage exit code 5 (no data collected) as success" {
  # First `coverage run -m pytest` (line 1 of the stub logic) must succeed
  # so the hook reaches the separate `coverage report` call; make the stub
  # react differently based on its first argument.
  cat > "$STUB_DIR/coverage" <<'STUB'
#!/bin/bash
if [ "$1" = "report" ]; then
  exit 5
fi
exit 0
STUB
  chmod +x "$STUB_DIR/coverage"

  printf 'x = 1\n' > file.py
  git add file.py

  run git commit -m "no coverage data"

  [ "$status" -eq 0 ]
  [[ "$output" == *"No data was collected"* ]]
}

@test "pre-commit aborts the commit when the coverage check fails" {
  cat > "$STUB_DIR/coverage" <<'STUB'
#!/bin/bash
if [ "$1" = "report" ]; then
  exit 2
fi
exit 0
STUB
  chmod +x "$STUB_DIR/coverage"

  printf 'x = 1\n' > file.py
  git add file.py

  run git commit -m "coverage failure"

  [ "$status" -ne 0 ]
  [[ "$output" == *"Coverage check failed with exit code 2"* ]]
  [[ "$output" == *"Aborting the commit"* ]]
}

@test "pre-commit logs commit author/date into commit-log.txt before the commit" {
  printf 'x = 1\n' > file.py
  git add file.py

  run git commit -m "log entry check"

  [ "$status" -eq 0 ]
  [ -f hooks-accessories/commit-log.txt ]
  grep -q "Author: Test User" hooks-accessories/commit-log.txt
}

@test "pre-commit fails with a clear message when a required tool is missing" {
  rm "$STUB_DIR/flake8"

  printf 'x = 1\n' > file.py
  git add file.py

  run git commit -m "missing tool check"

  [ "$status" -ne 0 ]
  [[ "$output" == *"'flake8' is not installed"* ]]
}
