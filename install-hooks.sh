#!/bin/bash
# This script copies hooks from the 'hooks/' folder to the '.git/hooks/' folder.
# To launch the script, open Git Bash, and type in:
    # bash install-hooks.sh

# Copy each hook to the .git/hooks/ directory.
cp -r "./hooks/"* ".git/hooks/"

echo "Git hooks files have been copied from the 'hooks/' folder to the '.git/hooks/' folder."