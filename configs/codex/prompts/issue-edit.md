# Issue Edit

Edit issue details locally and on GitHub.

## Usage
```
/issue-edit

After running the prompt, ask the user for the issue number they want to edit. This will be referred to as $ARGUMENTS.
```

## Instructions

### 1. Get Current Issue State

```bash
# Get from GitHub
gh issue view $ARGUMENTS --json title,body,labels

# Find local task file
# Search for file with github:.*issues/$ARGUMENTS
```

### 2. Interactive Edit

Ask user what to edit:
- Title
- Description/Body
- Labels
- Acceptance criteria (local only)
- Priority/Size (local only)

### 3. Update Local File

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update the local task file by rewriting it with the agreed changes:
- Update frontmatter `name` if title changed
- Update body content if description changed
- Update `updated` field with current datetime

### 4. Update GitHub

If title changed:
```bash
gh issue edit $ARGUMENTS --title "{new_title}"
```

If body changed:
```bash
gh issue edit $ARGUMENTS --body-file {updated_task_file}
```

If labels changed:
```bash
gh issue edit $ARGUMENTS --add-label "{new_labels}"
gh issue edit $ARGUMENTS --remove-label "{removed_labels}"
```

### 5. Output

```
✅ Updated issue #$ARGUMENTS
  Changes:
    {list_of_changes_made}

Synced to GitHub: ✅
```

## Important Notes

Always update local first, then GitHub.
Preserve frontmatter fields not being edited.
Follow `~/.codex/rules/frontmatter-operations.md`.
