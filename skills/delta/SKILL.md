---
name: delta
description: Use `terminal` delta (v0.19.2) for syntax-highlighting pager for git and diff output. Use when you need to view diffs with syntax highlighting, line numbers, or side-by-side layout.
disable-model-invocation: false
---

# delta — A viewer for git and diff output

`delta` v0.19.2, a syntax-highlighting pager for git and diff output. Reads unified diff from stdin (or diffs two files directly). Use `--paging never` to disable the pager and print to stdout.

## Quick Reference

| Task | Command |
| ---- | ------- |
| Pipe git diff | `git diff \| delta` |
| View staged | `git diff --staged \| delta` |
| View commit | `git show \| delta` |
| View log with diffs | `git log -p \| delta` |
| Diff two files | `delta file1 file2` |
| Extra context lines | `delta --diff-args=-U10 file1 file2` |
| Side-by-side | `-s` |
| Line numbers | `-n` |
| Keep +/- markers | `--keep-plus-minus-markers` |
| Disable paging | `--paging never` |
| Dark theme | `--dark` |
| Light theme | `--light` |
| Custom minus/plus style | `--minus-style 'red bold' --plus-style 'green bold'` |
| Fallback language | `--default-language python` |
| List languages | `--list-languages` |
| List syntax themes | `--list-syntax-themes` |
| Show active config | `--show-config` |

## Basic Usage

Delta is a pager by default — use `--paging never` to print directly to stdout.

```bash
git diff | delta
git diff --staged | delta
git show | delta
git log -p | delta
delta file1 file2
delta --diff-args="-U10" file1 file2
```

**⚠️ Quirk:** `delta file1 file2` exits with code 1 when files differ (follows `diff` convention). Use `|| true` in scripts.

## Display Modes

```bash
# Side-by-side
git diff | delta -s

# Line numbers (two columns: old | new)
git diff | delta -n

# Restore +/- prefixes (removed by default for clean copy-paste)
git diff | delta --keep-plus-minus-markers
```

In side-by-side mode, delta wraps long lines. Symbols: `↵` (continues), `↴` (end of wrap), `…` (continuation prefix), `→` (right portion follows).

## Syntax Highlighting

Delta infers the language from the filename in the diff header.

```bash
delta --list-languages              # supported languages
delta --list-syntax-themes          # available themes
git diff | delta --syntax-theme Dracula
git diff | delta --default-language python
```

## Style Customization

Style string syntax: `'<foreground> <background> <attributes>'`.

```bash
git diff | delta --minus-style 'red bold' --plus-style 'green bold'
git diff | delta --minus-style 'syntax auto' --plus-style 'syntax auto'
```

Colors: CSS names (`red`), hex (`"#0e7c0e"` — quote to avoid shell comment), ANSI names (`brightred`), ANSI numbers (`28`). Special: `auto` (delta chooses), `normal` (terminal default), `syntax` (syntax-highlight, fg only), `raw` (pass-through).

Attributes: `bold`, `dim`, `italic`, `reverse`, `strike`, `ul` (underline), `blink`, `hidden`, `omit` (removes element).

Key style targets: `--minus-style` (removed lines), `--plus-style` (added lines), `--zero-style` (unchanged), `--minus-emph-style` / `--plus-emph-style` (word-level changes).

## Troubleshooting

### Delta hangs (waiting for input)

Delta is a pager. Use `--paging never`:

```bash
git diff | delta --paging never
```

### Delta is slow on large diffs

```bash
git diff | delta --max-line-length 1000 --max-syntax-highlighting-length 200
```

### `delta file1 file2` exits with code 1

This is standard `diff` behavior — exit code 1 means differences found, not an error.

### Output looks wrong (no colors, garbled)

```bash
git diff | delta --true-color never   # force 256-color mode
```

## Notes

- Delta formats diff output; it does not compute diffs itself (`delta file1 file2` shells out to `git diff --no-index`).
- Delta strips ANSI colors from input by default. Use `--raw` to pass through unchanged.
- Use `--no-gitconfig` for predictable output in scripts (ignore user's `~/.gitconfig`).
