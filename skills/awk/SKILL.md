---
name: awk
description: Use GNU awk (5.4.0) for field-based text processing — column extraction, arithmetic, conditional filtering, multi-line records. Prefer awk over sed when fields matter. Use when you need to slice, sum, or transform structured text.
---

# awk — GNU Awk Text Processor

`awk` v5.4.0 (GNU Awk). In MSYS2/Git Bash at `/usr/bin/awk`. Use for field-based text processing, arithmetic operations, conditional logic, and record-oriented transformations. Stronger than `sed` when columns, numbers, or multi-condition logic are involved.

## ⚠️ `awk -i inplace` Destroys Links

`awk -i inplace` creates a temp file and renames it over the original — identical mechanism to `sed -i`. This means:

| Link type | `awk -i inplace` behavior |
|-----------|---------------------------|
| **Hard link** | ❌ **Broken** — target gets new inode, other links see stale data |
| **Symlink to file** | ❌ **Symlink destroyed** — replaced with a regular file |
| **File via symlinked dir** | ✅ Safe — dir symlink preserved, target file modified |

```bash
# Evidence: same inode before, different after
# Before:
#   base.txt  Inode: 3377  Links: 2
#   peer.txt  Inode: 3377  Links: 2
awk -i inplace '{print "MOD: " $0}' base.txt
# After:
#   base.txt  Inode: 2251  Links: 1   ← NEW file
#   peer.txt  Inode: 3377  Links: 1   ← stale, sees old data
```

**Without `INPLACE_SUFFIX`**, the temp file is renamed over the original — the old inode is orphaned (if no other hard links reference it) or left with stale content for remaining links.

**With `INPLACE_SUFFIX=.bak`**, the original is renamed to `file.bak` (preserving its inode), then a new file is written. The `.bak` file and any peer hard links share the same old inode:

```bash
awk -i inplace -v INPLACE_SUFFIX=.bak '{print "CHANGED: " $0}' base.txt
# base.txt     → new inode (modified content)
# base.txt.bak → old inode (original content, shared with peer.txt)
# peer.txt     → old inode (stale, sees original content)
```

### Link-Safe Alternative

```bash
# Preserves hard links and symlinks — writes through the existing inode
awk '{print "SAFE: " $0}' file > file.tmp && cat file.tmp > file && rm file.tmp
```

The `cat >` redirect opens the existing file inode and writes to it directly. No temp-file-rename dance.

Always verify with `stat` after editing files that may be hard-linked or symlinked:

```bash
stat file_a.txt file_b.txt | grep -E "File:|Inode:|Links:"
# Same Inode, Links: 2 → linked ✅
# Different Inode, Links: 1 → broken ❌
```

## Basic Usage

```bash
# Print specific fields (whitespace-delimited by default)
awk '{print $1, $3}' file.txt          # columns 1 and 3
awk '{print $NF}' file.txt             # last field
awk '{print $(NF-1)}' file.txt         # second-to-last field

# Field separator
awk -F: '{print $1, $7}' /etc/passwd   # colon-separated
awk -F'\t' '{print $2}' file.tsv        # tab-separated
awk -F'[,;]' '{print $1}' file.csv      # multiple separators

# Condition + action
awk '$3 > 100 {print $1, $3}' data.txt          # filter rows
awk 'NR >= 5 && NR <= 10 {print}' file.txt       # line range
awk '/pattern/ {print $0}' file.txt              # grep-like
awk '!/skip/ {print}' file.txt                   # inverted match
awk 'NF > 0 {print}' file.txt                    # skip blank lines
```

## Extended Patterns (GAWK)

```bash
# BEGIN / END blocks
awk 'BEGIN {print "Header"} {print $0} END {print "Footer"}' file.txt

# Arithmetic
awk '{sum += $1} END {print "Total:", sum}' numbers.txt
awk '{count++; total += $3} END {print total/count}' data.txt

# String operations
awk '{gsub(/old/, "new"); print}' file.txt       # global replace
awk '{sub(/^prefix/, ""); print}' file.txt        # strip prefix
awk 'length($0) > 80 {print NR, length($0)}'      # long-line checker
awk '{print toupper($1), tolower($2)}' file.txt

# Multi-line records (paragraph mode)
awk 'BEGIN {RS=""} /keyword/ {print $0}' file.txt
```

## Common Recipes

```bash
# Sum a column, print average
awk '{sum+=$2; n++} END {printf "Sum: %d, Avg: %.2f\n", sum, sum/n}' data.tsv

# Extract unique values from column 3
awk '{print $3}' file.txt | sort -u

# Reorder columns
awk '{print $3, $1, $2}' file.txt

# Remove lines containing any of several patterns
awk '!/error/ && !/warn/ && !/debug/' log.txt

# Print lines between two patterns (inclusive)
awk '/START/,/END/' file.txt

# Print with line numbers (like `cat -n`)
awk '{printf "%4d  %s\n", NR, $0}' file.txt

# Convert CSV to TSV
awk -F, -v OFS='\t' '{print $1, $2, $3}' file.csv > file.tsv

# Add prefix to each line of a hard-linked file (link-safe)
awk '{print "PREFIX: " $0}' file > file.tmp && cat file.tmp > file && rm file.tmp

# Strip version prefix from paths (MSYS2: double-escape backslashes)
awk '{sub(/.*\\\\1.21.5_1.21.8\\\\/, ""); print}' paths.txt
```

## Notes

- **Field references**: `$0` = whole line, `$1`..`$NF` = individual fields, `NF` = field count, `NR` = record (line) number.
- **Default field separator** is any whitespace (spaces/tabs). Use `-F` to override.
- **`-v VAR=val`** sets variables before processing begins (e.g., `-v threshold=50`).
- **On MSYS2**, backslashes in paths need double-escaping in regex: `\\\\` produces a literal `\`.
- **Prefer awk over sed when**: you need arithmetic, field-based logic, multi-condition filtering, or formatted output.
- **Prefer sed over awk when**: you only need simple search-and-replace with no field math.
- For complex scripts, use a file: `awk -f script.awk input.txt`.
