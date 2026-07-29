#!/usr/bin/env bats
# Tests for hooks/sendemail-validate.
# Invoked directly with a path to an email file, the same way
# `git send-email` calls it for each outgoing message.

load helpers

setup() {
  common_setup
}

teardown() {
  common_teardown
}

@test "sendemail-validate rejects an email containing conflict markers" {
  EMAIL_FILE="$SCRATCH_DIR/patch.eml"
  cat > "$EMAIL_FILE" <<'EOF'
Subject: [PATCH] example

diff --git a/f.py b/f.py
+<<<<<<< HEAD
+old
+=======
+new
+>>>>>>> feature
EOF

  run bash "$REPO_ROOT/hooks/sendemail-validate" "$EMAIL_FILE"

  [ "$status" -ne 0 ]
  [[ "$output" == *"conflict markers"* ]]
}

@test "sendemail-validate accepts a clean email" {
  EMAIL_FILE="$SCRATCH_DIR/patch.eml"
  cat > "$EMAIL_FILE" <<'EOF'
Subject: [PATCH] example

diff --git a/f.py b/f.py
+new line
EOF

  run bash "$REPO_ROOT/hooks/sendemail-validate" "$EMAIL_FILE"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Email content accepted"* ]]
}
