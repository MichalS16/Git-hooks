#!/bin/bash

# This script copies hooks from the 'hooks/' folder to the '.git/hooks/' folder
# and adjusts line endings based on the detected OS environment.
#
# Run this manually after cloning, and again any time hooks/ changes:
#   bash hooks-accessories/install-hooks.sh
#
# This is intentionally a manual, explicit step and is not invoked
# automatically by any hook. See README "Security Considerations".

set -uo pipefail

# Function to detect OS and convert line endings
function convert_line_endings() {
  local PATH_TO_HOOKS=$1  # Get the path passed as the first argument
  local CONVERTER=""

  # Determine which converter this OS needs: dos2unix on Unix-like
  # systems, unix2dos on anything Windows-like (Git Bash/MSYS/Cygwin, or
  # native Windows detected via $WINDIR when $OSTYPE isn't set).
  if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* || "$OSTYPE" == "freebsd"* ]]; then
    echo "Detected Unix-like system."
    CONVERTER="dos2unix"
  elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || -n "${WINDIR:-}" ]]; then
    echo "Detected Windows-like system (Git Bash, MSYS, Cygwin, or native Windows)."
    CONVERTER="unix2dos"
  else
    echo "Unknown OS type. Please manually check your environment."
    exit 1
  fi

  if ! command -v "$CONVERTER" >/dev/null 2>&1; then
    echo "Error: '$CONVERTER' is not installed or not on PATH. Install it and re-run."
    exit 1
  fi

  echo "Running $CONVERTER on hooks..."
  # Convert every file under hooks/, recursively - not just the hook
  # scripts directly in hooks/, but also hooks/lib/*.sh (sourced by
  # several hooks) and hooks/server-side/* (copied by the cp -r below
  # even though they aren't installed into a client's .git/hooks/) -
  # so nothing that gets copied is left with unconverted line endings.
  local HOOK_FILE
  while IFS= read -r -d '' HOOK_FILE; do
    "$CONVERTER" "$HOOK_FILE"
  done < <(find "$PATH_TO_HOOKS" -type f -print0)
}

# Call the function to convert line endings based on OS
# For the path we're copying from first, in order not to overwrite the line endings of the pre-commit and cause errors
convert_line_endings "./hooks"
echo "Line endings have been adjusted based on the detected OS."

# Copy each hook to the .git/hooks/ directory.
cp -r "./hooks/"* ".git/hooks/"
echo "Git hooks files have been copied from the hooks/ folder to the .git/hooks/ folder."