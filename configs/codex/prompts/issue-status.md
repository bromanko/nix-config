# Issue Status

Check issue status (open/closed) and current state.

## Usage
```
/issue-status

After running the prompt, ask the user for the issue number they want to get status for. This will be referred to as $ARGUMENTS.
```

## Instructions

You are checking the current status of a GitHub issue and providing a quick status report for: **Issue #$ARGUMENTS**

### 1. Fetch Issue Status
Use GitHub CLI to get current status:
```bash
gh issue view #$ARGUMENTS --json state,title,labels,assignees,updatedAt
```

### 2. Status Display
Show concise status information:
```
🎫 Issue #$ARGUMENTS: {Title}

📊 Status: {OPEN/CLOSED}
   Last update: {timestamp}
   Assignee: {assignee or "Unassigned"}

🏷️ Labels: {label1}, {label2}, {label3}
```

### 3. Epic Context
If issue is part of an epic:
```
📚 Epic Context:
   Epic: {epic_name}
   Epic progress: {completed_tasks}/{total_tasks} tasks complete
   This task: {task_position} of {total_tasks}
```

### 4. Local Sync Status

Check for an update directory:
```bash
update_dir=$(ls -d .claude/epics/*/updates/$ARGUMENTS 2>/dev/null | head -n1)
```
- If `update_dir` is missing, report `Local file: missing`
- Otherwise prefer `progress.md` if present:
  ```bash
  local_file="${update_dir}/progress.md"
  if [ ! -f "$local_file" ]; then
    local_file=$(ls "${update_dir}"/stream-*.md 2>/dev/null | head -n1)
  fi
  ```
- If neither file exists, report `Local file: missing`
- Use the chosen file to read the most recent frontmatter `last_sync` (if available) or the file mtime for `Last local update`
- Set `Sync status` by comparing `last_sync`/mtime against GitHub timestamps as before, and treat stream files the same as progress files when computing it

### 5. Quick Status Indicators
Use clear visual indicators:
- 🟢 Open and ready
- 🟡 Open with blockers
- 🔴 Open and overdue
- ✅ Closed and complete
- ❌ Closed without completion

### 6. Actionable Next Steps
Based on status, suggest actions:
```
🚀 Suggested Actions:
   - Start work: /issue-start $ARGUMENTS
   - Sync updates: /issue-sync $ARGUMENTS
   - Close issue: gh issue close #$ARGUMENTS
   - Reopen issue: gh issue reopen #$ARGUMENTS
```

### 7. Batch Status
If checking multiple issues, support comma-separated list:
```
/issue-status 123,124,125
```

Keep the output concise but informative, perfect for quick status checks during development of Issue #$ARGUMENTS.
