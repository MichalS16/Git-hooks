#!/bin/bash

# This script copies hooks from the 'hooks/' folder to the '.git/hooks/' folder
# and adjusts line endings based on the detected OS environment.
# Can run this script manually: bash hooks-accessories/install-hooks.sh

# Function to detect OS and convert line endings
function convert_line_endings() {
  local PATH_TO_HOOKS=$1  # Get the path passed as the first argument

  # First check if we're in a Bash-like environment with $OSTYPE
  if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* || "$OSTYPE" == "freebsd"* ]]; then
    # Unix-like system (Linux, macOS, FreeBSD)
    echo "Detected Unix-like system. Running dos2unix on hooks..."
    dos2unix $PATH_TO_HOOKS/post-commit
    dos2unix $PATH_TO_HOOKS/pre-commit
  elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Git Bash on Windows or Cygwin/MSYS
    echo "Detected Windows-like system using Git Bash or MSYS. Running unix2dos on hooks..."
    unix2dos $PATH_TO_HOOKS/post-commit
    unix2dos $PATH_TO_HOOKS/pre-commit
  else
    # If $OSTYPE isn't available, check the OS using PowerShell or CMD environment variable
    if [[ -n "$WINDIR" ]]; then
      # We're on Windows (PowerShell/CMD)
      echo "Detected native Windows environment. Running unix2dos on hooks..."
      unix2dos $PATH_TO_HOOKS/post-commit
      unix2dos $PATH_TO_HOOKS/pre-commit
    else
      echo "Unknown OS type. Please manually check your environment."
      exit 1
    fi
  fi
}

# Call the function to convert line endings based on OS
# For the path we're copying from first, in order not to overwrite the line endings of the pre-commit and cause errors
convert_line_endings "./hooks"
echo "Line endings have been adjusted based on the detected OS."

# Copy each hook to the .git/hooks/ directory.
cp -r "./hooks/"* ".git/hooks/"
echo "Git hooks files have been copied from the hooks/ folder to the .git/hooks/ folder."