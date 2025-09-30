# Epic Sync

Push epic and tasks to GitHub as issues.

## Usage
```
/epic-sync

When this prompt is triggered, ask the user for the feature name which we will refer to as $ARGUMENTS.
```

## Quick Check

```bash
# Verify epic exists
test -f .claude/epics/$ARGUMENTS/epic.md || echo "❌ Epic not found. Run: /prd-parse"

# Count task files
ls .claude/epics/$ARGUMENTS/*.md 2>/dev/null | grep -v epic.md | wc -l
```

If no tasks found: "❌ No tasks to sync. Run: /epic-decompose"

## Instructions

### 1. Create Epic Issue

Strip frontmatter and prepare GitHub issue body:
```bash
# Extract content without frontmatter
sed '1,/^---$/d; 1,/^---$/d' .claude/epics/$ARGUMENTS/epic.md > /tmp/epic-body-raw.md

# Remove "## Tasks Created" section and replace with Stats
awk '
  /^## Tasks Created/ {
    in_tasks=1
    next
  }
  /^## / && in_tasks {
    in_tasks=0
    # When we hit the next section after Tasks Created, add Stats
    if (total_tasks) {
      print "## Stats\n"
      print "Total tasks: " total_tasks
      print "Parallel tasks: " parallel_tasks " (can be worked on simultaneously)"
      print "Sequential tasks: " sequential_tasks " (have dependencies)"
      print ""
    }
  }
  /^Total tasks:/ && in_tasks { total_tasks = $3; next }
  /^Parallel tasks:/ && in_tasks { parallel_tasks = $3; next }
  /^Sequential tasks:/ && in_tasks { sequential_tasks = $3; next }

  !in_tasks { print }
  END {
    # If we were still in tasks section at EOF, add stats
    if (in_tasks && total_tasks) {
      print "## Stats\n"
      print "Total tasks: " total_tasks
      print "Parallel tasks: " parallel_tasks " (can be worked on simultaneously)"
      print "Sequential tasks: " sequential_tasks " (have dependencies)"
    }
  }
' /tmp/epic-body-raw.md > /tmp/epic-body.md

# Determine epic type (feature vs bug) from content
if grep -qi "bug\|fix\|issue\|problem\|error" /tmp/epic-body.md; then
  epic_type="bug"
else
  epic_type="feature"
fi

# Create epic issue with labels
epic_number=$(gh issue create \
  --title "Epic: $ARGUMENTS" \
  --body-file /tmp/epic-body.md \
  --label "epic,epic:$ARGUMENTS,$epic_type" \
  --json number -q .number)
```

Store the returned issue number for epic frontmatter update.

### 2. Create Task Sub-Issues

Check if gh-sub-issue is available:
```bash
if gh extension list | grep -q "yahsan2/gh-sub-issue"; then
  use_subissues=true
else
  use_subissues=false
  echo "⚠️ gh-sub-issue not installed. Using fallback mode."
fi
```

Count task files to determine strategy:
```bash
task_count=$(ls .claude/epics/$ARGUMENTS/[0-9][0-9][0-9].md 2>/dev/null | wc -l)
```

### For Small Batches (< 5 tasks): Sequential Creation

```bash
if [ "$task_count" -lt 5 ]; then
  # Create sequentially for small batches
  for task_file in .claude/epics/$ARGUMENTS/[0-9][0-9][0-9].md; do
    [ -f "$task_file" ] || continue

    # Extract task name from frontmatter
    task_name=$(grep '^name:' "$task_file" | sed 's/^name: *//')

    # Strip frontmatter from task content
    sed '1,/^---$/d; 1,/^---$/d' "$task_file" > /tmp/task-body.md

    # Create sub-issue with labels
    if [ "$use_subissues" = true ]; then
      task_number=$(gh sub-issue create \
        --parent "$epic_number" \
        --title "$task_name" \
        --body-file /tmp/task-body.md \
        --label "task,epic:$ARGUMENTS" \
        --json number -q .number)
    else
      task_number=$(gh issue create \
        --title "$task_name" \
        --body-file /tmp/task-body.md \
        --label "task,epic:$ARGUMENTS" \
        --json number -q .number)
    fi

    # Record mapping for renaming
    echo "$task_file:$task_number" >> /tmp/task-mapping.txt
  done

  # After creating all issues, update references and rename files
  # This follows the same process as step 3 below
fi
```

### For Larger Batches

Codex CLI executes sequentially even for large sets of tasks. Break the work into manageable batches, record them in the planning tool, and process each task file in a loop while capturing a mapping file.

```bash
> /tmp/task-mapping.txt
for task_file in .claude/epics/$ARGUMENTS/[0-9][0-9][0-9].md; do
  [ -f "$task_file" ] || continue

  task_name=$(grep '^name:' "$task_file" | sed 's/^name: *//')
  sed '1,/^---$/d; 1,/^---$/d' "$task_file" > /tmp/task-body.md

  if [ "$use_subissues" = true ]; then
    task_number=$(gh sub-issue create \
      --parent "$epic_number" \
      --title "$task_name" \
      --body-file /tmp/task-body.md \
      --label "task,epic:$ARGUMENTS" \
      --json number -q .number)
  else
    task_number=$(gh issue create \
      --title "$task_name" \
      --body-file /tmp/task-body.md \
      --label "task,epic:$ARGUMENTS" \
      --json number -q .number)
  fi

  echo "$task_file:$task_number" >> /tmp/task-mapping.txt
done
```

If `task_count` is high, run the loop in batches (e.g., five at a time), updating the plan between batches so you and reviewers know the sync status.

### 3. Rename Task Files and Update References

First, build a mapping of old numbers to new issue IDs:
```bash
# Create mapping from old task numbers (001, 002, etc.) to new issue IDs
> /tmp/id-mapping.txt
while IFS=: read -r task_file task_number; do
  # Extract old number from filename (e.g., 001 from 001.md)
  old_num=$(basename "$task_file" .md)
  echo "$old_num:$task_number" >> /tmp/id-mapping.txt
done < /tmp/task-mapping.txt
```

Then rename files and update all references:
```bash
# Process each task file
while IFS=: read -r task_file task_number; do
  new_name="$(dirname "$task_file")/${task_number}.md"

  # Read the file content
  content=$(cat "$task_file")

  # Update depends_on and conflicts_with references
  while IFS=: read -r old_num new_num; do
    # Update arrays like [001, 002] to use new issue numbers
    content=$(echo "$content" | sed "s/\b$old_num\b/$new_num/g")
  done < /tmp/id-mapping.txt

  # Write updated content to new file
  echo "$content" > "$new_name"

  # Remove old file if different from new
  [ "$task_file" != "$new_name" ] && rm "$task_file"

  # Update github field in frontmatter
  # Add the GitHub URL to the frontmatter
  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  github_url="https://github.com/$repo/issues/$task_number"

  # Update frontmatter with GitHub URL and current timestamp
  current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Use sed to update the github and updated fields
  sed -i.bak "/^github:/c\github: $github_url" "$new_name"
  sed -i.bak "/^updated:/c\updated: $current_date" "$new_name"
  rm "${new_name}.bak"
done < /tmp/task-mapping.txt
```

### 4. Update Epic with Task List (Fallback Only)

If NOT using gh-sub-issue, add task list to epic:

```bash
if [ "$use_subissues" = false ]; then
  # Get current epic body
  gh issue view {epic_number} --json body -q .body > /tmp/epic-body.md

  # Append task list
  cat >> /tmp/epic-body.md << 'EOF'

  ## Tasks
  - [ ] #{task1_number} {task1_name}
  - [ ] #{task2_number} {task2_name}
  - [ ] #{task3_number} {task3_name}
  EOF

  # Update epic issue
  gh issue edit {epic_number} --body-file /tmp/epic-body.md
fi
```

With gh-sub-issue, this is automatic!

### 5. Update Epic File

Update the epic file with GitHub URL, timestamp, and real task IDs:

#### 5a. Update Frontmatter
```bash
# Get repo info
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
epic_url="https://github.com/$repo/issues/$epic_number"
current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Update epic frontmatter
sed -i.bak "/^github:/c\github: $epic_url" .claude/epics/$ARGUMENTS/epic.md
sed -i.bak "/^updated:/c\updated: $current_date" .claude/epics/$ARGUMENTS/epic.md
rm .claude/epics/$ARGUMENTS/epic.md.bak
```

#### 5b. Update Tasks Created Section
```bash
# Create a temporary file with the updated Tasks Created section
cat > /tmp/tasks-section.md << 'EOF'
## Tasks Created
EOF

# Add each task with its real issue number
for task_file in .claude/epics/$ARGUMENTS/[0-9]*.md; do
  [ -f "$task_file" ] || continue

  # Get issue number (filename without .md)
  issue_num=$(basename "$task_file" .md)

  # Get task name from frontmatter
  task_name=$(grep '^name:' "$task_file" | sed 's/^name: *//')

  # Get parallel status
  parallel=$(grep '^parallel:' "$task_file" | sed 's/^parallel: *//')

  # Add to tasks section
  echo "- [ ] #${issue_num} - ${task_name} (parallel: ${parallel})" >> /tmp/tasks-section.md
done

# Add summary statistics
total_count=$(ls .claude/epics/$ARGUMENTS/[0-9]*.md 2>/dev/null | wc -l)
parallel_count=$(grep -l '^parallel: true' .claude/epics/$ARGUMENTS/[0-9]*.md 2>/dev/null | wc -l)
sequential_count=$((total_count - parallel_count))

cat >> /tmp/tasks-section.md << EOF

Total tasks: ${total_count}
Parallel tasks: ${parallel_count}
Sequential tasks: ${sequential_count}
EOF

# Replace the Tasks Created section in epic.md
# First, create a backup
cp .claude/epics/$ARGUMENTS/epic.md .claude/epics/$ARGUMENTS/epic.md.backup

# Use awk to replace the section
awk '
  /^## Tasks Created/ {
    skip=1
    while ((getline line < "/tmp/tasks-section.md") > 0) print line
    close("/tmp/tasks-section.md")
  }
  /^## / && !/^## Tasks Created/ { skip=0 }
  !skip && !/^## Tasks Created/ { print }
' .claude/epics/$ARGUMENTS/epic.md.backup > .claude/epics/$ARGUMENTS/epic.md

# Clean up
rm .claude/epics/$ARGUMENTS/epic.md.backup
rm /tmp/tasks-section.md
```

### 6. Create Mapping File

Create `.claude/epics/$ARGUMENTS/github-mapping.md`:
```bash
# Create mapping file
cat > .claude/epics/$ARGUMENTS/github-mapping.md << EOF
# GitHub Issue Mapping

Epic: #${epic_number} - https://github.com/${repo}/issues/${epic_number}

Tasks:
EOF

# Add each task mapping
for task_file in .claude/epics/$ARGUMENTS/[0-9]*.md; do
  [ -f "$task_file" ] || continue

  issue_num=$(basename "$task_file" .md)
  task_name=$(grep '^name:' "$task_file" | sed 's/^name: *//')

  echo "- #${issue_num}: ${task_name} - https://github.com/${repo}/issues/${issue_num}" >> .claude/epics/$ARGUMENTS/github-mapping.md
done

# Add sync timestamp
echo "" >> .claude/epics/$ARGUMENTS/github-mapping.md
echo "Synced: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> .claude/epics/$ARGUMENTS/github-mapping.md
```

### 7. Output

```
✅ Synced to GitHub
  - Epic: #{epic_number} - {epic_title}
  - Tasks: {count} sub-issues created
  - Labels applied: epic, task, epic:{name}
  - Files renamed: 001.md → {issue_id}.md
  - References updated: depends_on/conflicts_with now use issue IDs

Next steps:
  - Start parallel execution: /epic-start
  - Or work on single issue: /issue-start
  - View epic: https://github.com/{owner}/{repo}/issues/{epic_number}
```

## Error Handling

Follow `~/.codex/rules/github-operations.md` for GitHub CLI errors.

If any issue creation fails:
- Report what succeeded
- Note what failed
- Don't attempt rollback (partial sync is fine)

## Important Notes

- Trust GitHub CLI authentication
- Don't pre-check for duplicates
- Update frontmatter only after successful creation
- Keep operations simple and atomic
