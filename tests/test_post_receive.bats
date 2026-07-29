#!/usr/bin/env bats
# Tests for hooks/server-side/post-receive.
# Installed on a bare "server" repo, not a client's .git/hooks/, so
# tests push into a bare repo that has it installed, exactly as it
# would run for a real `git push`.

load helpers

setup() {
  common_setup
  init_push_scenario
  install_hook server-side/post-receive "$REMOTE_DIR/hooks"
  seed_commit
}

teardown() {
  common_teardown
}

# Environment variables set on the pushing client are not passed through
# to a server-side hook (it runs in the server's own shell, invoked by
# the receiving `git-receive-pack`), so DEPLOY_WORK_TREE has to be baked
# into the installed hook script itself, unlike client-side hook tests
# which run the hook in-process and can use `env`/`run env`.
set_deploy_work_tree() {
  sed "s|DEPLOY_WORK_TREE:-/var/www/app|DEPLOY_WORK_TREE:-$1|" \
    "$REPO_ROOT/hooks/server-side/post-receive" > "$REMOTE_DIR/hooks/post-receive"
  chmod +x "$REMOTE_DIR/hooks/post-receive"
}

@test "post-receive deploys to the work tree when main is pushed" {
  DEPLOY_DIR="$SCRATCH_DIR/deploy"
  mkdir -p "$DEPLOY_DIR"
  set_deploy_work_tree "$DEPLOY_DIR"

  run git push origin main

  [ "$status" -eq 0 ]
  [[ "$output" == *"Deployment successful"* ]]
  [ -f "$DEPLOY_DIR/file.py" ]
}

@test "post-receive does not deploy when a non-main branch is pushed" {
  DEPLOY_DIR="$SCRATCH_DIR/deploy"
  mkdir -p "$DEPLOY_DIR"
  set_deploy_work_tree "$DEPLOY_DIR"

  git checkout -q -b feature/unrelated
  printf 'y = 2\n' >> file.py
  git add file.py
  git commit -m "feature commit" -q

  run git push origin feature/unrelated

  [ "$status" -eq 0 ]
  [[ "$output" != *"Deploying"* ]]
  [ ! -f "$DEPLOY_DIR/file.py" ]
}

@test "post-receive also deploys master, not just main" {
  DEPLOY_DIR="$SCRATCH_DIR/deploy"
  mkdir -p "$DEPLOY_DIR"
  set_deploy_work_tree "$DEPLOY_DIR"

  git branch -m master

  run git push origin master

  [ "$status" -eq 0 ]
  [[ "$output" == *"Deployment successful"* ]]
  [ -f "$DEPLOY_DIR/file.py" ]
}

@test "post-receive reports a deploy failure without silently succeeding" {
  # Point the deploy target at a path that can never be checked out into
  # (a plain file, not a directory), forcing the checkout to fail. Like
  # post-commit, a post-receive hook's exit code cannot fail the push
  # itself - the push has already been accepted by the time this hook
  # runs - so only the hook's own output is checked, not $status.
  BROKEN_TARGET="$SCRATCH_DIR/not-a-directory"
  printf 'x\n' > "$BROKEN_TARGET"
  set_deploy_work_tree "$BROKEN_TARGET"

  run git push origin main

  [[ "$output" == *"deployment checkout failed"* ]]
  [[ "$output" != *"Deployment successful"* ]]
}

@test "post-receive processes a second ref in the same push even after a prior ref's line was read" {
  # Push two refs in one invocation and confirm the hook's per-ref loop
  # actually reaches and reports on the second one (not just the first),
  # using two non-deploy branches so no real checkout is involved -
  # isolates "does the loop keep reading stdin" from the deploy logic
  # already covered by the tests above.
  git checkout -q -b feature/first
  printf 'a = 1\n' >> file.py
  git add file.py
  git commit -m "first feature commit" -q

  git checkout -q -b feature/second
  printf 'b = 2\n' >> file.py
  git add file.py
  git commit -m "second feature commit" -q

  run git push origin feature/first feature/second

  [ "$status" -eq 0 ]
  run git ls-remote origin
  [[ "$output" == *"refs/heads/feature/first"* ]]
  [[ "$output" == *"refs/heads/feature/second"* ]]
}
