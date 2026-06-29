**Load the `errors` Skill first encountering new tool call error**

Load errors Skill when any tool call (builtin, CLI, MCP, Skill-introduced CLI) throws an new(not appearing in context) error.

**Read Tool Scope**

| tool | scope | gitignore-aware |
|------|-------|:----------:|
| `read_file` / `list_directory` | project roots + `~/.agents/skills/` only | sees all |
| `grep` / `find_path` | project roots only | skips `.gitignore` + `.git/info/exclude` |
| `terminal` (cat/grep/ls/find) | anywhere (stupidly slow working on large file trees) | sees all |
| `es` (Everything Search) | anywhere (filenames, full absolute paths, no file content, but stupidly fast working on any file trees) | sees all |


**Search excluded dirs efficiently**

`terminal` grep / ls is slow on large trees. **always use `es` instead**:

1. **`es`** - find likely files by filename, path (`-match-path`, `-path`), sort by size/date (`-sort`) - instant, index-based
2. **`list_directory`** - only when interested
3. **`terminal` grep** - now grep a single file or small subtree, not the whole forest

eg. To search inside excluded dirs (e.g. `mc-decompile-sources/`), use `es` to find files/dirs by filename or path, then `terminal` grep to read content.

**Directory exploration: prefer `es` over `list_directory`**

`list_directory` shows a single level, unsorted. `es` gives the whole tree ranked - use it as a "project tail":
- `es -n 50 -sort size-descending -size -path "..."` - biggest files = project skeleton
- `es -n 50 -sort date-modified-descending -dm '!path:git' -path "..."` - what changed recently
- Exclude noise: `'!path:git'` to suppress `.git`, filter by extension (`*.java`) to narrow further

**While using `terminal` commands, never create or redirect to files named:** `nul`, `con`, `prn`, `aux`, `com1`–`com9`, `lpt1`–`lpt9` - these are Windows reserved device names. Windows Explorer and many tools can't delete/rename them. (If one exists, `terminal` `rm` can remove it via POSIX path bypass.)

**Check branches and list root**

Always start with this to know where you are and what the project looks like:

```bash
git --no-pager branch --show-current; echo " "; git --no-pager branch --sort=-committerdate | head -n 50;
```

Then call `list_directory` on the project root to see the top-level structure.

After checking branches and calling `list_directory`, if the project seems to have directories or more than a handful of files, **load the `es` Skill** - it gives you the whole tree ranked in one shot, way faster than `list_directory`.

**Never push without permission**

Local commits are always allowed - they're safe, local version control. But `git push` (and `gh` operations that write to remotes) require explicit user permission. Ask before pushing.
