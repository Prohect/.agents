# AGENTS.md

## Read Tool Scope

- `read_file`
  - Scope: project roots + `~/.agents/skills/`
  - Respect `gitignore`: false
  - Respect `.zed/settings.json::file_scan_exclusions` & `.zed/settings.json::file_scan_inclusions`: true
- `list_directory`
  - Scope: project roots + `~/.agents/skills/`
  - Respect `gitignore`: true
  - Respect `file_scan_exclusions` & `file_scan_inclusions`: true
- `grep` / `find_path`
  - Scope: project roots
  - Respect `gitignore`: true
  - Respect `file_scan_exclusions` & `file_scan_inclusions`: true
- `terminal` cat/grep/ls/find
  - Scope: anywhere (slow on large file trees)
  - Respect `gitignore`: false
  - Respect `.zed/settings.json`: false
- `terminal` es
  - Scope: anywhere (files, directories, **fast**)
  - Respect `gitignore`: false
  - Respect `.zed/settings.json`: false

### Note 
- `gitignore`: `$PWD/.gitignore` & `$PWD/.git/info/exclude`.
- `.zed/settings.json`: `$PWD/.zed/settings.json`.
- `file_scan_inclusions` wins `gitignore`.
- pattern of `file_scan_exclusions` & `file_scan_inclusions`: glob.

Prefer native tools over `terminal` <tool> when searching for file contents.
Temporary adding glob patterns to `file_scan_inclusions` to search for file contents allowed.

## Terminal

- While using `terminal`, never create or redirect to a file named `nul`, `con`, `prn`, `aux`, `com1`-`com9`, or `lpt1`-`lpt9` — these are Windows reserved names.
- Never use a `terminal` tool to find/read/edit a file unless other tools cannot cover it (error or scope limitation).
- Never use a `terminal` tool to find/read/edit a file unless other tools cannot cover it (error or scope limitation).
- **While using a `terminal` tool, load that tool's Skill if one is available.**
- **While using a `terminal` tool, load that tool's Skill if one is available.**

## Efficient Search

Use `terminal` es instead of `terminal` ls, which is slow on large file trees and requires recursive tool calls.

To search inside a gitignored path, prefer adding it in `file_scan_inclusions` as a recursive `dir/**` glob so the native tools see it. For paths outside `$PWD`, native `grep` / `find_path` / `list_directory` cannot reach them — symlinking into `$PWD` does NOT help even with `file_scan_inclusions` globs. Use `terminal` tools (grep/cat/es) on the absolute path directly.

`terminal` es local machine first if need to search a repo not in pwd.

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

## Non-Blocking Calls

- **never use blocking tool call for non-blocking/asynchronous purpose**
- **never use blocking tool call for non-blocking/asynchronous purpose** -- you never get real stdout/stderr/tool_call_err as-is from the non-blocking parts of the tool call you make via blocking calls, it's abandoned by yourself. 

## Terminal waits

Never hardcode a long `sleep <n>`. Poll with a bounded 1s-interval loop instead, so the wait ends the moment the condition is true:
```bash
for i in $(seq 1 <limit>); do netstat -ano 2>/dev/null | grep -q "<port>.*LISTENING" && echo "Port <port> listening after ${i}s" && break; sleep 1; done
```

## Make Minimal Changes

- Make minimal changes with minimal documentation while coding (explain why the code is written that way).
- Make minimal yet comprehensive changes to markdown files. Minimal here doesn't mean minimal length or tokens — tokens are expected exactly as-is from the session.

## Parallel Sub-Agents

Parallel sub-agents that write to the same working directory — whether targeting different git branches or sharing intersecting edit trees — are **unpredictable** and **unreliable**: they race on checkout, stomp each other's staged changes, and can leave the repo in an **unrecoverable** state if no git or chaos like detached HEAD, lost stashes, merge-conflict artifacts.

## Context Summarize | Compress

Never write global rules or project rules to summarize | compress.
