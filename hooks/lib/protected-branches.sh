#!/bin/bash
# Shared "what counts as a protected branch" definition for client-side
# hooks. Sourced by hooks/pre-push and hooks/pre-rebase so the pattern
# only has to be edited in one place.
#
# Server-side hooks (hooks/server-side/pre-receive, update) intentionally
# do NOT source this file: they run on the Git server from the bare
# repository's own hooks/ directory, a different install location and
# trust boundary than a client's .git/hooks/, so they can't literally
# `source` a file that lives in a client checkout. If this pattern
# changes, update the matching regex in those two files as well.

PROTECTED_BRANCHES="^(main|master)$"
