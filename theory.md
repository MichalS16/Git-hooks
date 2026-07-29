# Theory of Git Hooks

> Every hook described below has a small, working example script in this repo: client-side hooks in [`hooks/`](hooks/), server-side hooks in [`hooks/server-side/`](hooks/server-side/). See the table in [README.md](README.md#-hooks) for a one-line summary of what each example does.

## Introduction

**Git hooks** are powerful scripts that allow you to automate tasks and enforce policies at key points during the Git workflow. These scripts are triggered by specific Git actions such as making a commit, pushing changes, or merging branches. By leveraging Git hooks, developers can enhance productivity by automating tasks such as running tests, checking for code quality, or verifying commit messages, ensuring the repository maintains a high standard of code quality and consistency.

Git hooks can be used both locally and on the server-side (on the Git server), offering flexibility in how they are implemented. They help to enforce coding standards, run scripts before or after certain Git operations, and even enable integration with external systems such as continuous integration or deployment pipelines.

For teams working collaboratively, Git hooks act as a safeguard, preventing bad code from being pushed into the shared repository by automating checks and balances. This ensures that only validated, formatted, and properly documented code makes it into the shared codebase, saving time and effort in code reviews or debugging later on.

## Why Use Git Hooks?

By using Git hooks, developers can automate a wide range of tasks that are often manual and prone to errors. These hooks allow for seamless integration of quality control, testing, and deployment processes directly into the version control workflow. By utilizing Git hooks, teams can ensure a consistent development experience and reduce the likelihood of mistakes. Here are some key reasons why Git hooks are invaluable to modern development practices:

- **Automate Repetitive Tasks**: Hooks can run linting tools, format code, or update documentation automatically, ensuring consistency across the codebase.

- **Enforce Standards**: By running scripts during commits or pushes, you can enforce coding standards and prevent poorly formatted or untested code from being pushed to the repository.

- **Trigger External Actions**: Hooks can trigger continuous integration and continuous deployment (CI/CD) pipelines, send notifications, or deploy code automatically after a successful push.

## Types of Git Hooks

Git hooks are categorized into two main types based on where they are executed:

1. **Client-Side Hooks**: These run on the developer's local machine and are triggered by actions like commits and merges. They are ideal for enforcing code quality and automating tasks during the development process.

2. **Server-Side Hooks**: These run on the Git server and are triggered by actions such as pushes or merges. They are used to enforce policies across the repository, validate incoming changes, and automate deployment processes.

Each type of hook plays a crucial role in enhancing workflow efficiency and maintaining code quality throughout the development lifecycle.

## How Hooks Actually Behave

A few mechanics apply to every hook and are easy to miss if you've only seen individual examples:

- **Exit codes decide the outcome, and only for hooks that run *before* the thing they're checking.** A non-zero exit from `pre-commit`, `commit-msg`, `pre-push`, `pre-receive`, `update`, `pre-rebase`, `pre-merge-commit`, or `pre-auto-gc` aborts the operation - the commit is never made, the push is rejected, and so on. Hooks that run *after* the fact - `post-commit`, `post-checkout`, `post-merge`, `post-receive`, `post-update`, `post-rewrite`, `post-applypatch` - can't undo anything that already happened; their exit code is purely informational (Git logs it but doesn't act on it). This repo's own `hooks/post-commit` and `hooks/server-side/post-receive` deliberately keep this in mind: neither one tries to use `exit 1` to "cancel" a commit or push that has already completed.

- **`git clone` does not copy hooks.** Hooks live in `.git/hooks/`, which is local, untracked repository metadata - not part of the repository's tracked content that clone/fetch/pull transfer. This is exactly why a project that wants everyone to use the same hooks needs an explicit installation step (this repo's `hooks-accessories/install-hooks.sh`, or a tool like the `pre-commit` framework) rather than being able to rely on the hooks simply arriving with the clone.

- **`.git/hooks/` starts out full of `*.sample` files.** Every fresh `git init`/`git clone` populates `.git/hooks/` with a `<hookname>.sample` file for each hook Git supports - disabled by default (Git only runs a file named exactly `<hookname>`, with no extension, and only if it's executable). This is most people's first encounter with hooks, and it's also why simply dropping a same-named executable file into that directory is enough to activate a hook - no registration step, no config file to edit.

- **`--no-verify` bypasses client-side verification hooks.** Most commands with a client-side verification hook (`git commit`, `git push`, and a few others) accept `--no-verify` to skip it entirely - a legitimate escape hatch for a false-positive check or an emergency commit, not a bug. This is also *why* server-side hooks matter for anything that must be enforced for real: they can't be bypassed with a client-side flag, since they run on the server regardless of what the pushing client asked for (see README "Security Considerations" for how this repo treats that distinction).

- **Git only runs one script per hook name - there's no built-in chaining.** If two different tools each want to react to `pre-commit`, only the last one to overwrite `.git/hooks/pre-commit` actually runs; Git has no mechanism to run several scripts for the same event. This is precisely the gap frameworks like [pre-commit](https://pre-commit.com) (see README, and this repo's own [`.pre-commit-config.yaml`](.pre-commit-config.yaml)) exist to fill: they install one small dispatcher script as the real hook, which then reads a config file and runs as many checks as it lists, in effect adding the chaining Git itself doesn't provide.

### Client-Side Hooks

Client-side hooks are triggered by actions performed by developers in their local environment, such as committing code or merging branches. These hooks are essential for catching issues early, ensuring code quality before changes are pushed to the central repository. Key examples include:

- **pre-commit**: Executes before a commit is finalized, allowing you to run linters, format code, or perform checks. This ensures that only code meeting your standards is committed.

- **prepare-commit-msg**: Provides an opportunity to auto-populate or modify commit messages before they are saved. This can enforce message formatting or include relevant issue keys automatically.

- **post-commit**: Runs immediately after a commit is made, making it ideal for tasks like sending notifications, updating logs, or cleaning up temporary files.

By implementing these hooks, developers can enhance their workflows and maintain a high standard of code quality.

### Server-Side Hooks

Server-side hooks are triggered on the Git server and play a crucial role in collaboration, ensuring consistency and quality across the team. They help enforce policies and automate processes related to code management. Key examples include:

- **pre-receive**: Executes before any changes are pushed to the repository. This hook is useful for validating commit messages, enforcing coding standards, or running tests to ensure code quality before it is accepted.

- **post-receive**: Runs immediately after changes are pushed to the repository. This hook is commonly used to trigger continuous integration (CI) pipelines or deployment scripts, automating the process of building, testing, and deploying code to production environments.

For further reading on the different types of Git hooks and their applications, you can refer to the following sources:

- [Git Hooks Documentation](https://git-scm.com/docs/githooks)

- [Atlassian Git Hooks Tutorial](https://www.atlassian.com/git/tutorials/git-hooks)

## Git Hooks vs. GitHub Actions

### Historical Development

**Git Hooks** were introduced as part of Git's core functionality from its inception in 2005. They provide a way to execute scripts at various points in the Git workflow, allowing developers to customize their development processes directly within their local repositories. Git hooks are executed locally on a developer's machine or on a Git server, which gives them the ability to enforce coding standards, automate testing, and perform pre- or post-commit actions.

On the other hand, **GitHub Actions** was launched by GitHub in November 2019. It revolutionized CI/CD workflows by allowing developers to automate tasks directly within the GitHub platform. GitHub Actions enables users to define workflows that can be triggered by various GitHub events, such as push, pull request, or issue creation. This feature integrates seamlessly with other GitHub functionalities, allowing for automation of testing, building, and deployment processes.

### Comparison

| Feature                  | Git Hooks                                                        | GitHub Actions                                                           |
|--------------------------|------------------------------------------------------------------|--------------------------------------------------------------------------|
| **Execution Environment**| Local (developer's machine or server)                            | Cloud-based (within GitHub)                                              |
| **Triggering Events**    | Specific Git operations (commit, merge, push)                    | Various GitHub events (push, pull request, issue)                        |
| **Setup Complexity**     | Requires manual setup in `.git/hooks` directory                  | Configured via YAML files in the repository                              |
| **Scalability**          | Limited to the local environment and can be cumbersome for teams | Highly scalable; designed for collaborative CI/CD workflows              |
| **Integration**          | Works primarily with Git and local scripts                       | Integrates with various third-party services, APIs, and tools            |
| **Flexibility**          | Customized for local workflows, but limited to Git actions       | Highly customizable workflows with a vast ecosystem of actions available |
| **Visibility**           | Local to the developer; less visibility for the team             | Actions and results are visible on GitHub, fostering collaboration       |

### Current Relevance

In today's development landscape, both Git Hooks and GitHub Actions serve essential but distinct roles.

- **Git Hooks** remain valuable for local development environments, allowing developers to enforce coding standards and run tests before committing code. They are particularly useful in smaller teams or projects where quick validation and immediate feedback are crucial. However, they require setup on each developer's machine, which can lead to inconsistencies if not managed properly.

- **GitHub Actions**, on the other hand, has gained significant traction in modern development practices, especially in larger teams and projects. They offer a robust solution for CI/CD, enabling automated testing, building, and deployment workflows directly on GitHub. Their cloud-based nature allows for greater scalability and collaboration, as teams can create shared workflows that are visible to all contributors.

### Conclusion

Both Git Hooks and GitHub Actions provide powerful tools for automating tasks and ensuring code quality. While Git Hooks are excellent for local validation and immediate feedback, GitHub Actions offer a comprehensive platform for CI/CD workflows that are essential in today's collaborative development environments. Depending on the project's needs, developers may choose to use one or both methods to streamline their workflows effectively.
