---
name: es
description: Use the Everything Search CLI (es.exe) for ultra-fast file and folder search on Windows. Use when you need to find files by name, extension, pattern, regex, or path — especially across large directory trees where traditional search is too slow.
---

# ES — Everything Search CLI

`es.exe` is the command-line interface to Voidtools Everything, a lightning-fast Windows file indexer. It returns results near-instantly because it queries Everything's pre-built NTFS index rather than walking the filesystem.

## Prerequisites

Everything must be running for `es` to work. If a search returns `Error 8: Everything IPC window not found`, start Everything first:

```bash
# Start Everything in background mode (typical location)
"E:/Programme Files/Everything/Everything.exe" -startup
```

Confirm it's running with a quick test: `es -n 1 "."`

The Everything database auto-updates while running. If the index seems stale, force a rebuild:

```bash
es -reindex
```

## Search Syntax

Everything uses its own search syntax, not regex by default. Basic patterns:

| Pattern | Meaning |
|---------|---------|
| `foo` | Files/folders containing "foo" (case-insensitive) |
| `*.java` | All `.java` files |
| `*.{java,kt}` | Multiple extensions |
| `ext:exe;dll` | Filter by extension list |
| `"file name with spaces"` | Literal with spaces |

### Regex Search

Use `-regex` (or `-r`) for regex mode:

```bash
# Find all SKILL.md files (exact filename)
es -regex "SKILL\\.md$"

# Case-sensitive regex
es -i -regex "^[A-Z].*\\.rs$"
```

### Path Filtering

```bash
# Search within a specific directory tree
es -path "F:\source\BindAliasPlus" "*.java"

# Direct children of a folder (one level deep)
es -parent "F:\source\BindAliasPlus" "*.gradle"

# Children of the parent folder
es -parent-path "F:\source\BindAliasPlus"

# Match against full path, not just filename
es -match-path "gradle" -path "F:\source\BindAliasPlus"
```

### Type Filtering

```bash
# Folders only (use folder: search function — /ad flag doesn't work on this install)
es -n 20 "folder:" -path "F:\source\BindAliasPlus\mc-decompile-sources\26.1.2_26.2"

# Files only (use file: search function)
es -n 10 "file: *.java" -path "F:\source\BindAliasPlus\src"

# Exclude folders from results
es -n 10 "!folder: *.java" -path "F:\source\BindAliasPlus\src"
```

### Sort and Limit

```bash
# Limit results
es -n 20 "*.java"

# Sort by size (largest first) — "project tail": see big/important files at a glance
es -n 15 -sort size-descending -size "*.java" -path "F:\source\BindAliasPlus\src"

# Sort by date modified (newest first) — see what changed recently
es -n 15 -sort date-modified-descending -dm '!path:git' -path "F:\source\BindAliasPlus"
```

### Excluding paths (NOT operator)

The Everything NOT operator `!` must prefix a **search function** (like `path:`, `ext:`), not a bare term:

```bash
# ❌ Bare NOT — ignored, .git files still show
es !.git -path "F:\source\BindAliasPlus"

# ✅ Function-scoped NOT — excludes anything with "git" in the path
es '!path:git' -path "F:\source\BindAliasPlus"

# Also works:
es -match-path '!.git' -path "F:\source\BindAliasPlus"
```

### Whole Word and Case

```bash
# Whole word match
es -whole-word "SKILL"

# Case-sensitive
es -i "ClassName"
```

## Output Display

Default output is one full path per line. Add columns for metadata:

```bash
# Show file size and date modified
es -size -dm -n 5 "*.exe" -path "E:/Programme Files/Everything"

# Available columns:
# -name, -path-column, -full-path-and-name, -extension, -size
# -date-created (-dc), -date-modified (-dm), -date-accessed (-da)
# -attributes, -run-count, -date-run, -date-recently-changed (-rc)
```

### Structured Output Formats

```bash
# CSV output (with header)
es -csv -n 5 "*.md" -path "F:\source\BindAliasPlus"

# TSV, EFU, TXT formats also available: -tsv, -efu, -txt

# Export to file
es -export-csv results.csv "*.java" -path "F:\source\BindAliasPlus"
```

## Metadata Queries (No File Listing)

```bash
# Count matching files
es -get-result-count "*.java" -path "F:\source\BindAliasPlus"

# Total size of matching files
es -get-total-size "*.java" -path "F:\source\BindAliasPlus"

# Get Everything version
es -version
```

## Common Recipes

### Find All Source Files in a Project

```bash
es -n 50 "ext:java;kt;xml;gradle;json;properties" -path "F:\source\BindAliasPlus"
```

### Find Recently Modified Files

```bash
es -n 20 -sort date-modified-descending -dm -path "F:\source\BindAliasPlus"
```

### Find Large Files

```bash
es -n 20 -sort size-descending -size -path "F:\source\BindAliasPlus"
```

### Search Across Multiple Drives

```bash
# Everything indexes all NTFS volumes by default — no -path needed
es -n 10 "SKILL.md"
```

### Find Empty Directories

Use `folder:` combined with path filtering, then check manually — Everything doesn't have a native "empty folder" filter.

### Find Files by Attribute

```bash
# Hidden files and folders
es /ah -n 10 -path "F:\source\BindAliasPlus"

# Read-only files
es /ar -n 10 -path "F:\source\BindAliasPlus"
```

## Error Codes

| Code | Meaning |
|------|---------|
| 6 | Invalid switch/argument |
| 8 | Everything not running (IPC error) |
| Other | See `es --help` for full list |

## Tips

- Options can be abbreviated: internal `-` chars are optional (e.g., `-wholeword` works for `-whole-word`).
- Switches can also start with `/` (e.g., `/a-d`), but **`/ad` for folders doesn't work** on this install — use `folder:` search function instead.
- Disable a column with `-no-` prefix (e.g., `-no-size`).
- Use `^` prefix or double-quotes to escape special chars: `\ & | > < ^`.
- For scripting, prefer `-csv` or `-export-csv` for parseable output.
- Use `folder:` to filter directories only, `file:` for files only.
