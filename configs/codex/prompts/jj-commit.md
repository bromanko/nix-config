---
allowed-tools: shell
description: Analyze jj status and create logical commits with good messages
---

## Codex CLI Notes
- Use the `shell` tool for all jj commands; Codex CLI cannot spawn interactive editors.
- Run commands from the repository root so jj sees the workspace.

## Context

- Current jj status: !`jj status`
- Current diff of all changes: !`jj diff`
- Current branch info: !`jj log -r @ -T 'commit_id ++ "\n" ++ description'`
- Recent commit history: !`jj log --limit 10 -T 'commit_id.short() ++ " " ++ description.first_line()'`

## Your task

Based on the jujutsu status and changes shown above, analyze the modifications and:

1. **Group related changes** into logical commits by examining:
   - File types and purposes (config files, modules, documentation, etc.)
   - Functional relationships between changes
   - Scope of modifications (single feature, bug fix, refactoring, etc.)

2. **Create separate commits** for each logical group using non-interactive commands:
   - **LINEAR COMMIT WORKFLOW**: Use `jj commit -m "message"` followed by `jj new` to create commits linearly, one after another
   - **NEVER use interactive commands**: Always include `-m` flag with commit message. Never use `jj commit` without `-m`
   - This ensures commits are created sequentially rather than branching from a common parent
   - Use `jj move` to organize files into logical groups if needed
   - Use descriptive commit messages following conventional commit format when applicable
   - Ensure each commit represents a complete, coherent change
   - Consider the existing codebase patterns and commit history style
   - Always end with `jj new` to create a fresh working copy for the next change

3. **Commit message guidelines**:
   - Start with a concise summary (50 chars or less)
   - Use imperative mood ("Add feature" not "Added feature")
   - Include more detailed explanation in body if needed
   - Reference any relevant issues or context

If there are no changes to commit, simply report the current status.
If changes are too complex to split automatically, suggest a manual approach with specific commands.

**Important**
  - Always use non-interactive commands only. Never use `jj split` without explicit paths, `jj commit` without `-m`, or any other command that would open an interactive editor or prompt.
  - In jujutsu, you only need `jj commit -m "message"` to create a fresh working copy for the next change.
  - Don't create empty commits, or commits without messages.
