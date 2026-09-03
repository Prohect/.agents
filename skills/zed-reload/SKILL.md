---
name: zed-reload
description: Use `terminal` zed-reload (0.5.0) to restart Zed and inject a message into the Agent Panel -- into the current agent session, or into a brand-new one with --handoff. Useful for reloading Zed config, reloading MCP tools, or iterating on Zed itself from within a Zed agent session.
disable-model-invocation: true
---

# zed-reload -- restart Zed and inject a message into the Agent Panel

Restarts Zed and injects a message into the Agent Panel. By default the message continues the session it was called from; with `--handoff` it starts a **new agent session** instead. Runs in a detached worker that survives Zed's death.

## What it does

1. Reopens the **calling project** (`$pwd`) -- the restarted session is the one that invoked zed-reload, even with several projects open (explicit `--project` overrides).
2. Minimizes the window right after it appears (unless the previous session was focused), so the launch doesn't hold focus.
3. Shows a Windows notification ("stop typing!"), waits `--heads-up` seconds, then focuses Zed and injects your message: toggle agent panel, paste, send. In handoff mode it presses the new-thread key before pasting, so the message lands in a fresh agent session.

Log: `zed-reload.log` next to the exe.

## When to use

- **Reload Zed config** -- after editing `settings.json`, `keymap.json`, themes, etc.
- **Reload MCP tools** -- after modifying an MCP server (Zed reconnects on restart).
- **Iterate on Zed itself** -- pick up a new build or extension.
- **Any restart + continue** -- the message ("continue", "run the tests", ...) appears in the restored agent panel.
- **Hand off work to a new session** -- `--handoff` delivers the message to a brand-new agent thread instead of the original sender.

## Handoff mode

```bash
zed-reload --handoff "work on this next"
```

After the restart, the message appears as the first message of a **new agent thread** -- the previous conversation is left untouched. The new-thread key is auto-detected from `keymap.json` (`agent::NewThread`, Zed default `ctrl-n`); override with `--new-thread-keys "ctrl-shift-t"`.

Known quirk: if the last entry you created in the agent panel was a *terminal* (not a thread), the new-thread key opens a terminal entry instead, and the message would be typed there. Create a thread entry once before handoff if in doubt.

## Usage

```
zed-reload [MESSAGE]...     restart + inject message (default: "continue")
zed-reload --handoff [MESSAGE]...  same, but into a NEW agent session
zed-reload --check          diagnostics (no side effects)
zed-reload --version
zed-reload --help
```

| Flag | Default | Purpose |
|------|---------|---------|
| `--wait N` | 26 | seconds before acting |
| `--settle N` | 10 | seconds to wait after the window appears |
| `--grace N` | 42 | graceful-close budget before force-kill |
| `--window-timeout N` | 16 | max seconds to wait for the Zed window |
| `--heads-up N` | 2 | delay between the notification and injection |
| `--project PATH` | `$pwd` | project to reopen (default: the calling session's working directory) |
| `--window-title SUB` | -- | target a window whose title contains SUB |
| `--zed-path PATH` | -- | explicit Zed.exe location |
| `--zed-pid PID` | -- | only stop this Zed process (default: the closest Zed ancestor) |
| `--config-dir DIR` | `%APPDATA%\Zed` | where settings.json and keymap.json are read from |
| `--mode MODE` | auto | editor mode: `normal`, `vim`, `helix` (auto-detected from settings.json) |
| `--toggle-keys KEYS` | auto | `agent::ToggleFocus` binding (auto-detected from keymap.json) |
| `--paste-keys KEYS` | auto | paste binding (auto-detected from keymap.json, else mode default) |
| `--send-enter` / `--send-ctrl-enter` | auto | force the send key (auto-detected from `settings.json`) |
| `--handoff` | off | deliver the message to a NEW agent session instead of the original sender |
| `--new-thread-keys KEYS` | auto | `agent::NewThread` binding for handoff (auto-detected from keymap.json, else `ctrl-n`) |

## Examples

```bash
zed-reload                                   # restart; "continue" in the calling session
zed-reload "run the tests and report results"
zed-reload --wait 25 --settle 7 "pick up where we left off"
zed-reload --handoff "start fresh on the parser rewrite"
zed-reload --check                           # diagnostics only
```

## Caveats

- **Kills the current Zed process** -- this agent session is interrupted. It resumes in the restarted session with your message; with `--handoff` the message goes to a new session instead.
- **Recovery is strict** -- the message goes to the calling project's window only; if that window isn't found, nothing is injected (check the log).
- **Needs an unlocked interactive desktop** -- foreground and keystroke injection require an active desktop session.
- **Clipboard is used for pasting** -- the previous clipboard text is restored afterwards, but only for Unicode text (images, files, etc. are lost).
