# .agents — Zed Coding Agent Skills & Rules

A curated collection of [Zed](https://zed.dev) coding agent skills, error references, and project rules. Each skill teaches the agent how to use a specific CLI tool effectively.

## Quick Deploy

```bash
git clone https://github.com/Prohect/.agents.git
cd .agents

# Deploy skills — symlink into ~/.agents/skills/
mkdir -p "$HOME/.agents/skills"
for skill in skills/*; do
    ln -s "$(pwd)/$skill" "$HOME/.agents/skills/$(basename "$skill")"
done

# Deploy error docs
ln -s "$(pwd)/errors" "$HOME/.agents/errors"

# Deploy project rules (optional — only if this is your primary ruleset)
ln -s "$(pwd)/AGENTS.md" "$HOME/.agents/AGENTS.md"
ln -s "$(pwd)/Zed/AGENTS.md" "$HOME/.agents/Zed/AGENTS.md"
```

On Windows, use `mklink /J` (junctions, no admin needed) or `cmd //c 'mklink ...'` from MSYS2 shells. See the [`ln` skill](skills/ln/SKILL.md) for details.

## Structure

```
.
├── AGENTS.md              # Global agent rules (project-agnostic)
├── Zed/
│   └── AGENTS.md          # Zed-specific agent configuration
├── skills/                # Agent skills (one per CLI tool)
│   ├── awk/               #   GNU awk — text processing
│   ├── cat/               #   GNU cat — file display
│   ├── commit-message/    #   Git commit message writing
│   ├── errors/            #   Tool error reference index
│   ├── es/                #   Everything Search — instant file search
│   ├── gh/                #   GitHub CLI
│   ├── grep/              #   GNU grep — content search
│   ├── ln/                #   GNU ln + mklink — links & junctions
│   └── sed/               #   GNU sed — stream editing
├── errors/                # Error solution docs (referenced by errors skill)
└── demo/                  # Deterministic test fixtures for each skill
```

## How Skills Work

Each skill is a directory under `skills/` containing a `SKILL.md` file with YAML frontmatter:

```markdown
---
name: cat
description: Use GNU cat for reading, concatenating, and displaying files.
---

# cat — Concatenate & Display Files

...reference docs, examples, quirks, and edge cases...
```

The agent loads a skill when a task matches its description. The SKILL.md teaches the agent the tool's full CLI surface — flags, quirks, platform notes, and worked examples — so it uses the tool correctly on the first try.

## The `errors` Skill

The `errors` skill is special: it's an index of documented tool-call errors and their solutions. When the agent hits a new error, it consults `errors/` for a known fix instead of guessing. Each error has its own directory with a `SOLUTION.md`.

## Prerequisites

Skills assume these CLI tools are available on `$PATH`:

| Tool | Minimum Version | Windows |
|------|----------------|---------|
| GNU awk | 5.3.0 | via MSYS2/Git Bash |
| GNU cat | 8.32 | via MSYS2/Git Bash |
| GNU grep | 3.0 | via MSYS2/Git Bash |
| GNU sed | 4.9 | via MSYS2/Git Bash |
| GNU ln | 8.32 | via MSYS2; `mklink` fallback |
| Everything Search (`es`) | 1.1.0.30 | native Windows |
| GitHub CLI (`gh`) | 2.95.0 | native Windows |

Install MSYS2 tools with `pacman -S coreutils grep sed gawk`.

## Contributing

See [`AGENTS.md`](AGENTS.md) for the skill authoring workflow. TL;DR:

1. Audit the tool (`<tool> --help`, `<tool> --version`)
2. Build a demo directory under `demo/<skill>/`
3. Test **every example** against the demo before writing it
4. Spawn a sub-agent to independently verify all examples
5. Document quirks prominently (broken vs. working examples)

## License

This is a personal tool configuration collection. Use, modify, and share freely.
