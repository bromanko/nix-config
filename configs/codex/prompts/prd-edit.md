---
allowed-tools: shell, update_plan
---

# PRD Edit

Edit an existing Product Requirements Document.

## Usage
```
/pm:prd-edit <feature_name>
```

## Instructions

### 1. Read Current PRD
- Use `shell` commands (for example `cat`, `sed -n`, `rg`) to inspect `.claude/prds/$ARGUMENTS.md`.
- Parse the frontmatter and review every section before proposing changes.

### 2. Interactive Edit
Ask the user which sections need to change:
- Executive Summary
- Problem Statement
- User Stories
- Requirements (Functional/Non-Functional)
- Success Criteria
- Constraints & Assumptions
- Out of Scope
- Dependencies

Discuss clarifying questions in the chat when needed.

### 3. Update PRD
- Get the current datetime with `date -u +"%Y-%m-%dT%H:%M:%SZ"`.
- Rewrite the file using `shell` redirection (e.g., `cat <<'EOF' > file` or a short script) to keep formatting consistent.
- Preserve all frontmatter fields except `updated`; set `updated` to the new timestamp.
- Apply the agreed edits to the selected sections only.

### 4. Check Epic Impact
If the PRD references an epic:
- Notify the user: "This PRD links to epic {epic_name}."
- Ask: "The epic may need updating based on these changes. Review it now? (yes/no)"
- If yes, suggest: "Run /pm:epic-edit {epic_name} to refresh the epic."

### 5. Output
```
✅ Updated PRD: $ARGUMENTS
  Sections edited: {list_of_sections}

{If has epic}: ⚠️ Epic may need review: {epic_name}

Next: /pm:prd-parse $ARGUMENTS to update epic
```

## Important Notes
- Preserve the original `created` timestamp.
- Keep any version history that already exists in the frontmatter.
- Follow `/rules/frontmatter-operations.md` for YAML safety.
- Use the planning tool when multiple edits require tracking.
