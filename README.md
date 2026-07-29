# Git-hooks (JEM224)

[![Last commit](https://img.shields.io/github/last-commit/MichalS16/Git-hooks)](https://github.com/MichalS16/Git-hooks/graphs/commit-activity)
[![License](https://img.shields.io/github/license/MichalS16/Git-hooks)](LICENSE)

## 🔎 About

This repository is a project from the IES course **JEM224 - Version control with Git**. Its purpose is to get a closer look at **Git Hooks**, with some general theory and an example of their use further with live implementation of *pre-commit* and *post-commit*.

## 👥 Authors [![Contributors](https://img.shields.io/github/contributors/MichalS16/Git-hooks)](https://github.com/MichalS16/Git-hooks/graphs/contributors)

The contributors to this project are:

- [@MichalS16](https://github.com/MichalS16) - Michal Smieško
- [@mrkoubek](https://github.com/mrkoubek) - David Koubek

## 📚 Content ![GitHub repo size](https://img.shields.io/github/repo-size/MichalS16/Git-hooks)

The general theory about **Git Hooks** is in:
[Theory](https://github.com/MichalS16/Git-hooks/blob/main/THEORY.md)

The demonstration of setting up **Git Hooks** is in:
[Examples](https://github.com/MichalS16/Git-hooks/blob/main/examples.ipynb)

## 🎣 Hooks

Our *pre-commit* and *post-commit* hook scripts are the main, fully worked-through implementation in this repo (lint/test/coverage checks, commit logging, optional Slack/Discord notifications). See [`hooks-accessories/commit-log.txt`](hooks-accessories/commit-log.txt) for real terminal output from actually installing and running them, including two commits that were rejected and then fixed.

Beyond those two, [`hooks/`](hooks/) also contains working, smaller example scripts for the rest of Git's client-side hooks, and [`hooks/server-side/`](hooks/server-side/) for the server-side ones - so every hook mentioned in [`THEORY.md`](THEORY.md) has a runnable implementation, not just a description:

| Hook | Where it lives | Fires on | What our example does |
| --- | --- | --- | --- |
| `pre-commit` | `hooks/` | before a commit is created | runs Flake8/Pytest/coverage; logs commit metadata |
| `prepare-commit-msg` | `hooks/` | after the default commit message is generated, before the editor opens | prefixes the message with a ticket ID parsed from the branch name |
| `commit-msg` | `hooks/` | after the message is written, before the commit is created | rejects too-short or `WIP`-only commit messages |
| `post-commit` | `hooks/` | after a commit is created | appends commit hash/message to the log; optional (disabled) Slack/Discord notification |
| `post-checkout` | `hooks/` | after `git checkout`/`git clone` | warns if `hooks/` changed on the branch you just switched to |
| `post-merge` | `hooks/` | after a successful merge/pull | warns if dependency files changed in the merge |
| `pre-rebase` | `hooks/` | before `git rebase` starts | blocks rebasing protected branches (`main`/`master`) |
| `pre-push` | `hooks/` | before a push leaves the local machine | warns when pushing directly to a protected branch |
| `pre-receive` | `hooks/server-side/` | on the **server**, before any ref is updated by a push | rejects non-fast-forward (force) pushes to `main`/`master` |
| `update` | `hooks/server-side/` | on the **server**, once per ref in a push | enforces a branch naming convention |
| `post-rewrite` | `hooks/` | after `git commit --amend` or `git rebase` | reports how many commits were rewritten and warns about needing a force-push |
| `applypatch-msg` | `hooks/` | `git am`'s equivalent of `commit-msg`, before the patch is applied | rejects a patch whose message is too short |
| `pre-auto-gc` | `hooks/` | before Git's unattended automatic garbage collection runs | skips gc outside a defined maintenance window |
| `post-update` | `hooks/server-side/` | on the **server**, after refs have already been updated by a push | reports updated refs and refreshes `info/refs` for the dumb HTTP transport |
| `sendemail-validate` | `hooks/` | before each outgoing message when using `git send-email` | rejects a patch email that still contains unresolved merge-conflict markers |
| `fsmonitor-watchman` | `hooks/` | queried by Git's `core.fsmonitor` feature instead of a full working-tree scan | falls back to "assume everything changed" when the `watchman` daemon isn't installed, rather than a real Watchman query |
| `post-receive` | `hooks/server-side/` | on the **server**, once per push, after all refs are updated | deploys `main`/`master` to a configurable work tree via `git checkout -f` |
| `pre-applypatch` | `hooks/` | `git am`, after a patch is applied to the working tree, before it's committed | runs Flake8 on the applied patch content, if installed |
| `post-applypatch` | `hooks/` | `git am`, after the patch's commit is created | logs the applied patch's hash and message |
| `pre-merge-commit` | `hooks/` | before a non-fast-forward merge creates its merge commit | runs an extra check when merging into a protected branch |
| `post-index-change` | `hooks/` | whenever Git updates the index/working tree as a whole (e.g. checkout, reset) | reports whether the working tree, or only the index, changed |
| `push-to-checkout` | `hooks/server-side/` | on the **server**, when a push updates a non-bare repo's currently checked-out branch | updates the working tree to match, refusing if there are uncommitted local changes |
| `proc-receive` | `hooks/server-side/` | on the **server**, for refs matching `receive.procReceiveRefs` | implements Git's pkt-line proc-receive protocol; accepts `refs/for/*` as a stand-in for "open a review", rejects everything else |
| `reference-transaction` | `hooks/server-side/` | anywhere Git updates a ref (not push-specific) | logs every ref change; refuses to let a transaction delete `main`/`master` |

The hooks under `hooks/server-side/` are installed differently from the rest: they belong in the **bare** repository's `hooks/` directory on the Git server (not a developer's `.git/hooks/`), since only server-side hooks can enforce a policy that can't be bypassed locally (e.g. with `git commit --no-verify`). `install-hooks.sh`'s `cp -r` does copy the `hooks/server-side/` directory along with everything else under `hooks/`, but Git only ever looks for specifically-named files directly inside a `hooks/` directory, never in a subdirectory, so the copies that land at `.git/hooks/server-side/*` are simply inert on a client checkout - installing them for real still means manually copying the individual files into a bare repository's own `hooks/` directory as described above. `reference-transaction` is the one exception worth calling out: unlike the rest of `hooks/server-side/`, it isn't push-specific and works fine in a plain client-side `.git/hooks/` too - it's grouped here because auditing/replicating ref changes is most commonly wanted on a shared server, not because it requires one.

This now covers every hook Git documents, with two narrow, explicitly out-of-scope exceptions: Perforce/Subversion bridge hooks (`p4-*`, `svn`-related), which only apply when Git is used as a front-end for a different version control system, and are irrelevant to demonstrating Git's own workflow.

See [`hooks-accessories/hooks-live-demo-client.txt`](hooks-accessories/hooks-live-demo-client.txt) and [`hooks-accessories/hooks-live-demo-server.txt`](hooks-accessories/hooks-live-demo-server.txt) for real terminal output from every hook above (`pre-commit`/`post-commit` have their own log in [`commit-log.txt`](hooks-accessories/commit-log.txt) instead) - not typed by hand, but copied from actually installing each hook and running the real Git command that triggers it, including the rejections along the way.

A few small pieces of logic that would otherwise be copy-pasted across multiple hook scripts are factored into [`hooks/lib/`](hooks/lib/) and `source`d by the hooks that need them: `protected-branches.sh` (the `main`/`master` pattern used by `pre-push` and `pre-rebase`), `validate-message.sh` (the subject-line length check shared by `commit-msg` and `applypatch-msg`), `banner.sh` (the `HOOK - <NAME> - START/END` messages printed by every client-side hook), and `maintenance-window.sh` (the pure hour-range check used by `pre-auto-gc`, kept as a plain function so it's directly unit-testable without faking the system clock). `install-hooks.sh` copies `hooks/lib/` alongside the hooks themselves. The server-side hooks intentionally keep their own copy of the protected-branch pattern and banner text inline rather than sourcing this directory, since they run from the bare repository on the Git server, not a client checkout, and can't rely on a `lib/` sibling being installed there.

[`hooks-accessories/commit-log.txt`](hooks-accessories/commit-log.txt) is filled in by `pre-commit`/`post-commit` only when those two hooks are actually installed into `.git/hooks/` in a live repo - the Bats test suite deliberately never does this (it runs each hook in a disposable scratch repo instead, so the project's own repo and its hooks are never touched by a test run). If you see a gap in that log's dates, it just means the hooks weren't installed here during that time, not that they're broken.

## 🔒 Security Considerations

Git hooks in `.git/hooks/` run with the full privileges of the committing user, with no sandboxing. Our first working version took a few shortcuts around this that we later hardened towards how hooks are actually run in production. The original variant of each is kept commented out in the scripts for reference.

- **Hook installation is now an explicit, manual step.** The original `pre-commit` called `hooks-accessories/install-hooks.sh` on every commit, which copied `hooks/pre-commit` and `hooks/post-commit` into `.git/hooks/` and immediately made them active. That meant any change merged into `hooks/` - e.g. through a pull request - became auto-installed, privileged, auto-executing code for every contributor on their very next commit, without review. We now require running `bash hooks-accessories/install-hooks.sh` yourself after cloning or after changing anything under `hooks/`, which is how installation is handled by production tooling (e.g. `pre-commit install`, below).
- **No more self-amending commits.** The original `post-commit` staged the updated log file and ran `git commit --amend --no-edit` to fold it into the commit that had just been created, rewriting its hash every time. We now write the commit metadata (author, date) into the log during `pre-commit`, before the commit is created, so it's staged and included normally; `post-commit` only appends the finalized hash/message afterwards, without touching the commit that already exists. This avoids rewriting history and matches how commit metadata is handled in real CI/hook setups.
- **Push automation stays disabled.** A `git push --force-with-lease` line in `post-commit` is intentionally commented out. We keep it in the script only to document that it was tested and works, not as an active feature - automating a force-push from a hook that fires on every commit is too easy to misuse.
- **Outbound notifications stay disabled by default.** The Slack/Discord webhook integration in `post-commit` is a working code example but is gated behind `NOTIFICATIONS_ENABLED=false`, so forking or sharing this repository does not cause it to fire against any real webhook.
- **The webhook secret file is encrypted at rest, not just gitignored.** `hooks-accessories/secret.txt` (where `post-commit` would read `SLACK_WEBHOOK_URL`/`DISCORD_WEBHOOK_URL` from, if notifications were ever enabled) is tracked in Git history, but transparently encrypted using [git-crypt](https://github.com/AGWA/git-crypt): the [`.gitattributes`](.gitattributes) filter rule (`filter=git-crypt diff=git-crypt`) means anyone cloning the repo sees only an encrypted binary blob for that file, both on disk and in every past commit, unless they hold a GPG key that's been explicitly authorized via `git-crypt add-gpg-user`. The [`.git-crypt/`](.git-crypt/) directory holds git-crypt's own bookkeeping (the repo's symmetric key, itself GPG-encrypted per authorized collaborator) - it is git-crypt's internal state, not something to edit by hand.
- **Industry-standard alternative.** Alongside our own hand-written hooks, [`.pre-commit-config.yaml`](.pre-commit-config.yaml) shows the same Flake8/Pytest/coverage checks configured for the [pre-commit framework](https://pre-commit.com) - the tool most real-world teams use instead of raw `.git/hooks/` scripts, since `pre-commit install` only ever installs a small framework-owned dispatcher rather than arbitrary repo content.
- **Script robustness.** Every hook and install script in the repo runs under `set -uo pipefail` (fail fast on unset variables and on pipeline failures). The ones that call an external tool (`flake8`, `pytest`, `coverage`, `curl`, `dos2unix`/`unix2dos`, `watchman`) check `command -v` for it first, printing an actionable error instead of a raw "command not found" if it isn't installed.

## 🧪 Testing the hooks

The hook scripts themselves are tested with [Bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System), the standard testing framework for Bash scripts. Tests live in [`tests/`](tests/), one file per hook, and exercise each hook end-to-end (via a real `git commit`/`git push`/`git am`/etc.) against a disposable scratch Git repository, so the project's own repo is never touched. Common setup/teardown (scratch repo creation, hook installation, bare-remote-plus-clone for push-based hooks) is factored into [`tests/helpers.bash`](tests/helpers.bash) and loaded with `load helpers` at the top of each file, rather than being copy-pasted per test file. `flake8`/`pytest`/`coverage` are stubbed out for the `pre-commit` tests so they check the hook's own control flow (how it reacts to a tool's exit code) rather than depending on those tools being installed; `pre-auto-gc`'s maintenance-window check is factored into a pure `in_maintenance_window(hour, start, end)` function in [`hooks/lib/maintenance-window.sh`](hooks/lib/maintenance-window.sh), unit-tested directly with arbitrary hours, with the hook-level tests stubbing the `date` command on `PATH` rather than relying on an environment-variable override in the hook's own code.

```bash
# Install Bats (e.g. via your package manager, or: npm install -g bats)
bats tests/
```

These tests also run automatically in CI on every push via [`.github/workflows/test-hooks.yml`](.github/workflows/test-hooks.yml).

> **Note:** on Windows/Git Bash (MSYS), Bats occasionally reports a spurious `cygheap read copy failed` / `fork: retry: Resource temporarily unavailable` error from the MSYS `fork()` emulation itself, unrelated to the hooks under test. Re-running the affected test in isolation (`bats tests/test_x.bats`) confirms it passes; this does not occur in CI, which runs on Linux.
