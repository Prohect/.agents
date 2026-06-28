---
name: cat
description: Use cat (and shell redirects) for safe file reads and writes that preserve hard links and symlinks. Use when you need to read or overwrite a file without breaking links — unlike sed -i which destroys them.
---

# cat & Shell Redirects — Link-Safe File I/O

Unlike `sed -i`, shell redirect operators (`>`, `>>`) and `cp` **preserve hard links and symlinks**. They open the existing file inode and write to it directly, rather than creating a temp file and renaming.

## Link Safety Matrix

| Operation | Hard link | File symlink | Symlink dir |
|-----------|:---:|:---:|:---:|
| `cat file` (read only) | ✅ | ✅ | ✅ |
| `echo "..." > file` | ✅ preserves | ✅ preserves, writes target | ✅ |
| `echo "..." >> file` | ✅ preserves | ✅ preserves, appends to target | ✅ |
| `cp source file` | ✅ preserves | ✅ preserves, writes target | ✅ |
| `head -n N > file` | ✅ preserves | ✅ preserves | ✅ |
| `sed 's/.../.../' file` (no `-i`) | ✅ reads only | ✅ | ✅ |
| `sed -i 's/.../.../' file` | ❌ **breaks** | ❌ **destroys** | ✅ |

**Rule**: any command that opens the existing file and writes to its inode is safe. `sed -i` is the dangerous outlier because it creates a temp file + renames.

## Verify After Writing

```bash
stat file_a.txt file_b.txt | grep -E "File:|Inode:|Links:"
# Same Inode, Links: 2 → linked ✅
# Different Inode, Links: 1 → broken ❌
```

## Common Patterns

```bash
# Safe: overwrite file preserving hard link
echo "new content" > hardlinked_file.txt

# Safe: replace specific line via grep + redirect
grep -v "old_line" file.txt > file.txt.tmp && mv file.txt.tmp file.txt
# NOTE: mv also preserves inode if destination exists (it overwrites inode)

# Safe: append
echo "new line" >> config.ini

# DANGER: breaks links
sed -i 's/old/new/' hardlinked_file.txt
```

## Use cat as Quick File Reader

`cat` from `terminal` is the universal escape hatch when `read_file` can't reach a file (outside project root, or in `~/.agents/errors/` but not `skills/`):

```bash
cat "C:/Users/76288/AppData/Roaming/Zed/AGENTS.md"      # outside project
cat "C:/Users/76288/.agents/errors/.../SOLUTION.md"      # errors dir (not skills)
cat "F:/source/forks/zed/README.md"                       # sibling project
```
