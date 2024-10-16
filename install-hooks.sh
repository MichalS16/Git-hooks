#!/bin/bash

# This script copies hooks from the 'hooks/' folder to the '.git/hooks/' folder
# and adjusts line endings based on the detected OS environment.

# Function to detect OS and convert line endings
function convert_line_endings() {
  # First check if we're in a Bash-like environment with $OSTYPE
  if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* || "$OSTYPE" == "freebsd"* ]]; then
    # Unix-like system (Linux, macOS, FreeBSD)
    echo "Detected Unix-like system. Running dos2unix on hooks..."
    dos2unix .git/hooks/post-commit
    dos2unix .git/hooks/pre-commit
  elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Git Bash on Windows or Cygwin/MSYS
    echo "Detected Windows-like system using Git Bash or MSYS. Running unix2dos on hooks..."
    unix2dos .git/hooks/post-commit
    unix2dos .git/hooks/pre-commit
  else
    # If $OSTYPE isn't available, check the OS using PowerShell or CMD environment variable
    if [[ -n "$WINDIR" ]]; then
      # We're on Windows (PowerShell/CMD)
      echo "Detected native Windows environment. Running unix2dos on hooks..."
      unix2dos .git/hooks/post-commit
      unix2dos .git/hooks/pre-commit
    else
      echo "Unknown OS type. Please manually check your environment."
      exit 1
    fi
  fi
}

# Copy each hook to the .git/hooks/ directory.
cp -r "./hooks/"* ".git/hooks/"
echo "Git hooks files have been copied from the 'hooks/' folder to the '.git/hooks/' folder."

# Call the function to convert line endings based on OS
convert_line_endings

echo "Line endings have been adjusted based on the detected OS."