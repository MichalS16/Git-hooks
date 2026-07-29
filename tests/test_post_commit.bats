#!/usr/bin/env bats
# Tests for hooks/post-commit.
# Run with: bats tests/

load helpers

setup() {
  common_setup
  init_client_repo
  mkdir -p hooks-accessories
  install_hook post-commit
}

teardown() {
  common_teardown
}

@test "post-commit does not rewrite the commit it just ran on" {
  printf 'x = 1\n' > good.py
  git add good.py
  git commit -m "initial" -q

  HASH_BEFORE="$(git rev-parse HEAD)"
  # post-commit already ran once as part of `git commit`; re-run it
  # explicitly and confirm HEAD is unchanged (no amend happened).
  bash .git/hooks/post-commit >/dev/null
  HASH_AFTER="$(git rev-parse HEAD)"

  [ "$HASH_BEFORE" = "$HASH_AFTER" ]
}

@test "post-commit appends commit hash and message to commit-log.txt" {
  printf 'x = 1\n' > good.py
  git add good.py
  git commit -m "log this commit" -q

  [ -f hooks-accessories/commit-log.txt ]
  grep -q "Message: log this commit" hooks-accessories/commit-log.txt
  grep -q "Commit hash: $(git rev-parse HEAD)" hooks-accessories/commit-log.txt
}

@test "post-commit skips notifications when NOTIFICATIONS_ENABLED=false" {
  printf 'x = 1\n' > good.py
  git add good.py

  run git commit -m "notifications check"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Notifications are disabled"* ]]
}

# The remaining tests flip NOTIFICATIONS_ENABLED on in a private copy of
# the hook (the real hook hardcodes it to false on purpose - see README
# "Security Considerations" - so tests exercise a copy instead of the
# installed hook, which would otherwise fire against a real webhook).
enable_notifications() {
  sed 's/NOTIFICATIONS_ENABLED=false/NOTIFICATIONS_ENABLED=true/' \
    "$REPO_ROOT/hooks/post-commit" > .git/hooks/post-commit
  chmod +x .git/hooks/post-commit
}

@test "post-commit reports curl missing when notifications are enabled" {
  enable_notifications
  printf 'SLACK_WEBHOOK_URL="http://example.invalid/slack"\nDISCORD_WEBHOOK_URL="http://example.invalid/discord"\n' > hooks-accessories/secret.txt

  # `command -v curl` must fail to resolve while `bash` and `git` (which
  # the hook calls earlier, for commit metadata) still work.
  local FILTERED_PATH
  FILTERED_PATH="$(path_without_executable curl "bash git")"
  if [ -z "$FILTERED_PATH" ]; then
    skip "curl can't be hidden from PATH without also breaking bash/git here"
  fi

  run env PATH="$FILTERED_PATH" bash .git/hooks/post-commit

  [ "$status" -eq 0 ]
  [[ "$output" == *"'curl' is not installed"* ]]
}

@test "post-commit reports an error when secret.txt is missing" {
  enable_notifications

  printf 'x = 1\n' > good.py
  git add good.py

  # A post-commit hook exiting non-zero does not make `git commit` itself
  # fail - the commit has already happened by the time this hook runs -
  # so only the hook's own error output is checked here, not $status.
  run git commit -m "missing secret check"

  [[ "$output" == *"secret.txt not found"* ]]
}

@test "post-commit reports missing webhook URLs when secret.txt doesn't define them" {
  enable_notifications
  printf '# no webhook vars here\n' > hooks-accessories/secret.txt

  printf 'x = 1\n' > good.py
  git add good.py

  run git commit -m "empty secret check"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Webhook URLs not found in secret.txt"* ]]
}

@test "post-commit sends Slack and Discord notifications when webhooks are configured" {
  enable_notifications
  printf 'SLACK_WEBHOOK_URL="http://127.0.0.1:1/slack"\nDISCORD_WEBHOOK_URL="http://127.0.0.1:1/discord"\n' > hooks-accessories/secret.txt

  # Stub curl so no real network call is made; it just echoes what it was
  # asked to do so the test can tell Slack's call apart from Discord's.
  STUB_DIR="$(mktemp -d)"
  cat > "$STUB_DIR/curl" <<'STUB'
#!/bin/bash
for ARG in "$@"; do
  case "$ARG" in
    *slack*) echo "unsuccessful-response"; exit 0 ;;
    *discord*) echo -n "204"; exit 0 ;;
  esac
done
STUB
  chmod +x "$STUB_DIR/curl"

  printf 'x = 1\n' > good.py
  git add good.py

  run env PATH="$STUB_DIR:$PATH" git commit -m "webhook send check"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Slack notification unsuccessful"* ]]
  [[ "$output" == *"Discord notification sent"* ]]
}
