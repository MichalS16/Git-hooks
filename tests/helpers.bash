#!/usr/bin/env bash
# Shared setup/teardown helpers for the hook test suite (tests/*.bats).
# Load with: load helpers
#
# Every test creates a throwaway Git repo/clone under a temp directory so
# the project's own repo is never touched.

# REPO_ROOT: absolute path to the project root (parent of tests/).
# Must be called first in setup(), since the other helpers assume it's set.
common_setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRATCH_DIR="$(mktemp -d)"
}

# Removes the scratch directory and any sibling dirs (e.g. STUB_DIR) a test
# may have created, and returns to REPO_ROOT so Bats' own bookkeeping isn't
# left inside a directory that's about to be deleted.
common_teardown() {
  cd "$REPO_ROOT"
  rm -rf "$SCRATCH_DIR" "${STUB_DIR:-}"
}

# Initializes a normal (non-bare) repo in SCRATCH_DIR, configures a test
# identity, and cds into it. Used by hooks that install into a single
# client-side .git/hooks/ (commit-msg, pre-commit, pre-rebase, etc.).
init_client_repo() {
  cd "$SCRATCH_DIR"
  git init -q "$@"
  git config user.email "test@example.com"
  git config user.name "Test User"
}

# Copies a hook from the project's hooks/ into the current repo's
# .git/hooks/ (or a given target dir) and makes it executable. Also copies
# hooks/lib/ alongside it (some hooks `source` shared helpers from there
# via a path relative to their own location, e.g. commit-msg, applypatch-msg,
# pre-push, pre-rebase), mirroring what install-hooks.sh's `cp -r` does for
# a real install.
#   install_hook commit-msg
#   install_hook server-side/pre-receive "$REMOTE_DIR/hooks/pre-receive"
install_hook() {
  local HOOK_NAME="$1"
  local TARGET_DIR="${2:-.git/hooks}"
  local TARGET="$TARGET_DIR/$(basename "$HOOK_NAME")"
  mkdir -p "$TARGET_DIR"
  cp "$REPO_ROOT/hooks/$HOOK_NAME" "$TARGET"
  chmod +x "$TARGET"
  if [ -d "$REPO_ROOT/hooks/lib" ]; then
    cp -r "$REPO_ROOT/hooks/lib" "$TARGET_DIR/"
  fi
}

# Sets up a bare "remote" repo plus a clone ("work", already cd'ed into)
# for hooks exercised via `git push` (pre-push, and the server-side hooks
# which install into the bare repo instead of the clone).
init_push_scenario() {
  REMOTE_DIR="$SCRATCH_DIR/remote.git"
  git init -q --bare -b main "$REMOTE_DIR"

  cd "$SCRATCH_DIR"
  git clone -q "$REMOTE_DIR" work
  cd work
  git config user.email "test@example.com"
  git config user.name "Test User"
}

# Commits the given file content as a quick "seed" commit, defaulting to a
# trivial Python file, so hooks that need at least one prior commit (e.g.
# anything relying on HEAD existing) have one.
seed_commit() {
  local FILE="${1:-file.py}"
  local CONTENT="${2:-x = 1}"
  local MESSAGE="${3:-initial commit}"
  printf '%s\n' "$CONTENT" > "$FILE"
  git add "$FILE"
  git commit -m "$MESSAGE" -q
}

# Creates STUB_DIR (if not already set) containing a fake, executable
# version of $1 that runs the body given as $2 (default: `exit 0`), and
# prepends STUB_DIR to PATH so it's found ahead of any real copy of the
# tool. Since STUB_DIR is put first on PATH, this also serves as the way
# to make a tool appear "missing": call stub_tool with a body that isn't
# installed anywhere, or simply `rm "$STUB_DIR/<tool>"` afterwards.
#   stub_tool flake8              # stub exits 0
#   stub_tool flake8 "exit 1"     # stub exits 1
stub_tool() {
  local TOOL="$1"
  local BODY="${2:-exit 0}"
  if [ -z "${STUB_DIR:-}" ]; then
    STUB_DIR="$(mktemp -d)"
    export PATH="$STUB_DIR:$PATH"
  fi
  printf '#!/bin/bash\n%s\n' "$BODY" > "$STUB_DIR/$TOOL"
  chmod +x "$STUB_DIR/$TOOL"
}

# Echoes a PATH with every directory containing an executable named $1
# removed, so `command -v "$1"` fails to resolve it - unless doing so
# would also remove one of the directories in $2 (space-separated list
# of tool names that must keep working, e.g. "bash git"), in which case
# nothing is echoed and the caller should `skip` the test: on some
# platforms a tool needing shared libraries next to it (e.g. Windows
# needs `git`'s own directory present to resolve its DLLs) can be
# colocated with the one being hidden, and no PATH trick fixes that.
#   FILTERED="$(path_without_executable curl "bash git")"
#   [ -n "$FILTERED" ] || skip "curl can't be hidden without breaking git/bash here"
#   run env PATH="$FILTERED" bash some-script
path_without_executable() {
  local NAME="$1"
  local MUST_KEEP="${2:-}"
  local RESULT=""
  local DIR
  while IFS= read -r DIR; do
    [ -z "$DIR" ] && continue
    if [ -e "$DIR/$NAME" ] || [ -e "$DIR/$NAME.exe" ]; then
      for KEEP_TOOL in $MUST_KEEP; do
        if [ -e "$DIR/$KEEP_TOOL" ] || [ -e "$DIR/$KEEP_TOOL.exe" ]; then
          return 0
        fi
      done
      continue
    fi
    RESULT="${RESULT:+$RESULT:}$DIR"
  done < <(printf '%s' "$PATH" | tr ':' '\n')
  printf '%s' "$RESULT"
}
