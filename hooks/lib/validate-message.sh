#!/bin/bash
# Shared commit-message-quality check for hooks/commit-msg and
# hooks/applypatch-msg (the `git am` equivalent of commit-msg), so both
# enforce the same minimum-length rule from one place.
#
# Usage: validate_message_length <subject line>
# Prints an error and returns non-zero if the subject line is too short.
# Takes the already-read subject line rather than a file path, so a
# caller that also needs the subject line for its own checks (e.g.
# commit-msg's WIP check) only reads the message file once.

MIN_SUBJECT_LENGTH=10

validate_message_length() {
  local MSG_FIRST_LINE="$1"

  if [ "${#MSG_FIRST_LINE}" -lt "$MIN_SUBJECT_LENGTH" ]; then
    echo "Error: commit message subject line is too short (min $MIN_SUBJECT_LENGTH characters)."
    echo "Got: \"$MSG_FIRST_LINE\""
    return 1
  fi

  return 0
}
