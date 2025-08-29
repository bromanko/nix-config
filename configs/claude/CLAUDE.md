## Version Control

- Prefer **jujutsu (jj)** over git when version control is needed.
- If a `.jj` directory is present, assume jujutsu is in use.
- The `jj` CLI is always available. If unsure about a command, run `jj --help` or `jj $command --help`.
- Only use git if no `.jj` directory is found.

### Common Jujutsu Commands

**IMPORTANT**: Jujutsu uses its own commands, NOT git commands. Never assume git commands work with jj.

- `jj status` - Show working copy status
- `jj log` - Show commit history  
- `jj diff` - Show changes in working copy
- `jj commit -m "message"` - Create commit with message
- `jj new` - Create new commit
- `jj edit COMMIT` - Edit a commit
- `jj move` - Move changes between commits
- `jj squash` - Squash commits
- `jj describe -m "message"` - Change commit description
- `jj branch create NAME` - Create new branch
- `jj branch set NAME` - Set branch to current commit
- `jj git push` - Push to git remote
- `jj git fetch` - Fetch from git remote
