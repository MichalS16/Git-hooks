#!/bin/bash
# Shared START/END banner for hook scripts, sourced by every hook that
# prints one, so the "HOOK - <NAME> - START/END" format only needs to be
# defined once instead of copy-pasted (with the name spelled out by hand)
# in every hook file.
#
# Usage: hook_start "PRE-COMMIT" [optional detail]
#        hook_end "PRE-COMMIT"

hook_start() {
  local NAME="$1"
  local DETAIL="${2:-}"
  if [ -n "$DETAIL" ]; then
    echo "HOOK - $NAME - START ($DETAIL):"
  else
    echo "HOOK - $NAME - START:"
  fi
}

hook_end() {
  local NAME="$1"
  echo "HOOK - $NAME - END"
}
