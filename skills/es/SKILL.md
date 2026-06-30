---
name: es
description: Use ES (Everything Search 1.1.0.30) for instant filename/path search on Windows. Use when you need to find files by name, extension, path pattern, or sort by size/date — orders of magnitude faster than `find` or recursive `ls`.
---

# es — Everything Search CLI

`es.exe` v1.1.0.30, the command-line interface to Voidtools Everything. Searches filenames and paths via the Everything index — instant results, even across the entire filesystem. Use it whenever you need to locate files or directories by name, extension, or path pattern.

## Quick Reference

| Task | Command |
|------|---------|
| Find by extension | `es -path "$HOME/proj" "*.java"` |
| Exclude `.git` noise | `es -path "$HOME/proj" '!path:git'` |
| Files only | add `file:` to search |
| Folders only | add `folder:` to search |
| Sort by size (largest first) | `-sort-size-descending` |
| Sort by date (newest first) | `-sort-date-modified-descending` |
| Limit results | `-n 50` |
| Show size column | `-size` |
| Show date column | `-date-modified` (or `-dm`) |
| Match path (not just name) | `-match-path` (or `-p`) |
| Regex search | `-regex "pattern"` |
| Case-sensitive | `-case` |
| Count results only | `-get-result-count` |

## Basic Search

```bash
# All .java files under a directory
es -path "$HOME/.agents/demo/es" "*.java"
# → src/Main.java, src/special file.java, test/TestHelper.java, src/Utils.java

# Using Everything ext: syntax (same result)
es -path "$HOME/.agents/demo/es" "ext:java"

# Match anywhere in the path, not just filename
es -path "$HOME/.agents/demo/es" -match-path "test"
# → test/ (directory), test/test_main.rs, test/TestHelper.java

# Short form of -match-path
es -path "$HOME/.agents/demo/es" -p "test"
```

## Filtering: Files vs Folders

```bash
# Files only — add `file:` to the search
es -path "$HOME/.agents/demo/es" file:

# Folders only — add `folder:` to the search
es -path "$HOME/.agents/demo/es" folder:

# Combine with other filters
es -path "$HOME/.agents/demo/es" "ext:java" file:       # .java files only, no dirs
es -path "$HOME/.agents/demo/es" "test" folder:         # directories matching "test"
```

**Note:** The `/ad` (folders only) and `/a-d` (files only) DIR-style switches are documented but may not work reliably in all ES/Everything configurations. Prefer `file:` and `folder:` in the search text.

## Excluding Noise

The `!` prefix negates a search term. Use Everything's function syntax for precise exclusions:

```bash
# Exclude anything with ".git" in the path
es -path "$HOME/.agents/demo/es" '!path:git'

# Exclude multiple patterns — chain ! terms
es -path "$HOME/proj" '!path:git' '!path:node_modules' '!path:target'

# Exclude hidden files
es -path "$HOME/proj" '!attrib:H'
```

**Shell safety:** Wrap `!` terms in single quotes to prevent history expansion in bash. In sh (the default shell) both single and double quotes are safe.

## Sorting & Limiting

```bash
# Largest files first (great for finding disk hogs)
es -path "$HOME/.agents/demo/es" -sort-size-descending -size -n 5
# → 51,200  resources/large.bin
#      38  error.log
#      33  server.log
#      33  src/main.rs
#      23  src/Utils.java

# Most recently modified first (what changed recently?)
es -path "$HOME/.agents/demo/es" -sort-date-modified-descending -date-modified '!path:git' file: -n 5
# → 2026/06/29 22:18  test/test_main.rs
#   2026/06/29 22:18  test/TestHelper.java
#   2026/06/29 22:18  resources/tiny.txt
#   ...

# Sort ascending (oldest/smallest first)
es -path "$HOME/.agents/demo/es" -sort-size-ascending -size -n 3
```

Available sort keys: `name`, `path`, `size`, `extension`, `date-created`, `date-modified`, `date-accessed`, `attributes`, `run-count`, `date-recently-changed`, `date-run`.

## Display Columns

By default, `es` prints only the full path. Add columns to see metadata:

```bash
es -path "$HOME/.agents/demo/es" -size -extension "*.java"
# → 23 java  src/Main.java
#    7 java  src/special file.java
#   12 java  test/TestHelper.java
#   23 java  src/Utils.java

# Common column flags (and short forms):
#   -size              file size
#   -date-modified, -dm   last modified date
#   -date-created, -dc    creation date
#   -extension, -ext      file extension
#   -full-path-and-name   full path + filename (default)
```

Size formatting:
```bash
es -path "$HOME/.agents/demo/es" -size -size-format 2 -sort-size-descending -n 2
# → 50 KB  resources/large.bin
#    1 KB  error.log
# -size-format: 0=auto, 1=Bytes, 2=KB, 3=MB
```

## Regex & Case Sensitivity

`-regex` enables Everything's regex engine. By default regex matches the filename only (use `-match-path` to match against the full path). Searches are **case-insensitive** unless `-case` is added.

### Regex Syntax Reference

| Syntax | Meaning |
|--------|---------|
| `a\|b` | Match `a` or `b` |
| `.` | Match any single character |
| `[abc]` | Match any single character: `a`, `b`, or `c` |
| `[^abc]` | Match any single character except `a`, `b`, `c` |
| `[a-z]` | Match any single character in range `a` through `z` |
| `[a-zA-Z]` | Match any single character in range `a`–`z` or `A`–`Z` |
| `^` | Match start of filename |
| `$` | Match end of filename |
| `( )` | Capturing group for backreferences (see below) |
| `\n` | Backreference to the nth captured group (`n` = 1–9) |
| `\b` | Match word boundary |
| `*` | Match preceding element 0 or more times |
| `?` | Match preceding element 0 or 1 time |
| `+` | Match preceding element 1 or more times |
| `*?` | Match preceding element 0 or more times (lazy) |
| `+?` | Match preceding element 1 or more times (lazy) |
| `{x}` | Match preceding element exactly `x` times |
| `{x,}` | Match preceding element `x` or more times |
| `{x,y}` | Match preceding element between `x` and `y` times |
| `\` | Escape special characters (e.g., `\.` for literal dot) |

### Verified Examples

```bash
# Alternation — use | without parentheses
es -path "$HOME/.agents/demo/es" -regex "Main|Utils"
# → src/Main.java, src/main.rs, test/test_main.rs, src/Utils.java

# Character class
# (Note: .java works in character class; . is literal here)
es -path "$HOME/.agents/demo/es" -regex "[er].*\.log"
# → error.log, server.log

# Start anchor ^ (matches start of filename)
es -path "$HOME/.agents/demo/es" -regex "^M.*\.java"
# → src/Main.java

# Negated character class
# Match .java files NOT starting with M
es -path "$HOME/.agents/demo/es" -regex "^[^M].*\.java"
# → src/special file.java, test/TestHelper.java, src/Utils.java

# End anchor $ (match by extension)
es -path "$HOME/.agents/demo/es" -regex "\.rs$"
# → src/main.rs, test/test_main.rs

# ? quantifier (optional preceding element)
es -path "$HOME/.agents/demo/es" -regex "errors?\.log"
# → error.log

# Capturing groups + backreferences
# Match filenames where first char repeats later (files only)
es -path "$HOME/.agents/demo/es" -regex "^(.).*\1" file:
# → test/test_main.rs, test/TestHelper.java, CamelCaseFile.txt, resources/tiny.txt

# Case-sensitive regex
es -path "$HOME/.agents/demo/es" -case -regex "Main"
# → src/Main.java
```

### Important: `( )` is for backreferences, not alternation

Everything's regex engine treats `(...)` as a **capturing group** for use with `\1`–`\9` backreferences. It does **not** support `(a|b)` for alternation grouping.

```bash
# ✅ Works — bare alternation with wildcard dot
es -path "$HOME/.agents/demo/es" -regex "Main.java|Utils.java"

# ❌ Does NOT work — parentheses not supported for alternation grouping
es -path "$HOME/.agents/demo/es" -regex "(Main|Utils).java"
```

**⚠️ Quirk:** An escaped dot (`\.`) or bracket dot (`[.]`) **before** `|` breaks alternation — only the first alternative matches. Use an unescaped `.` (wildcard) in alternation patterns, or restructure the regex:

```bash
# ❌ Broken — escaped dot before | drops second alternative
es -path "$HOME/.agents/demo/es" -regex "error\.log|server\.log"
# → error.log only (server.log dropped)

# ✅ Fixed — use unescaped . (wildcard) in alternation
es -path "$HOME/.agents/demo/es" -regex "error.log|server.log"
# → error.log, server.log

# ✅ Fixed — use $ anchor (safe with \. at end)
es -path "$HOME/.agents/demo/es" -regex "error\.log$|server\.log$"
# → error.log, server.log
```

## Counting & Sizing

```bash
# How many Java files?
es -path "$HOME/.agents/demo/es" -get-result-count "ext:java"
# → 4

# Total size of all matching files
es -path "$HOME/.agents/demo/es" -get-total-size "ext:java"
```

## Paths with Spaces

```bash
# Double-quote output — safe for piping to xargs
es -path "$HOME/.agents/demo/es" -double-quote "notes"
# → "C:\Users\...\demo\es\my notes.txt"

# Pipe to xargs (strip \r on Windows first):
es -path "$HOME/.agents/demo/es" -double-quote "notes" | tr -d '\r' | xargs cat
```

## CSV / Machine-Readable Output

```bash
es -path "$HOME/.agents/demo/es" -csv "ext:java"
# → Filename
#   "C:\Users\...\src\Main.java"
#   "C:\Users\...\src\special file.java"
#   "C:\Users\...\test\TestHelper.java"
#   "C:\Users\...\src\Utils.java"
```

Other formats: `-efu` (Everything File List), `-txt`, `-m3u`/`-m3u8` (playlists), `-tsv`.

## Common Recipes

```bash
# What are the biggest files in a project? (exclude .git noise)
es -n 20 -sort size-descending -size -path "$HOME/proj" '!path:git'

# What changed recently? (files only, last 30)
es -n 30 -sort date-modified-descending -dm '!path:git' -path "$HOME/proj" file:

# Find all Rust source files, sorted by path
es -path "$HOME/proj" -s "ext:rs"

# Count files by extension in a directory
es -path "$HOME/proj" -get-result-count "ext:rs"   # Rust
es -path "$HOME/proj" -get-result-count "ext:java" # Java

# Find files with "config" in the path, case-insensitive
es -path "$HOME/proj" -match-path "config"

# Export a file list to CSV for scripting
es -path "$HOME/proj" -export-csv files.csv "ext:java"
```

## Troubleshooting

### Error 8: Everything IPC window not found

`es.exe` is a thin CLI client that talks to the Everything GUI via IPC. If the Everything application isn't running, `es` has nothing to talk to and exits with code 8.

**Fix:** 
```bash
# Run "Everything" in the background
everything -startup
```
If it's not in your $PATH, ask the user the full path and document it below or add it to $PATH if the contents of the parent directory of everything.exe seems clean.

### Stale index: `-reindex`

If results seem out of date, force a fresh scan via flag `-reindex` before querying:

```bash
es -reindex; es -path "$HOME\.agents\demo\es" "*.java"
```

## Notes

- **`es` is index-based.** It queries the Everything database, not the filesystem. Results are instant but reflect the last index scan. Use `es -reindex` to force a rescan before querying.
- **Windows paths use backslashes.** `es` outputs backslashes (`C:\Users\...`). For shell pipelines, forward slashes work for most tools but not all.
- **`\r\n` line endings.** On Windows, `es` output lines end with `\r\n`. Pipe through `tr -d '\r'` before feeding to `xargs` or other Unix tools.
- **Use `$HOME` in paths, never hardcode usernames.** `"$HOME/.agents/demo/es"` is portable; `"C:\Users\username\..."` is not.
- **Quote `!` and `*` in search terms.** Single quotes (`'!path:git'`, `'*.java'`) prevent shell expansion and work in all shells.
- **Omit `-n` to return all results.** The default has no upper limit. Use `-n <num>` to cap results. Avoid `-n 0` (it returns zero results).
- **Combine filters in the search text.** `es -path "..." "ext:java" file: "Main"` finds Java files containing "Main" in the name. Each space-separated token is AND-ed together.
- **`-s` sorts by full path** (shortcut for `-sort-path-ascending`).
- **`-no-result-error`** sets a non-zero exit code when no results are found — useful in scripts.
