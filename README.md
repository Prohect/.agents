# .agents

A version-controlled copy of my personal [`~/.agents`](https://zed.dev/docs/ai/agent-panel)
directory — the configuration that turns the **Zed** editor's agent into a
customized coding assistant: its skills, system prompt, and built-in-tool
guidance, plus the demo fixtures that support them.

Built for Windows; the skill examples assume a Unix-like CLI toolchain
(Git Bash / MSYS2) alongside a Nushell-compatible shell.

## Layout

```
.agents/
├── Zed/                     # symlinked to Zed's user-config dir (see Deployment)
│   ├── AGENTS.md            # user-global agent instructions
│   ├── system_prompt.hbs    # overrides Zed's built-in system prompt (Handlebars)
│   ├── handlebars-built-in-helpers.md
│   ├── tool_guidance/       # per-tool .hbs overrides for built-in tool docs
│   ├── themes/              # custom themes
│   └── temp/                # scratch output / captured prompts
├── skills/                  # Zed Skills, one directory each
├── demo/                    # per-skill test fixtures used by the examples
├── .zed/settings.json       # project-scoped Zed settings
└── .gitignore
```

## Deployment

The checkout lives at `~/.agents`.
Zed's user-config directory is **symlinked to the tracked `Zed/` folder**, so
the repo is the single source of truth: tracked config files are committed
while Zed's runtime state lands in the same folder and stays gitignored.

Windows — a directory junction (no admin rights required):

```cmd
:: one-time, after moving any existing config aside
rmdir "%APPDATA%\Zed"
mklink /J "%APPDATA%\Zed" "%USERPROFILE%\.agents\Zed"
```

The equivalent PowerShell symlink (needs Developer Mode or an elevated shell):

```powershell
Remove-Item "$env:APPDATA\Zed" -Recurse -Force
New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Zed" -Target "$env:USERPROFILE\.agents\Zed"
```

macOS/Linux use their own config-dir equivalents, e.g.
`ln -s ~/.agents/Zed ~/.config/zed`.

Skills need no extra wiring: because the checkout lives at `~/.agents`, its
`skills/` folder is already the agent's skill directory (`~/.agents/skills/`),
so the symlink above is the only bridge required.

## Skills

Each skill is a `skills/<name>/SKILL.md` with YAML frontmatter
(`name`, `description`, `disable-model-invocation`). The agent loads a skill on
demand via the `skill` tool when a request matches its description.

| Skill | Description | Model-invokable |
| --- | --- | :---: |
| `awk` | GNU awk 5.4 field extraction, filtering, aggregates, CSV/text transforms. | yes |
| `sed` | GNU sed 4.9 substitution, deletion, insertion, regex transforms. | yes |
| `es` | Everything Search CLI — instant filename/path search on Windows. | yes |
| `gh` | GitHub CLI 2.95 — repos, PRs, issues, releases. | yes |
| `commit-message` | Git commit-message style rules. | yes |
| `minidump-stackwalk` | Analyze Windows `.mdmp` crash dumps (backtrace, modules, registers). | no |
| `playwright-cli` | Browser automation, UI testing, scraping, DevTools/tracing. | no |
| `zed-reload` | Restart Zed and inject a message into the Agent Panel. | no |

Skills marked **no** set `disable-model-invocation: true` — they only run when
explicitly invoked by the maintainer.

## Demo fixtures

`demo/<skill>/` holds a small, controlled file tree (varied types, nested and
hidden dirs, spaces in names, different sizes) so every example in a skill has
a **deterministic, reproducible** result. Run a skill's examples from the
matching demo directory:

```nu
cd ~/.agents/demo/awk
```

`demo/minidump-stackwalk/` is **not** tracked (see *Privacy*); recreate its
fixtures by following that skill's instructions.

## Customizing the agent

- **System prompt** — `Zed/system_prompt.hbs`. When it renders successfully it
  *replaces* Zed's built-in system prompt; delete it to fall back. Zed renders
  in strict mode, so an unknown variable aborts the render and reverts to the
  built-in prompt. See `Zed/handlebars-built-in-helpers.md` for the template
  syntax and the custom helpers (`contains`, `join`, `array`, `union`,
  `intersect`, `differ`).
- **Tool guidance** — `Zed/tool_guidance/<tool>/` extends the built-in
  documentation for each tool. `&self.hbs` extends the tool description;
  `<name>.hbs` extends a named parameter; `$<name>/` descends into a schema
  node. Guidance is always *appended*, never replaced. See
  `Zed/tool_guidance/README.md`.
- **User instructions** — `Zed/AGENTS.md`.

## Privacy

`.gitignore` keeps machine-specific data out of the repo:

- Zed runtime state under `Zed/*` is ignored, except the tracked config files
  (`AGENTS.md`, `system_prompt.hbs`, `handlebars-built-in-helpers.md`, and
  `tool_guidance/`).
- `demo/minidump-stackwalk/*` is ignored — crash dumps and browser profiles
  reference the author's machine and shouldn't be shared. Create your own.

`.zed/settings.json` additionally hides `Zed/*.json` and
`Zed/development_credentials` from the agent's file scans.
