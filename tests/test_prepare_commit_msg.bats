#!/usr/bin/env bats
# Tests for hooks/prepare-commit-msg.

load helpers

setup() {
  common_setup
  init_client_repo -b main
  install_hook prepare-commit-msg
  seed_commit

  printf 'y = 2\n' >> file.py
  git add file.py
}

teardown() {
  common_teardown
}

@test "prepare-commit-msg prefixes the message with a ticket id from the branch name" {
  git checkout -q -b JEM224-42-fix-hooks
  git commit -m "add feature" -q

  MSG="$(git log -1 --pretty=%s)"
  [ "$MSG" = "JEM224-42: add feature" ]
}

@test "prepare-commit-msg leaves the message untouched when the branch has no ticket id" {
  git checkout -q -b some-random-branch
  git commit -m "add feature" -q

  MSG="$(git log -1 --pretty=%s)"
  [ "$MSG" = "add feature" ]
}

@test "prepare-commit-msg does not double-prefix when amending with a message that already starts with the ticket id" {
  # Git only reports COMMIT_SOURCE="commit" (which the hook's case
  # statement skips) for an editor-based amend, not `--amend -m` - Git
  # gives this hook no way to tell those apart from its arguments, a
  # documented limitation noted in the hook's own comments. So
  # `--amend -m` always runs the same prefix-if-missing logic as a
  # fresh commit; this test checks that idempotency check works even
  # when re-supplying a message that was already prefixed.
  git checkout -q -b JEM224-42-fix-hooks
  git commit -m "add feature" -q

  git commit --amend -m "JEM224-42: add a better feature" -q

  MSG="$(git log -1 --pretty=%s)"
  [ "$MSG" = "JEM224-42: add a better feature" ]
}

@test "prepare-commit-msg does not touch an editor-based amend" {
  # An amend with no -m (editor-based) reports COMMIT_SOURCE="commit",
  # the one case where the hook CAN tell it's an amend and skips
  # entirely - this is the one amend path the hook actually protects.
  git checkout -q -b JEM224-42-fix-hooks
  git commit -m "add feature" -q

  GIT_EDITOR=true git commit --amend -q

  MSG="$(git log -1 --pretty=%s)"
  [ "$MSG" = "JEM224-42: add feature" ]
}

@test "prepare-commit-msg does not prefix a merge commit's message" {
  # A non-fast-forward merge passes COMMIT_SOURCE="merge" with Git's
  # own default merge message already filled in - the hook's case
  # statement must skip that source untouched, on a ticket-named branch
  # where it would otherwise try to prefix the message.
  git checkout -q -b JEM224-42-fix-hooks
  printf 'z = 3\n' > other.py
  git add other.py
  git commit -m "unrelated commit on ticket branch" -q

  git checkout -q main
  printf 'w = 4\n' > main-only.py
  git add main-only.py
  git commit -m "main-only commit" -q

  git merge JEM224-42-fix-hooks --no-edit

  MSG="$(git log -1 --pretty=%s)"
  [[ "$MSG" == "Merge branch"* ]]
  [[ "$MSG" != "JEM224-42:"* ]]
}

@test "prepare-commit-msg does not prefix an editor-finished squash commit" {
  # Git only reports COMMIT_SOURCE="squash" (which the hook's case
  # statement skips) when the squash commit is finished via the editor,
  # with no -m - `git commit -m "..."` after `git merge --squash`
  # reports COMMIT_SOURCE="message" instead, the same "-m hides the
  # real source" limitation documented for --amend. This is the one
  # squash path the hook can actually tell apart and protects.
  git checkout -q -b other-feature
  printf 'z = 3\n' > other.py
  git add other.py
  git commit -m "unrelated commit on other branch" -q

  git checkout -q main
  printf 'w = 4\n' > main-only.py
  git add main-only.py
  git commit -m "main-only commit" -q

  git checkout -q -b JEM224-42-fix-hooks
  git merge --squash other-feature
  GIT_EDITOR=true git commit -q

  MSG="$(git log -1 --pretty=%s)"
  [[ "$MSG" != "JEM224-42:"* ]]
}
