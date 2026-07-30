---
name: zed-reload
description: Use `terminal` zed-reload (0.2.1) to restart Zed and inject a message into the Agent Panel. Useful for reloading Zed config, reloading MCP tools, or iterating on Zed itself from within a Zed agent session.
disable-model-invocation: true
---

# zed-reload — restart Zed and inject a message into the Agent Panel

Restarts Zed, waits for the window to appear, brings it to the foreground, and injects a message into the Agent Panel via keystroke simulation. The entire flow runs in a detached worker process that survives Zed's death.

## How it works

```
you run `zed-reload [msg...]`
  → launcher writes message to temp file, spawns detached worker, returns immediately
  → worker waits (--wait, default 26s)
  → worker kills Zed (graceful WM_CLOSE, force-kill after --grace, default 42s)
  → worker starts Zed via explorer.exe (so Zed gets the correct desktop-shell parent)
  → worker waits for new Zed window (--window-timeout, default 16s)
  → settle period (--settle, default 10s — session restore, etc.)
  → first focus (heads-up — "stop typing!")
  → heads-up delay (--heads-up, default 2s)
  → second focus
  → Ctrl+Shift+/ (agent::ToggleFocus)
  → paste message (clipboard, restored after)
  → send key (Enter or Ctrl+Enter — auto-detected from settings.json)
```

Log is written to `zed-reload.log` next to the exe.

## When to use

Call this from within a Zed agent session when you need to:

- **Reload Zed config** — after editing `settings.json`, `keymap.json`, themes, etc.
- **Reload MCP tools** — after modifying an MCP server (Zed reconnects on restart).
- **Iterate on Zed itself** — restart Zed to pick up a new build or extension.
- **Any restart + continue** — the message ("continue", "run the tests", etc.) appears
  in the restored agent panel so you can pick up where you left off.

## CLI reference

```
zed-reload [MESSAGE]...           # restart + inject message (default: "continue")
zed-reload --check                # diagnostics (no side effects)
zed-reload --version
zed-reload --help
```

| Flag | Default | Purpose |
|------|---------|---------|
| `--wait N` | 26 | seconds before acting |
| `--settle N` | 10 | seconds to wait after window appears |
| `--grace N` | 42 | graceful-close budget before force-kill |
| `--window-timeout N` | 16 | max seconds to wait for the Zed window |
| `--heads-up N` | 2 | delay between heads-up focus and injection |
| `--project PATH` | — | open this path instead of session restore |
| `--window-title SUB` | — | target a window whose title contains SUB |
| `--zed-path PATH` | — | explicit Zed.exe location |
| `--send-enter` | — | force send with Enter |
| `--send-ctrl-enter` | — | force send with Ctrl+Enter |

## Usage examples

```bash
# Basic reload — "continue" appears in the agent panel after restart
zed-reload

# Custom message
zed-reload "run the tests and report results"

# Reload after editing config
zed-reload "config updated, verify it took effect"

# Quick reload with tighter timings
zed-reload --wait 25 --settle 5 --heads-up 2 "pick up where we left off"

# Diagnostics only (check Zed.exe path, windows, send key)
zed-reload --check
```

## Two-focus flow

The injection uses two focus events to avoid breaking the keystroke injection:

1. **First focus** — brings Zed to the foreground. You see it pop up and stop typing.
2. **Heads-up delay** (`--heads-up`, default 2s) — you have time to stop any
   keyboard/mouse activity that could interfere.
3. **Second focus** — brings Zed to the foreground again, then injects.

Without the heads-up, user input (typing, clicking) during injection could steal
focus or produce unexpected keystrokes.

## Why explorer.exe?

Zed is launched through `explorer.exe` so its parent is the desktop shell.
A direct `CreateProcessW` spawn puts Zed under a console-process ancestry,
which causes its terminal-shell auto-detection to fall back to PowerShell
instead of the user's preferred shell.

## Caveats

- **Kills the current Zed process** — the detached worker survives, but this
  agent session will be interrupted. Zed restores the session on relaunch.
- **Needs an unlocked interactive desktop** — foreground stealing and
  keystroke injection require an active desktop session.
- **Clipboard is used for pasting** — the previous clipboard text is restored
  afterwards, but only for Unicode text (images, files, etc. are lost).
- **`use_modifier_to_send`** — auto-detected from `%APPDATA%\Zed\settings.json`.
  Override with `--send-enter` or `--send-ctrl-enter` if detection is wrong.
