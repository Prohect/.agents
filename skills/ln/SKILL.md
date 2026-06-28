---
name: ln
description: Use GNU ln (coreutils 8.32) for creating hard links and symbolic links on Windows. Use when you need to deduplicate files, create lightweight file clones that share disk blocks, set up symlink-based project structures, or manage link-based build artifacts.
---

# ln — GNU coreutils Link Utility for Windows

`ln.exe` is a Windows port of GNU coreutils `ln` (v8.32). It creates hard links and symbolic links on Windows — a direct replacement for `mklink` (cmd built-in) and `New-Item -ItemType SymbolicLink` (PowerShell).

Located at: `E:/Programme Files/commandLineInterface/ln.exe`

## Hard Links (no elevation needed)

Hard links point to the same file data (inode) on disk. Both names are equal peers — modify through either, delete either, the data survives until the last link is removed.

```bash
ln target.txt link.txt
# target.txt and link.txt share the same inode
# stat shows Links: 2 for both files
```

**This always works** — no admin, no Developer Mode required. The only constraint: both files must be on the same NTFS volume.

Verify with `stat`:
```bash
stat file_a.txt file_b.txt | grep Inode
# Same Inode → hard links (one copy on disk)
# Different Inode → separate files (actual copies)
```

## Symbolic Links (requires elevation — Developer Mode does NOT help `ln`)

**Key finding**: GNU `ln -s` on Windows **always** needs elevation to create real symlinks. Even with Developer Mode enabled, `ln -s` silently falls back to copying. This is a limitation of the GNU port — it does not use the same API as `mklink`, which does respect Developer Mode.

| Method | Non-elevated | Elevated (RunAs admin) |
|--------|-------------|----------------------|
| `ln -s` (even with Dev Mode) | ❌ copy | ✅ real symlink |
| `mklink` (with Dev Mode) | ✅ real symlink | ✅ real symlink |

### Check what you're getting

Always verify with `stat` — if it says `regular file`, you got a copy, not a symlink:

```bash
ln -s target.txt test.txt
stat test.txt | head -20
# "regular file" → silently copied, NOT a symlink!
# "symbolic link" → real symlink
```

### Create symlinks: spawn elevated `ln.exe` directly

Use PowerShell's `Start-Process -Verb RunAs` to launch `ln.exe` directly as admin:

```bash
# The one reliable way to make ln -s create real symlinks:
powershell -Command "Start-Process -FilePath 'E:\Programme Files\commandLineInterface\ln.exe' \
  -ArgumentList '-s','-v','F:\full\path\target.txt','F:\full\path\symlink.txt' \
  -Verb RunAs -Wait"
```

A UAC prompt will appear. Once approved, `ln.exe` runs elevated and creates a real NTFS symlink.

### Using relative paths as targets

Pass a relative path directly as the TARGET argument:

```bash
# From an elevated context:
ln -s target.txt sym.txt
# stat shows: sym.txt -> target.txt (symbolic link)
```

## Usage Forms

```
ln [OPTION]... TARGET LINK_NAME        # 1st form: named link
ln [OPTION]... TARGET                   # 2nd form: link in current dir (same name)
ln [OPTION]... TARGET... DIRECTORY      # 3rd form: link multiple into directory
ln [OPTION]... -t DIRECTORY TARGET...   # 4th form: -t variant of above
```

## Key Options

| Flag | Long | Effect |
|------|------|--------|
| `-s` | `--symbolic` | Create symbolic link (needs elevation) |
| `-f` | `--force` | Remove existing destination before linking |
| `-v` | `--verbose` | Print each link operation |
| `-b` | `--backup` | Backup existing dest as `filename~` before overwriting |
| `-t DIR` | `--target-directory=DIR` | Create all links inside DIR |
| `-T` | `--no-target-directory` | Treat LINK_NAME as file, not directory |
| `-n` | `--no-dereference` | Treat symlink-to-directory as a regular file |
| `-i` | `--interactive` | Prompt before overwriting |
| `-d` | `--directory` | Attempt directory hard-link (will fail on Windows) |

## Practical Recipes

### Hard Link Build Artifacts

```bash
# Link all .dll files from build output into a lib folder (no copy, shared disk blocks)
ln -v -t lib/ build/*.dll
```

### Force Overwrite with Backup

```bash
ln -b -f new_config.ini config.ini
# Old config.ini → config.ini~ (backup)
# config.ini is now a hard link to new_config.ini
```

### Link Single File into Current Directory

```bash
cd target_dir
ln /path/to/source_file.txt
# Creates ./source_file.txt as hard link
```

### Create Symlink (elevated — the only way for `ln`)

```bash
# From non-elevated shell, spawn elevated ln.exe directly:
powershell -Command "Start-Process -FilePath 'E:\Programme Files\commandLineInterface\ln.exe' \
  -ArgumentList '-s','-v','F:\source\project\config.json','F:\source\project\config_link.json' \
  -Verb RunAs -Wait"

# Or use mklink instead (no elevation needed if Developer Mode is on):
cmd //c "mklink F:\source\project\config_link.json F:\source\project\config.json"
```

## Developer Mode

Developer Mode (Settings → Privacy & Security → For Developers → On) enables `mklink` without elevation, but does **not** help `ln -s`. GNU `ln` still requires `Start-Process -Verb RunAs` for symlinks.

If you need symlinks often without UAC, use `cmd //c mklink` instead of `ln -s`.

## Constraints & Gotchas

- **Hard links**: Same NTFS volume only. Cannot hard-link directories (`ln -d` → "Operation not permitted").
- **Symlinks without elevation**: `ln -s` silently creates a **copy**, not a symlink. Even Developer Mode doesn't fix this (only `mklink` respects it). The only way to get real symlinks via `ln` is `Start-Process -Verb RunAs`. Always verify with `stat`: `regular file` = copy, `symbolic link` = real.
- **Cross-volume**: Hard links fail across volumes. Use symlinks (with elevation) for cross-volume linking.
- **Verbose output**: The `'link' => 'target'` format tells you what was created.
- **Temp files**: Clean up test links with `rm` — the data survives until all hard links are removed.
