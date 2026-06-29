**Load the `errors` Skill first encountering new tool call error**

Load errors Skill when any tool call (builtin, CLI, MCP, Skill-introduced CLI) throws an new(not appearing in context) error.

**Read Tool Scope**

| tool | scope | gitignore-aware |
|------|-------|:----------:|
| `read_file` / `list_directory` | project roots + `~/.agents/skills/` only | sees all |
| `grep` / `find_path` | project roots only | skips `.gitignore` + `.git/info/exclude` |
| *`terminal` cat/grep/ls/find* | anywhere (stupidly slow working on large file trees) | sees all |
| `es` (Everything Search) | anywhere (filenames, full absolute paths, no file content, but stupidly fast working on any file trees) | sees all |


**Search efficiently**

*`terminal` ls* is slow on large trees and requires recursive tool calls. **always use `es` instead**:

1. **`es`** - find likely files by filename, path (`-match-path`, `-path`), sort by size/date (`-sort`) - instant, index-based
2. ***`terminal` grep*** - now grep a single file or small subtree, not the whole forest

eg. To search inside gitignore dirs (e.g. `mc-decompile-sources/`), use `es` to find files/dirs by filename or path, then *`terminal` grep* to read content.

**Directory exploration: `es` Skill**

`es` gives the whole tree ranked:
- `es -n 50 -sort size-descending -size -path "..."`
- `es -n 50 -sort date-modified-descending -dm '!path:git' -path "..."` - what's changed recently
- Exclude noise: `'!path:git'` to suppress `.git`, filter by extension (`*.java`) to narrow further

**While using `terminal`, never create or redirect to file named:** `nul`, `con`, `prn`, `aux`, `com1`–`com9`, `lpt1`–`lpt9` - these are Windows reserved device names.

**Check branches and list root**

Always start with this to know where you are and what the project looks like:

```bash
git --no-pager branch --show-current; echo " "; git --no-pager branch --sort=-committerdate | head -n 50;
```

Then call `list_directory` on the project root to see the top-level structure. If the project seems to have some directories, **load the `es` Skill** - it could give you the whole sorted tree in one call.

**Never push without permission**

Local commits are always allowed - they're safe, local version control. But `git push` (and `gh` operations or mcp tools that write to remotes) require explicit user permission. Ask before pushing.
