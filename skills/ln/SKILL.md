---
name: ln
description: Use ln (GNU coreutils 8.32) for creating hard links and symbolic links. Use mklink (Windows native) as the reliable alternative when symlinks fail on MSYS2. Use when you need to mirror files without copying, create relative cross-directory references, or set up link farms.
---

# ln — Link Files (GNU coreutils 8.32) + mklink (Windows)

`ln` (GNU coreutils 8.32) creates hard links by default and symbolic links with `-s`. On MSYS2/Windows, symlink behavior depends on the `MSYS` environment variable. `mklink` (Windows cmd built-in) provides a native, always-reliable alternative.

## Quick Reference

| Task | Command |
|------|---------|
| Hard link (file mirror, same inode) | `ln TARGET LINK_NAME` |
| Symlink (MSYS2 real) | `MSYS=winsymlinks:nativestrict ln -s TARGET LINK_NAME` |
| Hard link, overwrite existing | `ln -f TARGET LINK_NAME` |
| Hard link, backup existing | `ln -b TARGET LINK_NAME` |
| Verbose (show each link) | `ln -v ...` |
| Symlink, relative path | `MSYS=winsymlinks:nativestrict ln -sr TARGET LINK_NAME` |
| Link multiple files into a directory | `ln TARGET... DIRECTORY` |
| Link into directory, explicit | `ln -t DIR TARGET...` |
| Treat LINK_NAME as file (not dir) | `ln -T ...` |
| Windows native symlink (file) | `cmd //c "mklink LINK TARGET"` |
| Windows native symlink (dir) | `cmd //c "mklink /D LINK TARGET"` |
| Windows native hard link | `cmd //c "mklink /H LINK TARGET"` |
| Windows native junction | `cmd //c "mklink /J LINK TARGET"` |

## Two Forms of ln

`ln` has four usage forms:

```bash
# 1. Named link — create LINK_NAME pointing to TARGET
ln [OPTIONS] TARGET LINK_NAME

# 2. Link in current directory — uses TARGET's basename
ln [OPTIONS] TARGET

# 3. Link multiple targets into a directory
ln [OPTIONS] TARGET... DIRECTORY

# 4. Explicit target directory
ln [OPTIONS] -t DIRECTORY TARGET...
```

## Hard Links (Default)

Hard links share the same inode — two names for the same file. Deleting one doesn't delete the data until all names are gone.

```bash
# Create a hard link
ln -v notes.txt hardlink.txt
# → 'hardlink.txt' => 'notes.txt'

# Both share the same inode
stat -c '%i %N' notes.txt hardlink.txt
# → 281474977317905 'notes.txt'
#   281474977317905 'hardlink.txt'

# Content is identical (not a copy — same bytes on disk)
cat hardlink.txt
# → hello main
```

**Hard links always work on Windows.** No MSYS configuration needed.

## Multiple Targets into a Directory

```bash
mkdir links_dir
ln -v notes.txt config.cfg tiny.txt links_dir/
# → 'links_dir/notes.txt' => 'notes.txt'
#   'links_dir/config.cfg' => 'config.cfg'
#   'links_dir/tiny.txt' => 'tiny.txt'

# Same with -t (explicit target directory)
ln -v notes.txt config.cfg -t links_dir/
```

**⚠️ Quirk (MSYS2):** `ln -s TARGET... DIR/` (trailing slash form) may fail with "No such file or directory". Use `ln -t DIR TARGET...` or `ln TARGET... DIR` (no trailing slash) instead.

## Symbolic Links (`-s`)

### Windows MSYS2 Behavior

On MSYS2/Windows, `ln -s` behavior is controlled by the `MSYS` environment variable. **Without it set, `ln -s` copies file contents** instead of creating a real symlink:

```bash
# ❌ Without MSYS setting: creates a regular file copy, NOT a symlink
ln -s notes.txt bad_link.txt
stat -c '%F' bad_link.txt   # → regular file
ls -la bad_link.txt          # → -rw-r--r-- (regular file, not lrwxrwxrwx)
```

```bash
# ✅ With MSYS=winsymlinks:nativestrict: creates a real Windows symlink
MSYS=winsymlinks:nativestrict ln -s notes.txt good_link.txt
stat -c '%F' good_link.txt   # → symbolic link
ls -la good_link.txt          # → lrwxrwxrwx ... good_link.txt -> notes.txt
cat good_link.txt             # → hello main
```

**Rule:** Always prepend `MSYS=winsymlinks:nativestrict` when using `ln -s` on Windows.

### Relative Symlinks (`-r`)

`-r` creates symlinks with relative paths instead of absolute — essential for portable link trees.

```bash
# Without -r: symlink stores the path exactly as given
MSYS=winsymlinks:nativestrict ln -s notes.txt src/link.txt
# src/link.txt -> notes.txt  (broken — looks for src/notes.txt!)

# With -r: computes the minimal relative path automatically
MSYS=winsymlinks:nativestrict ln -sr notes.txt src/link.txt
# src/link.txt -> ../notes.txt  (correct!)
```

Deep nesting:

```bash
MSYS=winsymlinks:nativestrict ln -sr notes.txt src/sub/deep_link.txt
# src/sub/deep_link.txt -> ../../notes.txt
```

### Windows Native: mklink

When `ln -s` gives trouble, `mklink` is the reliable Windows-native alternative:

```bash
# File symlink (same as ln -s)
cmd //c "mklink mylink.txt notes.txt"
# → 为 mylink.txt <<===>> notes.txt 创建的符号链接

# Directory symlink (same as ln -s for a directory target)
cmd //c "mklink /D mydir_link src"
# → 为 mydir_link <<===>> src 创建的符号链接

# Hard link (same as ln)
cmd //c "mklink /H myhard.txt notes.txt"
# → 为 myhard.txt <<===>> notes.txt 创建了硬链接

# Junction (directory hard-link-like reference, no admin required)
cmd //c "mklink /J myjunction src"
# → 为 myjunction <<===>> src 创建的联接
```

`mklink` uses the **current working directory** to resolve relative targets, just like `ln`.

## Force, Backup, and Interactive

### Force Overwrite (`-f`)

```bash
echo "existing" > file.txt
ln -fv notes.txt file.txt
# → 'file.txt' => 'notes.txt'
# Overwrites without asking.
```

### Backup Before Overwrite (`-b`)

```bash
echo "existing data" > backup_me.txt
ln -bv notes.txt backup_me.txt
# → 'backup_me.txt~' ~ 'backup_me.txt' => 'notes.txt'
# Original renamed to backup_me.txt~

cat backup_me.txt~
# → existing data
```

Custom suffix:

```bash
ln -bv -S .old notes.txt file.txt
# → 'file.txt.old' ~ 'file.txt' => 'notes.txt'

# Long form:
ln -bv --suffix=.bak notes.txt file.txt
```

Default backup suffix is `~`; override with `-S` or `--suffix`.

### Interactive (`-i`)

Prompts before overwriting:

```bash
echo "data" > maybe.txt
ln -iv notes.txt maybe.txt
# → ln: replace 'maybe.txt'?  (type 'y' or 'n')
```

## Form Control: `-T` and `-t`

### `-T` — Treat LINK_NAME as a file, never a directory

```bash
# Without -T: if LINK_NAME is a directory, ln places the link inside it
MSYS=winsymlinks:nativestrict ln -sv src existing_dir/
# → existing_dir/src -> src  (link created INSIDE existing_dir)

# With -T: LINK_NAME is always the link name itself
MSYS=winsymlinks:nativestrict ln -svT src link_name
# → link_name -> src  (even if link_name is a directory, it will fail)
```

### `-t` — Explicit target directory

```bash
# Instead of: ln TARGET... DIR
ln -vt mydir notes.txt config.cfg
# → 'mydir/notes.txt' => 'notes.txt'
#   'mydir/config.cfg' => 'config.cfg'
```

`-t` makes the directory argument unambiguous — useful in scripts.

## Dereference Control: `-L`, `-P`, `-n`

These control what happens when a TARGET (or LINK_NAME) is itself a symlink.

### `-P` (default) — Physical: link to the symlink itself

```bash
MSYS=winsymlinks:nativestrict ln -s notes.txt first_sym.txt
ln -Pv first_sym.txt hard_P.txt
# hard_P.txt and first_sym.txt share the same inode
# (hard link to the symlink, not to notes.txt)
```

### `-L` — Logical: dereference the symlink, link to its target

```bash
ln -Lv first_sym.txt hard_L.txt
# hard_L.txt and notes.txt share the same inode
# (hard link to the actual target)
```

`-s` overrides both `-L` and `-P`. The last one specified wins.

### `-n` — No dereference of LINK_NAME

When LINK_NAME is a symlink to a directory, `ln` normally dereferences it (placing the link inside). `-n` treats it as a regular file:

```bash
MSYS=winsymlinks:nativestrict ln -sv real_dir dir_sym
# dir_sym -> real_dir

# Without -n: ln dereferences dir_sym and puts the link inside
MSYS=winsymlinks:nativestrict ln -sv notes.txt dir_sym
# → dir_sym/notes.txt -> notes.txt

# With -n: ln replaces dir_sym itself (needs -f to overwrite)
MSYS=winsymlinks:nativestrict ln -sfvn notes.txt dir_sym
# → dir_sym -> notes.txt  (symlink itself is replaced)
```

## Paths with Spaces

```bash
# Quote filenames with spaces
ln -v "my notes.txt" "hard link to notes.txt"
# → 'hard link to notes.txt' => 'my notes.txt'

# In directories with spaces, quote the whole path
ln -v notes.txt "path with spaces/notes_link.txt"
# → 'path with spaces/notes_link.txt' => 'notes.txt'
```

## Flags Reference

```
-s, --symbolic            Create symbolic link instead of hard link
-f, --force               Remove existing destination files
-i, --interactive          Prompt before removing destinations
-v, --verbose              Print name of each linked file
-b, --backup               Backup each existing destination file
-S, --suffix=SUFFIX        Override the usual backup suffix (default: ~)
-t, --target-directory=DIR  Specify the directory in which to create links
-T, --no-target-directory   Treat LINK_NAME as a normal file always
-n, --no-dereference        Don't dereference LINK_NAME if it's a symlink to a dir
-P, --physical              Hard link directly to symbolic links (default)
-L, --logical               Dereference TARGETs that are symbolic links
-r, --relative              Create symlinks with relative paths
-d, -F, --directory         Allow superuser to hard link directories (usually fails)
```

## Common Recipes

```bash
# Mirror a file under a different name (no extra disk space)
ln -v original.txt duplicate.txt

# Create a temporary workspace linking many files
mkdir workspace
ln -t workspace notes.txt config.cfg tiny.txt

# Force-replace a symlink without asking
MSYS=winsymlinks:nativestrict ln -sfv /path/to/new/target current_link

# Portable symlink tree (relative paths)
MSYS=winsymlinks:nativestrict ln -srv shared/lib libs/project/lib
MSYS=winsymlinks:nativestrict ln -srv shared/config config/app/config

# Windows-native: quick directory junction (like a hard link for dirs)
cmd //c "mklink /J node_modules_link ..\shared\node_modules"

# Backup before overwriting a critical symlink
MSYS=winsymlinks:nativestrict ln -sbv new.target critical.link
```

## Notes

- **Hard links never cross filesystem boundaries.** You can't hard-link from `C:\` to `D:\` or `/c` to `/d`.
- **`ln -s` on MSYS2 without `MSYS=winsymlinks:nativestrict` copies file contents** instead of creating a symlink. Always set the variable when you need real symlinks.
- **`mklink` is the Windows-native fallback.** When `ln -s` misbehaves (even with MSYS setting), `cmd //c "mklink ..."` is reliable.
- **Symlinks require Developer Mode or admin** on Windows. `mklink /J` (junction) works without admin and behaves like a directory hard link.
- **`-r` computes relative paths automatically** — prefer it for symlinks that must work when the tree is moved.
- **`-s` overrides `-L` and `-P`.** When creating symlinks, these dereference flags are ignored.
- **Use `$HOME` in paths, never hardcode usernames.** `"$HOME/.agents/demo/ln"` is portable; `/c/Users/76288/...` is not.
- **Quote names with spaces** in the shell. Single-quote `!` and `*` to prevent expansion.
