# .agents — Zed Coding Agent Skills & Rules

A curated collection of [Zed](https://zed.dev) coding agent skills, error references, and project rules. Each skill teaches the agent how to use a specific CLI tool effectively.

## Quick Deploy

The repo itself is the deploy target — clone it directly into `~/`:

```bash
git clone https://github.com/Prohect/.agents.git "$HOME/"
```

If `~/.agents` already exists, you may optionally combine them with this repo:

```bash
# Rename your old skills directory
mv "$HOME/.agents/skills" "$HOME/.agents-old/skills"

# Clone this repo into your home directory
git clone https://github.com/Prohect/.agents.git "$HOME/"

# combine them (optional if you already paid lots of effort maintaining your custom skills), 
# you should read the contents recursively of both directories, 
# and merge them manually to keep the rules not conflicting and confusing.

# Remove the old skills directory (optional)
rm -rf "$HOME/.agents-old"
```

## Structure

```
.
├── README.md               # You are here
├── AGENTS.md               # Project agent rules for agents to maintain or contribute to this repository
├── Zed/
│   └── AGENTS.md           # Global agent rule, you may override or combine with your old global AGENTS.md
│                           # Recommand to use directory symlink to keep this one synced with your global AGENTS.md
├── skills/                 # Agent skills (one per CLI tool)
│   ├── awk/                #   GNU awk — text processing
│   ├── cat/                #   GNU cat — file display
│   ├── commit-message/     #   Git commit message writing
│   ├── errors/             #   Tool error reference index
│   ├── es/                 #   Everything Search — instant file/directory search, only on Windows
│   ├── gh/                 #   GitHub CLI
│   ├── grep/               #   GNU grep — content search
│   ├── ln/                 #   GNU ln + mklink — links & junctions, only on Windows
│   └── sed/                #   GNU sed — stream editing
├── errors/                 # Error solution docs (referenced by errors skill)
└── demo/                   # Deterministic test fixtures for each skill
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

The `errors` skill is special: it's an index of documented tool-call errors and their solutions. When the agent hits a new error, it could consults `errors/` for a known fix instead of guessing. Each error has its own directory with a `SOLUTION.md`.

## Tool Dependencies

Skills document the usage of these CLI tools, but you only need the ones you use:

| Tool | Minimum Version | How to get it |
|------|----------------|---------------|
| GNU awk | 5.3.0 | `pacman -S gawk` (MSYS2), or built-in on most Linux/macOS |
| GNU cat | 8.32 | `pacman -S coreutils` (MSYS2), or built-in |
| GNU grep | 3.0 | `pacman -S grep` (MSYS2), or built-in |
| GNU sed | 4.9 | `pacman -S sed` (MSYS2), or built-in |
| GNU ln | 8.32 | `pacman -S coreutils` (MSYS2), or built-in |
| Everything Search | 1.1.0.30 | [voidtools.com](https://www.voidtools.com) (Windows only) |
| GitHub CLI | 2.95.0 | [cli.github.com](https://cli.github.com) |

On Windows, install [MSYS2](https://www.msys2.org) to get the GNU toolchain. The `es` and `gh` skills are Windows-first but the concepts transfer.

## Contributing

See [`AGENTS.md`](AGENTS.md) for the skill authoring workflow. TL;DR:

1. Audit the tool (`<tool> --help`, `<tool> --version`)
2. Build a demo directory under `demo/<skill>/`
3. Test **every example** against the demo before writing it
4. Spawn a sub-agent to independently verify all examples
5. Document quirks prominently (broken vs. working examples)

## License

This is a personal tool configuration collection. Use, modify, and share freely.
