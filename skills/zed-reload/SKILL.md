---
name: zed-reload
description: Use `terminal` zed-reload to reload Zed and inject a message into the Agent Panel — the agent thread survives the restart and continues unattended. Use when a task requires reloading Zed mid-flight — MCP server rebuilds (Zed spawns MCP servers only at startup), Zed/extension/settings updates — or as a crash/hang watchdog that revives Zed and resumes the thread.
disable-model-invocation: true
---

# zed-reload — reload Zed + inject into the Agent Panel

`zed-reload.exe`, a small Rust CLI on $PATH. It closes Zed gracefully (force-kill fallback), relaunches it (Zed's `restore_on_startup=last_session` reopens the workspace incl. the Agent Panel), then injects a message into the Agent Panel's message editor (`ctrl+shift+/` focus, clipboard paste, `enter`/`ctrl+enter` auto-detected from Zed's settings). The launcher returns immediately; a detached worker does the work, so it survives Zed's own death. Use it whenever a task needs Zed reloaded mid-flight while keeping the current agent thread going.

Every run appends to `zed-reload.log` next to the exe — check it first when something didn't happen:

```bash
cat "$(dirname "$(command -v zed-reload)")/zed-reload.log"
```

## Quick Reference

| Task                                   | Command                                |
| -------------------------------------- | -------------------------------------- |
| Reload Zed, then inject (default)      | `zed-reload "continue"`                |
| Inject into running Zed (⚠️ see quirks) | `zed-reload --send "msg"`              |
| Watchdog: revive on crash              | `zed-reload --watch "msg"`             |
| Watchdog: also revive on hang          | add `--unresponsive 60`                |
| Bound the watchdog (default 3600)      | `--watch-timeout N`                    |
| Delay before reload (caller finishes)  | `--wait 42`                            |
| Delay before injection (MCP load time) | `--settle 16`                          |
| Graceful-quit budget (default 20)      | `--grace N`                            |
| Window wait budget (default 90)        | `--window-timeout N`                   |
| Open a specific project                | `--project PATH`                       |
| Pick a window by title substring       | `--window-title SUB`                   |
| Force send key (default: auto-detect)  | `--send-enter` / `--send-ctrl-enter`   |
| Override Zed.exe location              | `--zed-path PATH`                      |
| Diagnostics, no side effects           | `zed-reload --check`                   |

## Self-Resurrection (reload mid-task, thread continues)

Arm the reload yourself; the detached worker reloads Zed (taking you with it), then injects your message into this thread — the next agent instance reads it as a user message:

```bash
zed-reload --wait 30 --settle 10 "[zed-reload] Zed was reloaded. Read <file> for context and continue <task> from step <N>."
# → zed-reload: launched detached worker pid=<pid> (mode=Restart, wait=30s, settle=10s)
# → zed-reload: log -> <install-dir>\zed-reload.log
```

Rules for arming a reload:

1. **Finish first.** Write every file the next instance needs BEFORE arming; it reads the thread + your files, not your mind. Make the revival message self-contained: what happened, what to do next, where the log is.
2. **`--wait` >= 20** so your final chat message flushes and the user can read it. Tell the user you're about to reload their IDE.
3. **`--settle` is the injection delay** (after the window appears, before paste). Raise it when Zed needs load time — MCP servers, big workspaces.
4. **Verify after revival** in the log:

```bash
cat "$(dirname "$(command -v zed-reload)")/zed-reload.log" | tail -n 10
# → WM_CLOSE pid=<pid> title='<workspace-title>'
# → Zed exited gracefully
# → starting <zed-exe> (bare, session restore)
# → window found pid=<pid> ...; settling 10s
# → foreground=true via AttachThreadInput (attempt 1)
# → send key: ctrl+enter
# → injected 376 chars
# → === done: ok=true ===
```

## MCP Development Loop

Zed spawns MCP servers at startup; rebuilding a server or changing MCP config requires a reload. Keep the benchmark/update task going across it:

```bash
# rebuild your MCP server first, then:
zed-reload --settle 25 --wait 25 "[zed-reload] MCP server rebuilt and Zed reloaded. Servers may still be starting: verify the MCP tools are available (wait 15s and retry, up to ~2 min), then re-run the benchmark: <cmd>. Compare with <baseline> and report."
```

**Note:** a fixed `--settle` is a guess; the revived agent can actually verify MCP readiness — put the retry loop in the message, as above.

## Watchdog (crash/hang recovery)

```bash
zed-reload --watch --unresponsive 60 "[zed-reload] Zed was revived after a crash/hang. Continue the previous task from the log."
# → zed-reload: launched detached worker pid=<pid> (mode=Watch, ...)
# polls every 5s; two consecutive no-window checks (or a hung window for
# 60s) → revive + inject, then exits. Add --watch-timeout N to bound it.
```

## Safe Dry-Run

Watch a healthy Zed, exit after the timeout, inject nothing:

```bash
zed-reload --watch --watch-timeout 12 "watch-dryrun"
# → zed-reload: launched detached worker pid=<pid> (mode=Watch, wait=6s, settle=10s)
# log ~15s later:
#   === start: msgLen=12 wait=6s settle=10s grace=20s ===
#   watching: timeout=12s unresponsive=off
#   watch timeout, Zed stayed healthy
#   === done: ok=true ===
```

## ⚠️ Quirks

- **Needs an unlocked desktop; hands off keyboard/mouse while it fires.** Keystrokes go to whatever is foreground. If the Zed window can't be brought to the foreground, the run aborts instead of typing into the wrong app.
- **`--send` is a blind toggle.** If the Agent Panel already has focus at that instant, `ctrl+shift+/` HIDES it and the paste lands in an open editor (modifies a file). Default reload and `--watch` are deterministic (the panel is never focused right after a start) — never use `--send` unattended.
- **Panel must be showing the thread.** If the Agent Panel comes up on a different/new thread after the reload, the injection lands there instead (log still says `injected`).
- **Clipboard is clobbered** to paste the message, then restored (text only).
- **Requires the default keybinding** `ctrl+shift+/` → `agent::ToggleFocus` (no custom `keymap.json` overriding it).

## Troubleshooting

### Nothing happened (no reload, no injection)

Read the log — every step is timestamped, the last line tells you where it stopped:

```bash
cat "$(dirname "$(command -v zed-reload)")/zed-reload.log" | tail -n 12
```

`=== start ===` but nothing more → the worker was killed mid-run (it must stay alive; never close a console running the `.cmd`/`.ps1` fallbacks — use the exe, which detaches properly).

### `zed-reload: LAUNCH FAILED`

The detached worker couldn't spawn. It retries without `CREATE_BREAKAWAY_FROM_JOB` before failing — should not happen; report it.

### Log says `injected` but nothing was sent

The Agent Panel wasn't showing the intended thread (see Quirks) — the message went wherever panel focus landed.

## Notes

- **Keystroke timing is configurable, not zero.** Defaults: `--wait 6` (pre-reload), `--settle 10` (pre-injection), `--grace 20` (quit budget), `--window-timeout 90`.
- **Unsaved editors can block the graceful quit** → force-kill after `--grace` seconds (logged).
- **The worker never un-maximizes** — it restores minimized windows only (`SW_RESTORE` would un-maximize).
- **Zed has no "reload without focus change" facility** (researched: internal `focus`/`visible` plumbing exists in gpui/workspace but isn't exposed via CLI/IPC). The background relaunch normally doesn't steal focus; the tool takes the foreground for ~3s at injection only.
- **Prefer `;` over `&&`** — some agent terminals parse commands as PowerShell 5.1, which has no `&&`.
- **Use `$HOME`-style portable paths in revival messages**, never hardcode usernames.
