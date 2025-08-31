---
allowed-tools: Bash(jj:*)
description: Analyze jj status and create logical commits with good messages
---

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
   - Use `jj new` to create new commits and `jj move` to organize files into logical groups
   - Use `jj commit -m "message"` to commit with messages directly (never use interactive editors)
   - Use descriptive commit messages following conventional commit format when applicable
   - Ensure each commit represents a complete, coherent change
   - Consider the existing codebase patterns and commit history style
   - Leave the working directory on a new clean commit

3. **Commit message guidelines**:
   - Start with a concise summary (50 chars or less)
   - Use imperative mood ("Add feature" not "Added feature")
   - Include more detailed explanation in body if needed
   - Reference any relevant issues or context

If there are no changes to commit, simply report the current status.
If changes are too complex to split automatically, suggest a manual approach with specific commands.

**Important**: Always use non-interactive commands only. Never use `jj split` without explicit paths, `jj commit` without `-m`, or any other command that would open an interactive editor or prompt.
