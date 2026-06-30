# read_file → path not in project (ENOENT variant)

## Error

```
Path <path> is not in the project
```

The `read_file` tool rejected the path because it lies outside any project root directory.

## Root Cause

`read_file` only resolves paths within:
- Any declared **project root** (e.g., `/home/you/project`)
- `~/.agents/skills/` (special allow case for global skills)

Arbitrary filesystem paths — even sibling directories on the same drive — are rejected.

## Actual Encounters

### 1. Binary outside project
```
read_file("C:\Program Files\SomeTool\tool.exe")
→ Path C:\Program Files\SomeTool\tool.exe is not in the project
```

### 2. Sibling repo on same drive
```
read_file("D:\source\other-project\README.md")
→ Path D:\source\other-project\README.md is not in the project
```

### 3. `~/.agents/errors/` (not skills!)
```
read_file("~/.agents/errors/read_file/ENOENT/SOLUTION.md")
→ Path ~/.agents/errors/read_file/ENOENT/SOLUTION.md is not in the project
```
Only `~/.agents/skills/` has the special allow case — `~/.agents/errors/` does not.

## Solution

Use `terminal` to read files outside project roots — it has no path restrictions:
```bash
cat "C:/Program Files/SomeTool/tool.exe"                 # binary — won't print usefully
cat "D:/source/other-project/README.md"                   # sibling repo
cat "$HOME/.agents/errors/.../SOLUTION.md"               # errors dir
```

For files that must be read frequently, consider adding their parent as a project root, or symlinking them into a project root directory.

## Attempts Log

- **2026-06-28**: Hit while testing read tool scope — tried reading binary, sibling repo, and errors directory. Resolved with `terminal cat`.
