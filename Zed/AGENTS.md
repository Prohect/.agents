**Read Tool Scope**

| tool                           | scope                                    |             gitignore-aware              |
| ------------------------------ | ---------------------------------------- | :--------------------------------------: |
| `read_file` / `list_directory` | project roots + `~/.agents/skills/` only |                 sees all                 |
| `grep` / `find_path`           | project roots only                       | skips `.gitignore` + `.git/info/exclude` |
| _`terminal` cat/grep/ls/find_  | anywhere (slow on large file trees)      |                 sees all                 |
| _`terminal` es_                | anywhere (files, directories, **fast**)  |                 sees all                 |

**Search efficiently: _`terminal` es_**
**Search efficiently: _`terminal` es_**

_`terminal` ls_ is slow on large trees and requires recursive tool calls. **use _`terminal` es_ instead**:

eg. To search inside gitignore path (e.g. `minecraft-decompile-sources/`), use _`terminal` es_ to find files/directories by filename or path, then _`terminal` grep_ to read content

**While using `terminal`, never create or redirect to file named:** `nul`, `con`, `prn`, `aux`, `com1`-`com9`, `lpt1`-`lpt9` - these are Windows reserved names.
**While using `terminal`, never create or redirect to file named:** `nul`, `con`, `prn`, `aux`, `com1`-`com9`, `lpt1`-`lpt9` - these are Windows reserved names.

**While using `terminal` <tool>, load `<tool>` Skill if available**
**While using `terminal` <tool>, load `<tool>` Skill if available**

**Check branches and list root**

Alwats start with this to know where you are:

```bash
pwd; git --no-pager branch --show-current; echo " "; git --no-pager branch --sort=-committerdate | head -n 16
```

Then call `list_directory` on the project root to see the top-level structure. If the project seems to have some directories, **load _`terminal` es_ Skill**.

**Never push without permission**

Local `git stash push -m <msg>` are always allowed - they're safe, local version control.
But ask for permission before each `git commit`and `git push` (and `gh` operations or mcp tools that (potentially) write to remotes).

**Use portable paths writing files**

Never hardcode a username,a api-key or machine-specific path to any file content.
Ask the user for the path to the specific CLI tool when a call is failed with `command not found` or similar error.
Harness $PATH and hardlink and symlink, maintain a clean CLI tool directory which is added to $PATH.

**Start independent (non-blocking, surviving) processes**

`& disown` in MSYS2 — the child dies when the shell exits. Instead:

```bash
cmd //c start \"\" '<exe>' '<arg1>' '<arg2>'
```

**Make minimal changes**

- Make minimal changes with minimal doc (explain why is the code coding that way) while coding.
- Make minimal changes to markdown files, minimal yet comprehensive meaning,
  but not minimal length or tokens, the token is expected exactly as-is from the session.
