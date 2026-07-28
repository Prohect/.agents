---
name: zed-reload
description: Reload Zed and inject a message into the Agent Panel via the zed-reload CLI — the agent thread survives the restart and continues without user input. Use for MCP-server dev loops (Zed loads MCP servers at startup — reload after rebuilding one or changing MCP config, then auto-resume the benchmark/task), Zed/extension/settings updates, crash/hang watchdog revival, and any mid-task Zed restart.
disable-model-invocation: true
---

# zed-reload — reload Zed + inject into the Agent Panel

CLI: `zed-reload` (on PATH, works from any cwd). Source + install:
https://github.com/Prohect/zed-reload (Rust, Windows; `scripts/` has
bash/PowerShell fallbacks). Every run appends to `zed-reload.log` next to
the exe — check it first when something didn't happen.

What a reload run does: `WM_CLOSE` every Zed window (force-kill after
`--grace` 20s if a modal blocks) → bare relaunch
(`restore_on_startup=last_session` reopens the workspace incl. the Agent
Panel) → wait for the window → `--settle` seconds → force foreground →
`ctrl+shift+/` (`agent::ToggleFocus`, lands in the message editor) →
clipboard paste → send key (auto-detected from Zed's `settings.json`:
`ctrl+enter` when `use_modifier_to_send` is true, else `enter`).

## Commands (verified)

```bash
zed-reload --check
```

Diagnostics, no side effects. Expected shape (sanitized fixture:
`../../demo/zed-reload/check-output.txt`):

```
zed-reload check (rust)
  self       : <install-dir>\zed-reload.exe
  zed exe    : %LOCALAPPDATA%\Programs\Zed Nightly\Zed.exe
  zed windows: 1
    pid=<pid> hung=false title='<workspace-title>'
  send key   : ctrl+enter (auto-detected)
  log file   : <install-dir>\zed-reload.log
```

```bash
zed-reload --watch --watch-timeout 12 "watch-dryrun"
```

Safe dry-run: watches a healthy Zed, exits after the timeout, injects
nothing. The launcher prints `launched detached worker pid=...`; ~15s later
the log shows (fixture: `../../demo/zed-reload/watch-dryrun-log.txt`):

```
[watch] === start: msgLen=23 wait=6s settle=10s grace=20s ===
[watch] watching: timeout=12s unresponsive=off
[watch] watch timeout, Zed stayed healthy
[watch] === done: ok=true ===
```

## Self-resurrection (reload Zed mid-task, keep the thread going)

Arm the restart yourself; the launcher returns immediately, the detached
worker reloads Zed (taking you with it), then injects your message into
this thread — the next agent instance reads it as a user message. Verified
end-to-end (sanitized trace fixture:
`../../demo/zed-reload/restart-e2e-log.txt`):

```bash
zed-reload --wait 25 --settle 20 "[zed-reload] Zed was reloaded. Read <file> for context and continue <task> from step <N>."
```

Rules for arming a reload:

1. **Finish first.** Write all files/docs the next instance needs BEFORE
   arming; it reads the thread + your files, not your mind. Make the
   revival message self-contained: what happened, what to do next, where
   the log is.
2. **`--wait` >= 20** so your final chat message flushes and the user can
   read it. Tell the user you're about to reload their IDE.
3. **`--settle` is the injection delay.** Raise it when Zed needs load
   time (MCP servers, big workspaces, extensions), e.g. `--settle 30`.
   (`--wait` = delay before the reload; `--settle` = delay after the
   window appears, before injection.)
4. **Verify after revival**: the log should end with `injected N chars`
   and `=== done: ok=true ===`.

## MCP development loop (primary use case)

Zed spawns MCP servers at startup; rebuilding a server or changing MCP
config requires a reload. Keep the benchmark/update task going across it:

```bash
# rebuild your MCP server first, then:
zed-reload --settle 25 --wait 25 "[zed-reload] MCP server rebuilt and Zed reloaded. Servers may still be starting: verify the MCP tools are available (wait 15s and retry, up to ~2 min), then re-run the benchmark: <cmd>. Compare with <baseline> and report."
```

A fixed `--settle` is a guess; the revived agent can actually verify MCP
readiness — put the retry loop in the message, as above.

## Watchdog (crash/hang recovery)

```bash
zed-reload --watch --unresponsive 60 "[zed-reload] Zed was revived after a crash/hang. Continue the previous task from the log."
```

Polls every 5s; two consecutive no-window checks (or a hung window for
`--unresponsive` seconds) → revive + inject, then exits. Bound it with
`--watch-timeout N` (default 3600). Flag path verified by dry-run
(`unresponsive=60s` appears in the log; fixture:
`../../demo/zed-reload/watch-unresponsive-dryrun-log.txt`); an actual
hang-triggered revive is implemented but not safely testable.

## ⚠️ Quirks (hard-won, respect them)

- **Needs an unlocked desktop; hands off keyboard/mouse while it fires.**
  Keystrokes go to whatever is foreground. If the Zed window can't be
  brought to the foreground the run aborts instead of typing into the
  wrong app.
- **`--send` is a blind toggle**: if the Agent Panel already has focus at
  that instant, `ctrl+shift+/` HIDES it and the paste lands in an open
  editor (modifies a file!). `--restart` (default) and `--watch` are
  deterministic (the panel is never focused right after a start) — never
  use `--send` unattended.
- **Requires the default keybinding** `ctrl+shift+/` →
  `agent::ToggleFocus` (no custom `keymap.json` overriding it).
- **Clipboard is clobbered** to paste the message, then restored (text
  only).
- The worker restores minimized windows but never un-maximizes
  (`SW_RESTORE` would — a real bug, since fixed).
- Zed has **no supported "reload without focus change"** facility
  (researched: gpui/workspace have internal `focus`/`visible` plumbing,
  but neither the CLI nor the IPC payload exposes it). The worker's
  background relaunch normally doesn't steal focus; it takes the
  foreground for ~3s at injection only.
- Unsaved editors can block the graceful quit → force-kill after
  `--grace` 20s (logged).
- Shells: some agent terminals parse commands as PowerShell 5.1, which
  has no `&&` — prefer `;` between commands.

## Troubleshooting

- Nothing happened → read `zed-reload.log` next to the exe: every step is
  logged with timestamps; the last line tells you where it stopped.
- `LAUNCH FAILED` → the worker couldn't spawn (it retries without
  `CREATE_BREAKAWAY_FROM_JOB` before failing).
- Log says `injected` but nothing was sent → the panel wasn't showing the
  thread; the message went wherever panel focus landed (rare).

## Install / rebuild from source

```bash
git clone https://github.com/Prohect/zed-reload; cd zed-reload; cargo build --release
# then put target/release/zed-reload.exe in any directory on %PATH%
```
