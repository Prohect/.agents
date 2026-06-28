# read_file → ENOENT (file not found)

## Error

```
ENOENT: no such file or directory, access '<path>'
```

The `read_file` tool could not find the specified file.

## Root Cause

- The file path is stale (file was renamed, moved, or deleted by a previous edit).
- The path contains a typo.
- The path references a directory that does not exist.
- The first component of the path is not a project root directory.

## Solution

1. **Verify the file exists**: Use `list_directory` on the parent directory.
2. **Search for renamed files**: Use `find_path` with a glob (e.g., `**/*old-name*`).
3. **Check project roots**: Use `list_directory` on each project root to confirm which root the file belongs to.
4. **Correct the path**: Ensure the first component matches a project root directory name exactly.

## Attempts Log

_Add specific attempts here when documenting a new occurrence._

---

_Last updated: 2026-06-28_
