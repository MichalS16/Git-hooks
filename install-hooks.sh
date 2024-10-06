#!/bin/bash
# This script copies hooks from the 'hooks/' folder to the '.git/hooks/' folder.

# Copy each hook to the .git/hooks/ directory.
cp -r "./hooks/"* ".git/hooks/"

echo "Git hooks files have been copied from 'hooks/' folder to the '.git/hooks/' folder."