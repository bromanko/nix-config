# Issue Close

Mark an issue as complete and close it on GitHub.

## Usage
```
/issue-close

After running the prompt, ask the user for the issue number they want to close. This will be referred to as $ARGUMENTS.
After that ask them to provide optional completion notes. This will be referred to as $COMPLETION_NOTES.
```

## Codex CLI Notes
- Run filesystem and GitHub CLI commands with the `shell` tool from the workspace root.
- Codex CLI cannot launch sub-agents; work through the checklist sequentially and use the planning tool if multiple subtasks need tracking.
- Rewrite local files atomically (for example with `cat <<'EOF' > file` or a short script) to avoid partial edits.

## Instructions

### 1. Find Local Task File
- Check for `.claude/epics/*/$ARGUMENTS.md` (preferred naming).
- If not found, search for a file whose frontmatter includes `github:.*issues/$ARGUMENTS`.
- If nothing is found, report: "❌ No local task for issue #$ARGUMENTS" and stop.

### 2. Update Local Status
- Get the current datetime with `date -u +"%Y-%m-%dT%H:%M:%SZ"`.
- Update the task file frontmatter (rewrite the file) so that:
  ```yaml
  status: closed
  updated: {current_datetime}
  ```

### 3. Update Progress File
If `.claude/epics/{epic}/updates/$ARGUMENTS/progress.md` exists:
- Set `completion` to `100%` and append a completion note with timestamp.
- Update `last_sync` with the current datetime.

### 4. Close on GitHub
- Write the completion note to a temporary file before sending it to GitHub:
  ```bash
  cat <<'MD' > /tmp/issue-$ARGUMENTS-completion.md
  ✅ Task completed

  $ARGUMENTS

  $COMPLETION_NOTES

  ---
  Closed at: {timestamp}
  MD
  gh issue comment $ARGUMENTS --body-file /tmp/issue-$ARGUMENTS-completion.md
  gh issue close $ARGUMENTS
  ```

### 5. Update Epic Task List on GitHub
- Derive the epic name from the local task file path.
- Read the epic issue number from `.claude/epics/$epic_name/epic.md`.
- If an epic issue exists, copy its body, update the checkbox, and write it back:
  ```bash
  gh issue view $epic_issue --json body -q .body > /tmp/epic-body.md
  ISSUE=$ARGUMENTS python - <<'PY'
  import os, pathlib
  issue = os.environ['ISSUE']
  path = pathlib.Path('/tmp/epic-body.md')
  text = path.read_text()
  path.write_text(text.replace(f"- [ ] #{issue}", f"- [x] #{issue}"))
  PY
  gh issue edit $epic_issue --body-file /tmp/epic-body.md
  ```

### 6. Update Epic Progress
- Count total and closed tasks for the epic.
- Recalculate progress and update the epic frontmatter accordingly.

### 7. Output
```
✅ Closed issue #$ARGUMENTS
  Local: Task marked complete
  GitHub: Issue closed & epic updated
  Epic progress: {new_progress}% ({closed}/{total} tasks complete)

Next: Run /pm-next for the next priority task
```

## Important Notes
- Follow `~/.codex/rules/frontmatter-operations.md`.
- Follow `~/.codex/rules/github-operations.md`.
- Always sync local state before touching GitHub.
