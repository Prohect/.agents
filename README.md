# `.agents`

A home for the **Zed** editor's agent. It bundles everything that shapes how the
agent works on this machine:

- the **global skills** the agent can load,
- the **session context** it runs with -- its system prompt and per-tool guidance,
  configured through Handlebars template overrides,
- the **Nushell** shell its `terminal` tool runs in,
- and the **demo fixtures** the skill docs use in their examples.

It is tracked in git so that the parts worth sharing survive a machine reinstall.
Machine-specific Zed state (settings, keymaps, credentials, indexes, crash dumps)
is deliberately excluded -- see [Private & ignored files](#private--ignored-files).

## Layout

```
.agents/
├── README.md                 this file
├── config.nu                 Nushell configuration
├── .gitignore                ignore rules (private Zed state, machine-specific demos)
├── .zed/
│   └── settings.json         per-project Zed settings (marks private files)
├── Zed/                      Zed agent configuration tracked by this repo
│   ├── AGENTS.md             user-global rules for the agent
│   ├── system_prompt.hbs     Handlebars override for the session's system prompt
│   ├── tool_guidance/        Handlebars overrides for the session's per-tool guidance
│   ├── handlebars-built-in-helpers.md
│   ├── themes/               user themes (empty here)
│   └── temp/                 scratch space
├── skills/                   global skills -- one folder per skill
│   ├── awk/
│   ├── commit-message/
│   ├── es/
│   ├── gh/
│   ├── minidump-stackwalk/
│   ├── playwright-cli/
│   ├── sed/
│   └── zed-reload/
└── demo/                     fixtures referenced by the skill docs
    ├── awk/
    ├── es/
    ├── gh/
    ├── sed/
    └── zed-reload/
```

## Skills

`skills/` is Zed's **global skills** directory (`~/.agents/skills/`). Each skill is
a folder containing a `SKILL.md` whose YAML frontmatter declares a `name`, a
`description`, and `disable-model-invocation`. When a request matches a skill's
description, the agent loads the full instructions with the `skill` tool.

- **Loaded by model** (`disable-model-invocation: false`) -- the agent may retrieve
  the skill on its own when the description matches.
- **Manual only** (`disable-model-invocation: true`) -- the skill is only loaded
  when the maintainer explicitly asks for it.

Skills that need more than one file keep it under a `references/` subfolder (see
`playwright-cli`). Skills whose examples depend on real input files point at the
matching folder under `demo/`.

## Demo fixtures (`demo/`)

Each subfolder holds small, self-contained inputs (`names.txt`, `scores.csv`,
`src/`, `logs/`, …) that the corresponding skill's `SKILL.md` uses in its examples.
`cd` into the relevant folder to reproduce the documented commands. The
`zed-reload` fixtures are sanitized captures of real runs (timestamps, PIDs, and
window titles replaced with placeholders).

`demo/minidump-stackwalk/` is intentionally **not** committed -- crash dumps are
machine-specific. Create your own following that skill's instructions.

## Zed configuration (`Zed/`)

These files configure / override the **session context** Zed assembles for each
agent session -- the agent-facing pieces that are safe to share and useful to
version.

The overrides are written as Handlebars templates, rendered per session with the
session's context variables (available tools, platform, model, date, …), so the
result can adapt to the active session.

- **`system_prompt.hbs`** -- overrides the session's system prompt. When it renders
  it replaces Zed's built-in system prompt (on a render error Zed falls back to the
  built-in one). It composes the agent's `Communication`, `Environment`, `Project`,
  `Tool Use`, `Making Changes`, `Task Execution`, and `Finnal Report` sections,
  conditionally based on the available tools, and injects the loaded skills
  catalog. Its header comment documents the context variables, the custom helpers
  (`contains`, `join`, `array`, `union`, `intersect`, `differ`), and partial
  imports.
- **`tool_guidance/`** -- overrides the guidance for the session's tools, one
  directory per tool. Each `.hbs` file adds to the corresponding part of the tool's
  built-in description (guidance is appended, never replaces the code-owned
  contract). The naming scheme (`&self.hbs`, `<param>.hbs`, `$<node>/…`, partials)
  is documented in [`tool_guidance/README.md`](Zed/tool_guidance/README.md).
- **`handlebars-built-in-helpers.md`** -- reference for the Handlebars helpers
  available to the templates above.
- **`AGENTS.md`** -- user-global instructions for the agent.

Only the files above (plus this README and the ignore rules) are tracked; the rest
of `Zed/` is private Zed state and is ignored. See the `.gitignore` and the
project's `.zed/settings.json`.

## Private & ignored files

The `.gitignore` ignores all of `Zed/` except the tracked docs listed above, and
ignores `demo/minidump-stackwalk/*`. In addition, the project's
`.zed/settings.json` marks `Zed/*.json` and `Zed/development_credentials` as
private files. Keep machine-specific paths and secrets out of the tracked files.

## Extending

- **Add a skill** -- create `skills/<name>/SKILL.md` with `name` and `description`
  frontmatter (add `disable-model-invocation: true` to keep it manual-only); put
  larger material under `skills/<name>/references/`.
- **Adjust tool guidance** -- add or edit a file under `Zed/tool_guidance/<tool>/`
  (`&self.hbs` for the tool's own description, `<param>.hbs` for a parameter,
  `$<node>/…` to descend into a schema node). See
  [`Zed/tool_guidance/README.md`](Zed/tool_guidance/README.md).
- **Edit the agent's system prompt** -- modify `Zed/system_prompt.hbs`.
- **Reload the changes** -- use the `zed-reload` skill to restart Zed and pick up
  the new config/MCP tools.
