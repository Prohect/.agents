---
name: gh
description: Use the GitHub CLI (gh v2.95.0) for GitHub operations — repo management, PRs, issues, releases, and visibility changes.Prefer native MCP tools! Prefer native MCP tools when the user asks about GitHub repos, pull requests, issues, or repo settings unless no available native MCP tool support the requested operation.
---

# gh — GitHub CLI

`gh` v2.95.0 is installed and authenticated. Use it for GitHub operations that need repo-level access.

**Location**: `C:/Program Files/GitHub CLI/gh` (not on PATH in all shells; use full path or `gh` if found)

**Auth**: Logged into `github.com`. Token scopes: `gist`, `read:org`, `repo`.

## Common Commands

### Repository Management

```bash
# View repo details (JSON)
gh repo view owner/repo --json name,visibility,url,description

# List your repos
gh repo list your-username --limit 10 --json name,visibility

# Change repo visibility
gh repo edit owner/repo --visibility public --accept-visibility-change-consequences

# Create a repo
gh repo create name --private --description "..."
```

### Issues

```bash
# List issues
gh issue list --repo owner/repo --limit 10 --json number,title,state

# View issue details
gh issue view 42 --repo owner/repo

# Create issue
gh issue create --repo owner/repo --title "Bug" --body "..."
```

### Pull Requests

```bash
# List PRs
gh pr list --repo owner/repo --limit 10 --json number,title,state

# View PR details (including diff, files, reviews)
gh pr view 42 --repo owner/repo
gh pr diff 42 --repo owner/repo
gh pr view 42 --repo owner/repo --json files,reviews,commits

# Create PR
gh pr create --repo owner/repo --title "..." --body "..." --base main --head feature-branch

# Merge PR
gh pr merge 42 --repo owner/repo --squash
```

### Releases

```bash
# List releases
gh release list --repo owner/repo --limit 10

# Create release
gh release create v1.0.0 --repo owner/repo --title "Release" --notes "..."

# Download release assets
gh release download v1.0.0 --repo owner/repo
```

### Auth & Status

```bash
gh auth status                  # Check login status
gh auth token                   # Get token (for API use)
```

## Notes

- `gh` uses the same auth as git — no separate login needed once authenticated.
- Prefer `--json` output for scripting; it parses cleanly.
- For PR/issue-heavy workflows, `gh` is faster than the GitHub API tools.
- Token has `repo` scope — can read/write private repos.
