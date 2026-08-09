# AGENTS.md

## Read Tool Scope

- `read_file`
  - Scope: project roots + `~/.agents/skills/`
  - Gitignore-aware: false; access all
  - Respects `.zed/settings.json::file_scan_exclusions`: true
- `list_directory`
  - Scope: project roots + `~/.agents/skills/`
  - Gitignore-aware: true;
  - Respects `file_scan_exclusions`: true
- `grep` / `find_path`
  - Scope: project roots
  - Gitignore-aware: true;
  - Respects `file_scan_exclusions`: true
- `terminal` cat/grep/ls/find
  - Scope: anywhere (slow on large file trees)
  - Gitignore-aware: false; access all
- `terminal` es
  - Scope: anywhere (files, directories, **fast**)
  - Gitignore-aware: false; access all

## Terminal Usage Rules

- While using `terminal`, never create or redirect to a file named `nul`, `con`, `prn`, `aux`, `com1`-`com9`, or `lpt1`-`lpt9` — these are Windows reserved names.
- Never use a `terminal` tool to edit a file unless other tools cannot cover it (error or scope limitation).
- While using a `terminal` tool, load that tool's Skill if one is available.

## Efficient Search

Use `terminal` es instead of `terminal` ls, which is slow on large file trees and requires recursive tool calls.

For example, to search inside a gitignored path (e.g. `minecraft-decompile-sources/`), use `terminal` es to find files or directories by name, then `terminal` grep to read their contents.

`terminal` es local first if need to search a repo not in pwd.

## Check Branches and List Root

Always start with this to know where you are:

```bash
pwd; git --no-pager branch --show-current; echo " "; git --no-pager branch --sort=-committerdate | head -n 16
```

Then call `list_directory` on the project root to see the top-level structure. If the project seems to have some directories, load the `es` Skill.

## Never Push Without Permission

`git stash push -m <msg>` is always allowed.

Ask for permission before each `git commit` and `git push`, and before any `gh` operation or MCP tool call that writes to a remote.

## Use Portable Paths When Writing Files

- Never hardcode a username, an API key, or a machine-specific path in any version-controlled file content.
- Ask the user for the path to a specific CLI tool when a call fails with `command not found` or similar.
- Leverage `$PATH`, hard links, and symlinks; maintain a clean CLI tool directory that's added to `$PATH`.

## Start Independent (Non-Blocking, Surviving) Processes

`& disown` in MSYS2 — the child dies when the shell exits. Instead:

```bash
cmd //c start \"\" '<exe>' '<arg1>' '<arg2>'
```

## Make Minimal Changes

- Make minimal changes with minimal documentation while coding (explain why the code is written that way).
- Make minimal yet comprehensive changes to markdown files. Minimal here doesn't mean minimal length or tokens — tokens are expected exactly as-is from the session.

## Parallel Sub-Agents

Parallel sub-agents that write to the same working directory — whether targeting different git branches or sharing intersecting edit trees — are **unpredictable** and **unreliable**: they race on checkout, stomp each other's staged changes, and can leave the repo in an **unrecoverable** state if no git or chaos like detached HEAD, lost stashes, merge-conflict artifacts.
