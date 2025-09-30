# Epic Decompose

Break an epic into concrete, actionable tasks.

## Usage
```
/epic-decompose

When this prompt is triggered, ask the user for the feature name which we will refer to as $ARGUMENTS.
```

## Codex CLI Notes
- Use `shell` commands for filesystem work; stay rooted in the repository.
- Plan your batches with the planning tool
- Create or update files by rewriting them atomically (e.g., with `cat <<'EOF' > file`).

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `~/.codex/rules/datetime.md` - For getting real current date/time

## Preflight Checklist

Complete these validation steps without narrating them to the user.

1. **Verify epic exists:**
   - Check if `.claude/epics/$ARGUMENTS/epic.md` exists
   - If not found, tell user: "❌ Epic not found: $ARGUMENTS. First create it with: /prd-parse"
   - Stop execution if epic doesn't exist

2. **Check for existing tasks:**
   - Look for numbered task files (001.md, 002.md, etc.) in `.claude/epics/$ARGUMENTS/`
   - If tasks exist, list them and ask: "⚠️ Found {count} existing tasks. Delete and recreate all tasks? (yes/no)"
   - Proceed only with explicit 'yes'
   - If user says no, suggest: "View existing tasks with: /epic-show"

3. **Validate epic frontmatter:**
   - Ensure the epic has `name`, `status`, `created`, and `prd`
   - If invalid, tell user: "❌ Invalid epic frontmatter. Please check: .claude/epics/$ARGUMENTS/epic.md"

4. **Check epic status:**
   - If epic status is "completed", warn: "⚠️ Epic is marked as completed. Are you sure you want to decompose it again?"

## Instructions

You are decomposing **$ARGUMENTS** into specific, actionable engineering tasks.

### 1. Read the Epic
- Use `shell` commands (e.g., `cat`, `sed -n`) to load `.claude/epics/$ARGUMENTS/epic.md`
- Understand the technical approach and requirements
- Review any existing task breakdown preview

### 2. Analyze Concurrency and Dependencies
- Decide which tasks can proceed in parallel and which require sequencing
- Update your plan with key groups or phases before creating files
- Note dependencies so you can populate `depends_on`, `parallel`, and `conflicts_with` accurately

### 3. Create Task Files Sequentially
For each task you identify:
1. Determine the next task number (001, 002, ...).
2. Capture details (title, scope, dependencies, acceptance criteria).
3. Create the task file using the template below and fill in all placeholders.
4. Update your plan and progress notes as you complete each file.

Template for `.claude/epics/$ARGUMENTS/{task_number}.md`:
```markdown
---
name: [Task Title]
status: open
created: [Current ISO date/time]
updated: [Current ISO date/time]
github: [Will be updated when synced to GitHub]
depends_on: []  # List prerequisite task numbers, e.g., [001, 002]
parallel: true  # Mark false when this task must wait on dependencies
conflicts_with: []  # Tasks that modify the same assets, e.g., [003, 004]
---

# Task: [Task Title]

## Description
Clear, concise description of what needs to be done

## Acceptance Criteria
- [ ] Specific criterion 1
- [ ] Specific criterion 2
- [ ] Specific criterion 3

## Technical Details
- Implementation approach
- Key considerations
- Code locations/files affected

## Dependencies
- [ ] Task/Issue dependencies
- [ ] External dependencies

## Definition of Done
- [ ] Code implemented
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] Code reviewed
```
Use `date -u +"%Y-%m-%dT%H:%M:%SZ"` for the timestamps.

### 4. Task Naming and Metadata
- Save files as `.claude/epics/$ARGUMENTS/{task_number}.md`
- Keep titles short but descriptive
- Set `parallel` to `true` only when tasks can run concurrently without conflicts
- List task numbers in `depends_on` for ordering and `conflicts_with` for resource contention

### 5. Task Types to Consider
- **Setup tasks**: Environment, dependencies, scaffolding
- **Data tasks**: Models, schemas, migrations
- **API tasks**: Endpoints, services, integration
- **UI tasks**: Components, pages, styling
- **Testing tasks**: Unit, integration, end-to-end
- **Documentation tasks**: README, API docs
- **Deployment tasks**: CI/CD, infrastructure

### 6. Progress Tracking
- Update your plan as you complete or adjust tasks
- Record summaries in `.claude/epics/$ARGUMENTS/updates` if applicable

### 7. Execution Strategy Guidance
- **Small epic (< 5 tasks):** Create tasks in one pass
- **Medium epic (5-10 tasks):** Break into batches and update the plan between batches
- **Large epic (> 10 tasks):** Consider additional decomposition or scope reduction before proceeding

### 8. Task Dependency Validation
- Ensure referenced dependencies exist (e.g., if Task 003 depends on 002, confirm 002 is created)
- Watch for circular dependencies and warn if discovered: "⚠️ Task dependency warning: {details}"

### 9. Update Epic with Task Summary
After all tasks are written, update the epic summary section:
```markdown
## Tasks Created
- [ ] 001.md - {Task Title} (parallel: true/false)
- [ ] 002.md - {Task Title} (parallel: true/false)
...
```

### 10. Quality Checks
- [ ] Each task is actionable and scoped (1-3 days of work)
- [ ] Dependencies and conflicts are accurate
- [ ] Acceptance criteria are clear and testable
- [ ] No placeholder text remains

## Output
Provide a concise summary:
```
✅ Created {task_count} tasks for epic $ARGUMENTS
  Parallel-ready: {parallel_count}
  Sequential: {sequential_count}

Next: /epic-sync to publish tasks to GitHub
```
