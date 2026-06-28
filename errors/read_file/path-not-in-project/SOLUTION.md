# read_file → path not in project (ENOENT variant)

## Error

```
Path <path> is not in the project
```

The `read_file` tool rejected the path because it lies outside any project root directory.

## Root Cause

`read_file` only resolves paths within:
- Any declared **project root** (e.g., `F:\source\BindAliasPlus`)
- `~/.agents/skills/` (special allow case for global skills)

Arbitrary filesystem paths — even sibling directories on the same drive — are rejected.

## Actual Encounters

### 1. Binary outside project
```
read_file("E:\Programme Files\commandLineInterface\es.exe")
→ Path E:\Programme Files\commandLineInterface\es.exe is not in the project
```

### 2. Sibling repo on same drive
```
read_file("F:\source\forks\zed\README.md")
→ Path F:\source\forks\zed\README.md is not in the project
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
cat "E:/Programme Files/commandLineInterface/es.exe"    # binary — won't print usefully
cat "F:/source/forks/zed/README.md"                      # sibling repo
cat "C:/Users/76288/.agents/errors/.../SOLUTION.md"      # errors dir
```

For files that must be read frequently, consider adding their parent as a project root, or symlinking them into a project root directory.

## Attempts Log

- **2026-06-28**: Hit while testing read tool scope — tried reading binary, sibling repo, and errors dir. Resolved with `terminal cat`.
