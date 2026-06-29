---
name: es
description: Use the Everything Search CLI (es) for ultra-fast file and directory search on Windows. Use when you need to find files/directories by name, extension, pattern, regex, or path, especially across large directory trees where traditional search is too slow.
---

# ES

`es` is the command-line interface to Voidtools Everything, a lightning-fast Windows file indexer. It returns results near-instantly because it queries Everything's pre-built NTFS index rather than walking the filesystem.

## Prerequisites

Everything must be running for `es` to work. If it's not already running, start it first (path varies by installation — adjust as needed). If the UAC is not permitted, then do not use `es`. If a search returns `Error 8: Everything IPC window not found`, start Everything first:

```bash
# Start Everything in background mode (adjust path to your installation)
"E:/Programme Files/Everything/Everything.exe" -startup
```

Confirm it's running with a quick test:

```bash
es -n 5 "."
```

The Everything database auto-updates while running. If the index seems stale, force a rebuild:

```bash
es -reindex
```

## Search Syntax

Everything uses its own search syntax, not regex by default. Basic patterns:

| Pattern | Meaning |
|---------|---------|
| `foo` | files/directories whose name (one level deep, full path not included) contains "foo" (case-insensitive) |
| `".file name with spaces"` | files/directories whose name (one level deep, full path not included) contains ".file name with spaces"  (case-insensitive) |
| `"ext:exe;dll"` | files filtered by extension list |

### Regex Search

Use `-regex` (or `-r`) for regex mode:

`a|b` : Match a or b
`gr(a|e)y` : Match gray or grey
`.` : Match any single character
`[abc]` : Match any character: a, b, or c
`[^abc]` : Match any character except a, b, c
`[a-z]` : Match any character in range a to z
`[a-zA-Z]` : Match any character in range a-z or A-Z
`^` : Match start of filename
`$` : Match end of filename
`( )` : Marked sub-expression (capturing group)
`\n` : Match the nth marked sub-expression (n = 1 to 9)
`\b` : Match word boundary
`*` : Match preceding item 0 or more times
`?` : Match preceding item 0 or 1 time
`+` : Match preceding item 1 or more times
`*?` : Match preceding item 0 or more times (lazy)
`+?` : Match preceding item 1 or more times (lazy)
`{x}` : Match preceding item exactly x times
`{x,}` : Match preceding item x or more times
`{x,y}` : Match preceding item between x and y times
`\` : Escape special character

Example:
```bash
es -r "\.rs$"
```

### Path Filtering

```bash
# Search recursively within a directory (case-insensitive exact match on the directory name)
es -path "$HOME/.agents/demo/proj" "*.java"

# Search direct children of a directory — non-recursive, only items whose parent is exactly this path
es -parent "$HOME/.agents/demo/proj" "*.gradle"

# Search recursively within the *parent* of the given path — equivalent to `es -path "$HOME/.agents/demo/proj"`
es -parent-path "$HOME/.agents/demo/proj/src"

# Match against full absolute path, not just filename or directory name
es -match-path "gradle" -path "$HOME/.agents/demo/proj"
```

### Type Filtering

```bash
# Directories only
es folder: -path "$HOME/.agents/demo/proj"

# Files only
es -n 20 file: "*.java" -path "$HOME/.agents/demo/proj/src"
```

### Sort and Limit

```bash
# Limit results
es -n 20 "*.java"

# Sort by size (largest first) — "project tail": see big/important files at a glance
es -n 20 -sort size-descending -size "*.java" -path "$HOME/.agents/demo/proj"

# Sort by date modified (newest first) — see what changed recently
es -n 20 -sort date-modified-descending -dm '!path:git' -path "$HOME/.agents/demo/proj"
```

### NOT operator

The Everything NOT operator is `!`:

```bash
# Bare `!` excludes only items whose *name* matches the given string.
# The .git directory itself is excluded, but its contents still appear
# because their individual names (e.g., "config") don't contain ".git".
es '!.git' -path "$HOME/.agents/demo/proj"

# `!` following `-match-path` excludes items whose *full path* matches the string.
# This removes everything inside .git as well.
es -match-path '!.git' -path "$HOME/.agents/demo/proj"

# Function-scoped `!` excludes anything with "git" anywhere in the path
es '!path:git' -path "$HOME/.agents/demo/proj"
```

### Whole Word and Case

```bash
# Whole word match — es is case-insensitive by default
es -whole-word "SKILL"

# Case-sensitive search
es -i "ClassName"
```

## Output Display

Default output is one full path per line. Add columns for metadata:

```bash
# Show file size and date modified
es -size -dm -n 20 "*.rs" -path "$HOME/.agents/demo/proj"

# Available columns:
# -name, -path-column, -full-path-and-name, -extension, -size
# -date-created (-dc), -date-modified (-dm), -date-accessed (-da)
# -attributes, -run-count, -date-run, -date-recently-changed (-rc)
```

### Structured Output Formats

```bash
# CSV output (with header)
es -csv -size -dm -n 20 "*.rs" -path "$HOME/.agents/demo/proj"

# TSV, EFU, TXT formats also available: -tsv, -efu, -txt

# Export to file
es -export-csv results.csv -size -dm -n 20 "*.rs" -path "$HOME/.agents/demo/proj"
```

## Metadata Queries (No File Listing)

```bash
# Count matching files
es -get-result-count "*.java" -path "$HOME/.agents/demo/proj"

# Total size of matching files
es -get-total-size "*.java" -path "$HOME/.agents/demo/proj"

# Get Everything version
es -version
```

## Common Recipes

### Find All Source Files in a Project

```bash
es -n 50 "ext:java;kt;xml;gradle;json;properties" -path "$HOME/.agents/demo/proj"
```

### Find Recently Modified Files

```bash
es -n 20 -sort date-modified-descending -dm -path "$HOME/.agents/demo/proj"
```

### Find Large Files

```bash
es -n 20 -sort size-descending -size -path "$HOME/.agents/demo/proj"
```

### Search Across Multiple Drives

```bash
# Everything indexes all NTFS volumes by default — no -path needed
es -n 20 "SKILL.md"
```

## Error Codes

| Code | Meaning |
|------|---------|
| 6 | Invalid switch/argument |
| 8 | Everything not running (IPC error) |
| Other | See `es --help` for full list |

## Tips

- **Combine with shell tools**: Pipe es output to `grep`, `wc -l`, or `xargs` for further processing. On Windows, strip `\r` first.

  ```bash
  # Count lines across all .java files
  es "*.java" -path "$HOME/.agents/demo/proj" | tr -d '\r' | xargs -d '\n' wc -l
  ```

- **Use `-n` to limit results**: es can return thousands of results quickly — always set `-n` unless you need everything.

- **Prefer `-path` over `-parent` for exploration**: `-path` searches recursively, which is usually what you want. Use `-parent` when you need exactly one level deep.

- **Single-quote special characters in shell**: Characters like `!` and `*` have special meaning in most shells. Wrap them in single quotes (`'!path:git'`, `'*.java'`) to pass them literally to es.

- **Run `es --help` for the full option list**: The help output covers every flag, sort option, and export format available.
