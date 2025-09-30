---
allowed-tools: shell, update_plan
---

# Issue Start

Begin work on a GitHub issue

## Usage
```
/issue-start

After running the prompt, ask the user for the issue number they want to start work on. This will be referred to as $ARGUMENTS.
```

## Codex CLI Notes
- All filesystem and GitHub actions run through the `shell` tool; stay in the repository root.
- Codex CLI cannot spawn sub-agents. Carry out the work yourself and use the planning tool for multi-step efforts.
- When creating or updating files, rewrite them atomically (e.g., `cat <<'EOF' > file`).

## Quick Check

1. **Find local task file:**
   - First check if `.claude/epics/*/$ARGUMENTS.md` exists (new naming)
   - If not found, search for file containing `github:.*issues/$ARGUMENTS` in frontmatter (old naming)
   - If not found: "❌ No local task for issue #$ARGUMENTS. This issue may have been created outside the PM system."

## Instructions

### 1. Setup Progress Tracking

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Create workspace structure:
```bash
mkdir -p .claude/epics/{epic_name}/updates/$ARGUMENTS
```

Update the task file frontmatter `updated` field with the current datetime.

### 2. Initialize Stream Notes

Create `.claude/epics/{epic_name}/updates/$ARGUMENTS/stream-1.md` (single active work item) with:
```markdown
---
issue: $ARGUMENTS
stream: main
agent: {agent_type}
started: {current_datetime}
status: in_progress
---

# Stream 1: main

## Scope
{task_scope}

## Files
{file_patterns}

## Progress
- Starting implementation
```
Populate the placeholders with details from the task file (scope, file patterns, acceptance criteria).

### 3. Outline Working Plan
- Use the planning tool to list the major subtasks you intend to complete during this session.
- Mirror the same subtasks in the `## Progress` section of `stream-1.md`, updating the list as you work.

### 4. GitHub Assignment

```bash
# Assign to self and mark in-progress
gh issue edit $ARGUMENTS --add-assignee @me --add-label "in-progress"
```

### 5. Output

```
✅ Started sequential work on issue #$ARGUMENTS

Epic: {epic_name}

Progress tracking initialized at:
  .claude/epics/{epic_name}/updates/$ARGUMENTS/

Next steps:
  1) Implement tasks in plan order and update stream-1.md as you go
  2) Run tests and review diffs when implementation is complete
  3) Prepare for manual review and Codex diff review before merging
  4) Sync updates and update the epic checklist

Monitor with: /epic-status
Sync updates: /issue-sync
```

## Error Handling

If any step fails, report clearly:
- "❌ {What failed}: {How to fix}"
- Continue with what's possible
- Never leave partial state

## Important Notes

- **No parallelization:** one issue at a time; treat “streams” as a sequential plan.
- **Reviews:** manual review is required; run a Codex review before merging.
- **No Sub-Issues plugin:** track progress via epic task list and issue comments.
- Follow `~/.codex/rules/datetime.md` for timestamps.
- Keep it simple - trust that GitHub and file system work.
