---
name: grep
description: Use GNU grep (3.0) for text search — pattern matching, recursive search, context, filtering. Use when you need to search file content for patterns, find TODOs, filter command output, or search codebases by content.
---

# grep — Text Search

`grep` v3.0 (GNU grep). Searches file content for lines matching a pattern. Supports Basic (BRE), Extended (ERE), Fixed-string, and Perl (PCRE) regex flavors, plus recursive directory search with inclusion/exclusion filters.

## Quick Reference

| Task | Command |
|------|---------|
| Basic literal search | `grep "ERROR" file.log` |
| Case-insensitive | `grep -i "error" file` |
| Extended regex (ERE) | `grep -E "ERROR\|FATAL" file` |
| Fixed string (no regex) | `grep -F "literal.*" file` |
| Perl regex (PCRE) | `grep -P "\d+" file` |
| Whole word only | `grep -w "error" file` |
| Whole line match | `grep -x "exact line" file` |
| Invert match | `grep -v "DEBUG" file` |
| Show line numbers | `grep -n "pattern" file` |
| Only matching part | `grep -o "ERROR" file` |
| Count matches per file | `grep -c "pattern" file` |
| List matching files only | `grep -l "pattern" *.java` |
| List non-matching files | `grep -L "pattern" *.java` |
| Recursive search | `grep -r "pattern" dir/` |
| Filter by extension | `grep -r --include="*.java" "pattern" .` |
| Exclude a directory | `grep -r --exclude-dir=".git" "pattern" .` |
| Exclude file patterns | `grep -r --exclude="*.log" "pattern" .` |
| Context (N lines around) | `grep -C 2 "pattern" file` |
| Pipe from stdin | `cmd \| grep "pattern"` |

## Regex Flavors

`grep` defaults to **BRE** (Basic Regular Expressions) unless a flavor flag is given. Prefer `-E` (ERE) for most tasks — it's cleaner and better-supported.

```bash
# BRE: must backslash-escape | ( ) { } +
cd "$HOME/.agents/demo/grep" && grep "ERROR\|FATAL" logs/error.log
# → [2024-01-01 10:30:00] ERROR Connection refused
#   [2024-01-01 10:31:00] FATAL Out of memory
#   [2024-01-01 10:32:00] ERROR Timeout on socket

# ERE: no backslash needed — cleaner
cd "$HOME/.agents/demo/grep" && grep -E "ERROR|FATAL" logs/error.log
# → same output

# Fixed string: treats pattern literally (no regex at all)
cd "$HOME/.agents/demo/grep" && grep -F "error.*" resources/notes.txt
# → (no match — literal "error.*" not in file)
```

## Basic Search

```bash
# Search a single file
cd "$HOME/.agents/demo/grep" && grep "error" src/main.rs
# →     // error handling

# Case-insensitive
cd "$HOME/.agents/demo/grep" && grep -i "error" src/main.rs
# →     // error handling
#       println!("Error: something went wrong");

# Whole word only — "error" matches but "errorCode" does not
cd "$HOME/.agents/demo/grep" && grep -w "error" src/special\ file.java
# → (no match — "error" appears only as part of "errorCode" / "errors")

# Whole line — line must be exactly the pattern
cd "$HOME/.agents/demo/grep" && grep -x "TODO: fix error handling in main module" resources/notes.txt
# → TODO: fix error handling in main module

# Invert match — show lines that do NOT match
cd "$HOME/.agents/demo/grep" && grep -v "ERROR" logs/error.log
# → [2024-01-01 10:31:00] FATAL Out of memory
```

## Output Control

```bash
# Line numbers
cd "$HOME/.agents/demo/grep" && grep -n "error" src/main.rs
# → 6:    // error handling

# Only the matching part (not the whole line)
cd "$HOME/.agents/demo/grep" && grep -o "ERROR" logs/error.log
# → ERROR
#   ERROR

# Count matches per file (0 for files without matches)
cd "$HOME/.agents/demo/grep" && grep -c "error" src/main.rs src/Utils.java src/Main.java
# → src/main.rs:1
#   src/Utils.java:0
#   src/Main.java:0

# Show only filenames that contain a match
cd "$HOME/.agents/demo/grep" && grep -l "error" src/*.java
# → src/special file.java

# Show only filenames that do NOT contain a match
cd "$HOME/.agents/demo/grep" && grep -L "error" src/*.java
# → src/Main.java
#   src/Utils.java

# Quiet mode — no output, just exit status (0 = found, 1 = not found)
cd "$HOME/.agents/demo/grep" && grep -q "ERROR" logs/error.log && echo "found"
# → found
```

### Filename Display (`-H`, `-h`)

```bash
# Multiple files: filenames shown by default
cd "$HOME/.agents/demo/grep" && grep "error" src/main.rs src/Utils.java
# → src/main.rs:    // error handling

# Single file: no filename by default; force with -H
cd "$HOME/.agents/demo/grep" && grep -H "error" src/main.rs
# → src/main.rs:    // error handling

# Suppress filenames with -h (even with multiple files)
cd "$HOME/.agents/demo/grep" && grep -h "error" src/main.rs src/Utils.java
# →     // error handling
```

## Recursive Search

```bash
# Recursively search all files under a directory
cd "$HOME/.agents/demo/grep" && grep -r "error" .
# → ./resources/notes.txt:TODO: fix error handling in main module
#   ./resources/notes.txt:FIXME: refactor error codes
#   ./resources/notes.txt:NOTE: all errors should go through logError()
#   ./src/main.rs:    // error handling
#   ./src/special file.java:    private int errorCode;
#   ./src/special file.java:        System.out.println("handling errors gracefully");
#   ./test/test_main.rs:fn test_error() {
#   ./test/test_main.rs:    assert!(false, "expected error");

# Combine with -l to only show filenames
cd "$HOME/.agents/demo/grep" && grep -r -l "error" .
# → ./resources/notes.txt
#   ./src/main.rs
#   ./src/special file.java
#   ./test/test_main.rs

# Combine with -n for line numbers in recursive output
cd "$HOME/.agents/demo/grep" && grep -r -n "TODO\|FIXME" .
# → ./resources/notes.txt:1:TODO: fix error handling in main module
#   ./resources/notes.txt:2:FIXME: refactor error codes
```

**⚠️ Quirk:** `grep -r` traverses `.git` directories by default. Use `--exclude-dir=".git"` to skip them (see Filtering below).

### Without `-r`: Directories Error

```bash
# Passing a directory without -r is an error
cd "$HOME/.agents/demo/grep" && grep "error" src/
# → grep: src/: Is a directory

# Use -d skip to silently skip directories (or -d read to treat them as files)
cd "$HOME/.agents/demo/grep" && grep -d skip "error" src/
# → (exit code 1 — no file searched, so no match)
```

## Filtering: Include & Exclude

```bash
# Only search .rs files
cd "$HOME/.agents/demo/grep" && grep -r --include="*.rs" "fn" .
# → ./src/main.rs:fn main() {
#   ./src/main.rs:fn helper() {
#   ./test/test_main.rs:fn test_main() {
#   ./test/test_main.rs:fn test_error() {

# Only search .java files
cd "$HOME/.agents/demo/grep" && grep -r --include="*.java" "error" .
# → ./src/special file.java:    private int errorCode;
#   ./src/special file.java:        System.out.println("handling errors gracefully");

# Exclude .git directory (important for project searches)
cd "$HOME/.agents/demo/grep" && grep -r --exclude-dir=".git" "bare" .
# → (no output — .git/config is skipped)

# Without --exclude-dir, .git IS searched:
cd "$HOME/.agents/demo/grep" && grep -r "bare" .
# → ./.git/config:    bare = false

# Exclude log files
cd "$HOME/.agents/demo/grep" && grep -r --exclude="*.log" "error" .
# → (logs/ are skipped)

# Exclude multiple directories
cd "$HOME/.agents/demo/grep" && grep -r --exclude-dir=".git" --exclude-dir="logs" "error" .
```

## Context Lines (`-A`, `-B`, `-C`)

```bash
# 1 line after each match
cd "$HOME/.agents/demo/grep" && grep -A 1 "ERROR" logs/server.log
# → [2024-01-01 10:15:00] ERROR Disk write failed
#   [2024-01-01 10:20:00] INFO  Server shutting down

# 1 line before each match
cd "$HOME/.agents/demo/grep" && grep -B 1 "Disk write" logs/server.log
# → [2024-01-01 10:10:00] INFO  Accepted connection from 127.0.0.1
#   [2024-01-01 10:15:00] ERROR Disk write failed

# 1 line before AND after (shortcut for -B 1 -A 1)
cd "$HOME/.agents/demo/grep" && grep -C 1 "Disk write" logs/server.log
# → [2024-01-01 10:10:00] INFO  Accepted connection from 127.0.0.1
#   [2024-01-01 10:15:00] ERROR Disk write failed
#   [2024-01-01 10:20:00] INFO  Server shutting down
```

## Binary Files

```bash
# Default: grep detects binary and just reports "matches"
cd "$HOME/.agents/demo/grep" && grep "ERROR" resources/large.bin
# → Binary file resources/large.bin matches

# -a: treat binary as text, show matching lines
cd "$HOME/.agents/demo/grep" && grep -a "ERROR" resources/large.bin
# → (prints matching line, may include binary garbage)

# -I: suppress binary match messages entirely (like --binary-files=without-match)
cd "$HOME/.agents/demo/grep" && grep -I "ERROR" resources/large.bin
# → (no output, exit code 1 — treated as no match)
```

**Tip:** When searching a mixed project tree, use `-I` to skip binary files silently:
```bash
cd "$HOME/proj" && grep -r -I "pattern" .
```

## Stdin / Pipe Input

```bash
# grep reads from stdin when no file is given
echo "test error line" | grep "error"
# → test error line

# Filter command output — only show lines containing "ERROR"
some_command | grep "ERROR"

# Exclude lines — show everything EXCEPT matches
some_command | grep -v "DEBUG\|TRACE"
```

## Multiple Patterns (`-e`, `-f`)

```bash
# -e: specify multiple patterns (OR-ed together)
cd "$HOME/.agents/demo/grep" && grep -e "ERROR" -e "FATAL" logs/error.log
# → [2024-01-01 10:30:00] ERROR Connection refused
#   [2024-01-01 10:31:00] FATAL Out of memory
#   [2024-01-01 10:32:00] ERROR Timeout on socket

# -f: read patterns from a file (one per line)
printf 'ERROR\nFATAL' > /tmp/patterns.txt
cd "$HOME/.agents/demo/grep" && grep -f /tmp/patterns.txt logs/error.log
# → same output
```

## Miscellaneous Options

```bash
# Stop after N matches per file
cd "$HOME/.agents/demo/grep" && grep -m 1 "ERROR" logs/error.log
# → [2024-01-01 10:30:00] ERROR Connection refused

# Per-file counts with -c
cd "$HOME/.agents/demo/grep" && grep -r -c "fn" --include="*.rs" .
# → ./src/main.rs:2
#   ./test/test_main.rs:2

# Color output (always/never/auto)
cd "$HOME/.agents/demo/grep" && grep --color=always "ERROR" logs/error.log  # force color
grep --color=never "ERROR" file.log   # strip color
grep --color=auto "ERROR" file.log    # color only when output is a terminal

# Null-separated filenames (for xargs -0)
cd "$HOME/.agents/demo/grep" && grep -l -Z "error" src/*.java | xargs -0 cat
```

## Common Recipes

```bash
# Find all TODO/FIXME comments in a project
cd "$HOME/proj" && grep -r -n "TODO\|FIXME" . --exclude-dir=".git"

# Find files containing a pattern, then inspect them
cd "$HOME/proj" && grep -r -l "pattern" . --exclude-dir=".git"

# Count how many files contain "error" (per extension)
grep -r -l --include="*.java" "error" . | wc -l
grep -r -l --include="*.rs" "error" . | wc -l

# Search only specific file types, show context
cd "$HOME/proj" && grep -r -n -C 2 --include="*.java" --include="*.rs" "TODO" .

# Find all lines NOT matching a debug/verbose pattern
grep -v "^[0-9]\+ DEBUG" app.log

# Check if a pattern exists anywhere (fast, no output)
cd "$HOME/proj" && grep -r -q "config_value" . && echo "found" || echo "not found"

# Extract all email addresses from a file
grep -E -o "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" file.txt
```

## Regex Cheat Sheet

### BRE (default)

| Token | Meaning |
|-------|---------|
| `^` | Start of line |
| `$` | End of line |
| `.` | Any single character |
| `[abc]` | Character class |
| `[^abc]` | Negated class |
| `*` | 0 or more of preceding |
| `\+` | 1 or more of preceding |
| `\?` | 0 or 1 of preceding |
| `\{n,m\}` | Between n and m of preceding |
| `\|` | Alternation (OR) |
| `\( \)` | Grouping |
| `\n` | Backreference |

### ERE (`-E`)

| Token | Meaning |
|-------|---------|
| `^`, `$`, `.`, `[...]`, `[^...]`, `*` | Same as BRE |
| `+` | 1 or more (no backslash) |
| `?` | 0 or 1 (no backslash) |
| `{n,m}` | Between n and m (no backslash) |
| `\|` | Alternation (no backslash) |
| `( )` | Grouping (no backslash) |

### PCRE (`-P`)

Adds `\d` (digit), `\w` (word), `\s` (whitespace), `\b` (word boundary), lookahead/lookbehind, non-greedy quantifiers (`*?`, `+?`), and more.

## Troubleshooting

### "Is a directory" error
Use `-r` for recursive search, or `-d skip` to silently skip directories.

### .git files showing up in results
`grep -r` traverses everything, including `.git`. Always add `--exclude-dir=".git"` when searching project trees.

### Binary file matches
Without `-a`, grep prints "Binary file X matches" instead of content. Use `-a` to force text output, or `-I` to silently skip binary files.

### No matches but you know the pattern exists
Check case sensitivity (`-i`), or whether you need `-E` for your regex, or whether the file is being treated as binary (`-a`).

## Notes

- **Default is BRE**, not ERE. Use `-E` for modern regex syntax without backslash escaping.
- **`-r` traverses .git by default** — always add `--exclude-dir=".git"` for project searches.
- **`-P` (Perl/PCRE) may not be available** on all systems. It works in the tested GNU grep 3.0 build. Fall back to `-E` for portability.
- **Exit codes**: `0` = match found, `1` = no match, `2` = error.
- **Use `$HOME` in paths**, never hardcode usernames. `"$HOME/.agents/demo/grep"` is portable.
- **Quote patterns with `*`, `?`, `[`, `!`** to prevent shell expansion. Single quotes are safest.
- **`-R` vs `-r`**: `-R` follows symbolic links; `-r` does not.
