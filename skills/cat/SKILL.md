---
name: cat
description: Use GNU cat (coreutils 8.32) for reading, concatenating, and displaying files. Use when you need to inspect file contents, merge files, number lines, reveal special characters (tabs, line endings, non-printing), or squeeze blank lines.
---

# cat — Concatenate & Display Files

`cat` (GNU coreutils 8.32) reads files and writes their contents to standard output. It's the go-to tool for quickly inspecting files, concatenating multiple files, and adding visual annotations like line numbers or special-character markers.

## Quick Reference

| Task | Command |
|------|---------|
| Print one file | `cat file` |
| Concatenate multiple files | `cat a.txt b.txt c.txt` |
| Number all lines | `cat -n file` |
| Number only non-blank lines | `cat -b file` |
| Squeeze repeated blank lines | `cat -s file` |
| Show `$` at line ends | `cat -E file` |
| Show tabs as `^I` | `cat -T file` |
| Show all hidden characters | `cat -A file` |
| Show non-printing bytes | `cat -v file` |
| Interleave stdin with files | `echo "text" \| cat file -` |
| Create file from stdin | `cat > newfile.txt` |
| Append to file | `cat >> existing.txt` |

## Basic Reading & Concatenation

```bash
# Print a single file
cat "$HOME/.agents/demo/cat/src/hello.txt"
# → Hello, World!
#   This is a test file.
#   It has three lines.

# Concatenate multiple files in order
cat "$HOME/.agents/demo/cat/src/hello.txt" "$HOME/.agents/demo/cat/src/main.rs"
# → Hello, World!
#   This is a test file.
#   It has three lines.
#   fn main() {
#       println!("Hello, world!");
#   }

# Use shell globs to concat all matching files
cat "$HOME/.agents/demo/cat/src/"*.rs
# → fn main() {
#       println!("Hello, world!");
#   }
```

## Line Numbering

```bash
# -n: number all lines (including blank ones)
cat -n "$HOME/.agents/demo/cat/src/hello.txt"
# →      1	Hello, World!
#        2	This is a test file.
#        3	It has three lines.

# -b: number only non-blank lines (overrides -n)
cat -b "$HOME/.agents/demo/cat/test/notes.txt"
# →      1	# My Notes
#
#
#        2	## Section 1
#
#        3	Content here.
#
#
#        4	## Section 2
#
#        5	More content.

# -b overrides -n when both are given
cat -nb "$HOME/.agents/demo/cat/test/notes.txt"
# (same as -b alone — only non-blank lines numbered)
```

**Note:** `-b` and `-n` together produce the same output as `-b` alone. `-b` always wins.

Line numbers are right-aligned in a 6-character field followed by a tab (GNU `%6d\t` format), so single-digit numbers start with 5 leading spaces.

## Blank Line Squeezing

```bash
# -s: collapse consecutive blank lines into one
cat -s "$HOME/.agents/demo/cat/test/notes.txt"
# → # My Notes
#
#   ## Section 1
#
#   Content here.
#
#   ## Section 2
#
#   More content.

# Combine -s with -n to see the result (numbers squeezed output)
cat -ns "$HOME/.agents/demo/cat/test/notes.txt"
# →      1	# My Notes
#        2
#        3	## Section 1
#        4
#        5	Content here.
#        6
#        7	## Section 2
#        8
#        9	More content.
```

## Revealing Hidden Characters

```bash
# -E: mark end of each line with $
cat -E "$HOME/.agents/demo/cat/src/hello.txt"
# → Hello, World!$
#   This is a test file.$
#   It has three lines.$

# -T: display tab characters as ^I
cat -T "$HOME/.agents/demo/cat/src/tabs.tsv"
# → Name^IAge^ICity
#   Alice^I30^INYC
#   Bob^I25^ILA

# -v: show non-printing characters (except TAB and LFD)
cat -v "$HOME/.agents/demo/cat/resources/data.bin"
# → Normal text.^A^B^C^DEnd of data.

# -A: show everything — equivalent to -vET
cat -A "$HOME/.agents/demo/cat/src/tabs.tsv"
# → Name^IAge^ICity$
#   Alice^I30^INYC$
#   Bob^I25^ILA$
```

### Detecting Windows line endings (CRLF)

```bash
# CRLF (\r\n) shows as ^M$ with -A
cat -A "$HOME/.agents/demo/cat/src/windows.txt"
# → line1^M$
#   line2^M$
#   line3^M$

# Compare with Unix line endings (just $)
cat -A "$HOME/.agents/demo/cat/src/hello.txt"
# → Hello, World!$
#   This is a test file.$
#   It has three lines.$
```

**`^M` = carriage return (`\r`), `$` = line feed (`\n`).** Seeing `^M$` means the file uses Windows line endings.

## Combining Options

Options can be combined. Short flags work as a single string or separately:

```bash
# These three forms are equivalent (syntax examples — replace "file" with your path):
cat -snE somefile.txt
cat -s -n -E somefile.txt
cat -s -nE somefile.txt

# Common combinations:
cat -bE somefile.txt   # number non-blanks + show line ends
cat -sn somefile.txt   # squeeze blanks + number all lines
cat -bT somefile.txt   # number non-blanks + show tabs
```

## Reading from stdin

```bash
# cat with no arguments: copies stdin to stdout
echo "direct input" | cat
# → direct input

# - as a placeholder for stdin among file arguments
echo "from stdin" | cat "$HOME/.agents/demo/cat/src/hello.txt" -
# → Hello, World!
#   This is a test file.
#   It has three lines.
#   from stdin

# Read stdin then a file
echo "header line" | cat - "$HOME/.agents/demo/cat/src/hello.txt"
# → header line
#   Hello, World!
#   This is a test file.
#   It has three lines.
```

## Files with Spaces in Names

Double-quote the path:

```bash
cat "$HOME/.agents/demo/cat/src/Config file.toml"
# → [project]
#   name = "demo"
#   version = "1.0"

cat "$HOME/.agents/demo/cat/src/quick notes.md"
# → # Quick Notes
#
#   - Item 1
#   - Item 2
```

## Error Handling

```bash
# Non-existent file → error message + non-zero exit
cat "$HOME/.agents/demo/cat/nope.txt"
# → cat: .../nope.txt: No such file or directory
# (exit code 1)

# Directory instead of file → error
cat "$HOME/.agents/demo/cat/src"
# → cat: .../src: Is a directory
# (exit code 1)

# Empty file → no output, no error (success)
cat "$HOME/.agents/demo/cat/src/empty.log"
# → (no output, exit code 0)
```

**⚠️ `cat` processes all arguments before exiting.** If any file fails, the error is printed and processing continues with remaining files. The exit code will be non-zero if any file failed.

## Common Recipes

```bash
# Peek at a file with line numbers
cat -n "$HOME/proj/README.md"

# Check for CRLF line endings
cat -A "$HOME/proj/somefile.txt" | head -n 3

# Squeeze blank lines and number the result
cat -ns "$HOME/proj/notes.md"

# Reveal tabs that should be spaces
cat -T "$HOME/proj/src/main.rs"

# Quick file creation (type content, Ctrl+D to finish)
cat > "$HOME/proj/newfile.txt"

# Concatenate into a new file
cat header.txt body.txt footer.txt > combined.txt

# Append to an existing file
cat extra-content.txt >> combined.txt

# Pipe to other tools
cat file.txt | grep "pattern"
```

## Notes

- **`cat` is not a pager.** For large files, pipe to `less` or use `head`/`tail` to avoid flooding the terminal: `cat large.log | less`.
- **Binary files can garble the terminal.** If output looks scrambled after `cat` on a binary file, run `reset` to restore the terminal. Use `cat -v` to safely inspect unknown files.
- **`-u` is ignored** on all modern systems (it was for unbuffered output on ancient Unix). It's silently accepted but does nothing.
- **`-b` overrides `-n`.** When both are specified, only non-blank lines are numbered.
- **`-A` = `-vET`** — a single flag that shows all hidden characters (non-printing bytes, tabs, and line ends).
- **Use `$HOME` in paths, never hardcode usernames.** `"$HOME/.agents/demo/cat"` is portable; `"C:\Users\76288\..."` is not.
- **On Windows, `cat` handles CRLF files transparently.** Lines with `\r\n` display normally; use `-A` to detect them.
