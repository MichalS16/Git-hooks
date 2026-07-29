#!/bin/bash
# Pure hour-window check used by hooks/pre-auto-gc.
#
# Kept as a plain function taking the hour as an argument (rather than
# reading `date +%H` itself) so it can be tested directly with arbitrary
# hours - no environment-variable seam needed in the hook that calls it.
#
# Usage: in_maintenance_window <current hour, 0-23> <start hour> <end hour>
# Returns 0 (true) if start <= current < end, 1 (false) otherwise.

in_maintenance_window() {
  local CURRENT_HOUR="$1"
  local START_HOUR="$2"
  local END_HOUR="$3"

  [ "$CURRENT_HOUR" -ge "$START_HOUR" ] && [ "$CURRENT_HOUR" -lt "$END_HOUR" ]
}
