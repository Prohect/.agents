---
name: sed
description: Use GNU sed (4.9) for stream editing — search and replace, in-place file modification, text filtering. Use when you need to transform text in files or pipelines, especially when a simple string replace is all that's needed.
---

# sed — GNU Stream Editor

`sed` v4.9 (GNU). Present in the MSYS2/Git Bash environment. Use for text replacement, deletion, insertion, and filtering in files or pipelines.

## ⚠️ `sed -i` Destroys Links

`sed -i` creates a temp file and renames it over the original. This means:

| Link type | `sed -i` behavior |
|-----------|-------------------|
| **Hard link** | ❌ **Broken** — target gets new inode, other links see old data |
| **Symlink to file** | ❌ **Symlink destroyed** — replaced with a regular file |
| **File via symlinked dir** | ✅ Safe — dir symlink preserved, target file modified |

Always verify with `stat` after `sed -i` on files that may be hard-linked or symlinked.

```bash
# Check if hard links survived
stat file_a.txt file_b.txt | grep -E "Inode:|Links:"
# Same Inode, Links: 2 → linked ✅
# Different Inode, Links: 1 → broken ❌
```

If you need to edit a hard-linked file without breaking the link, use `cat >` with a redirect, or `cp` then `ln -f`.

## Basic Usage

```bash
# Replace first occurrence on each line
sed 's/old/new/' file.txt

# Replace all occurrences on each line
sed 's/old/new/g' file.txt

# In-place edit (CAUTION: see above)
sed -i 's/old/new/g' file.txt

# Delete lines matching pattern
sed '/pattern/d' file.txt

# Print only lines matching pattern
sed -n '/pattern/p' file.txt

# Replace on specific line numbers
sed '3,5s/old/new/g' file.txt
```

## Common Recipes

```bash
# Strip version prefix from paths (backslashes need double-escape in MSYS2)
sed 's|.*\\\\1.21.5_1.21.8\\\\||' files.txt

# Remove .git noise from es output
sed '/\\\\\.git\\\\/d'

# Change specific config value
sed -i 's/^max_players=.*/max_players=20/' server.properties

# Insert line before match
sed -i '/pattern/i\new line' file.txt

# Append line after match
sed -i '/pattern/a\new line' file.txt
```

## Notes

- On MSYS2, backslashes in paths need double-escaping: `\\\\` produces a literal `\` in the regex.
- `-i` without a backup suffix (like `-i.bak`) creates no backup — the original is gone.
- Pipe-friendly: `echo "text" | sed 's/.../.../'` works as expected.
- For complex multi-line transformations, prefer a script file: `sed -f script.sed file.txt`.
