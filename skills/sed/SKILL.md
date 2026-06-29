---
name: sed
description: Use GNU sed (4.9) for stream editing — substitution, deletion, insertion, regex text transformation on files or pipelines. Use when you need to find-and-replace, extract, filter, or transform text in a repeatable, scriptable way.
---

# sed — Stream Editor

GNU sed v4.9. A non-interactive stream editor for filtering and transforming text. Reads input line by line, applies commands, and prints the result. Use it for substitution, deletion, insertion, extraction, and any regex-driven text manipulation in files or pipelines.

## Quick Reference

| Task | Command |
|------|---------|
| Replace first match per line | `sed 's/old/new/' file` |
| Replace all matches per line | `sed 's/old/new/g' file` |
| Delete lines matching pattern | `sed '/pattern/d' file` |
| Print only matching lines | `sed -n '/pattern/p' file` |
| In-place edit (no backup) | `sed -i 's/old/new/g' file` |
| In-place with backup | `sed -i.bak 's/old/new/g' file` |
| Multiple commands | `sed -e 's/a/A/' -e 's/b/B/' file` |
| Lines 5–10 only | `sed -n '5,10p' file` |
| Case-insensitive match | `sed 's/foo/bar/i'` |
| Extended regex | `sed -E 's/pattern/replacement/' file` |
| Quiet mode (no auto-print) | `sed -n '...'` |
| Append after match | `sed '/pattern/a\new line' file` |
| Insert before match | `sed '/pattern/i\new line' file` |
| Replace entire line | `sed '/pattern/c\new line' file` |
| Transliterate chars | `sed 'y/abc/xyz/'` |

## Basic Substitution

```bash
# Replace first occurrence on each line
sed 's/Hello/Hi/' "$HOME/.agents/demo/sed/src/main.c"
# → #include "config.h"
#   ...
#       printf("Hi World\n");
#   ...

# Replace ALL occurrences on each line (g flag)
echo "foo foo foo" | sed 's/foo/bar/g'
# → bar bar bar

# Replace nth occurrence only (2nd)
echo "foo foo foo" | sed 's/foo/bar/2'
# → foo bar foo

# Replace nth onward (2g: from 2nd to end)
echo "foo foo foo foo" | sed 's/foo/bar/2g'
# → foo bar bar bar
```

**Delimiters:** You can use any character, not just `/`. This avoids "leaning toothpick syndrome" when the pattern or replacement contains slashes:

```bash
# Change delimiter to | (useful for paths/URLs)
echo "http://example.com/path" | sed 's|http://|https://|'
# → https://example.com/path

# Change delimiter to # (for patterns with both / and |)
echo "a/b|c" | sed 's#a/b#X#'
# → X|c
```

## Addresses & Ranges

Addresses select which lines a command applies to. Without an address, the command applies to all lines.

### Line Numbers

```bash
# Single line
sed -n '3p' "$HOME/.agents/demo/sed/numbers.txt"
# → 3 three

# Range of lines
sed -n '3,6p' "$HOME/.agents/demo/sed/numbers.txt"
# → 3 three
#   4 four
#   5 five
#   6 six

# From line 5 to end
sed -n '5,$p' "$HOME/.agents/demo/sed/numbers.txt"
# → 5 five ... 10 ten

# Every Nth line starting from M (GNU extension: M~N)
sed -n '2~3p' "$HOME/.agents/demo/sed/numbers.txt"
# → 2 two
#   5 five
#   8 eight
```

### Pattern Matching

```bash
# Lines matching a regex
sed -n '/^5/p' "$HOME/.agents/demo/sed/numbers.txt"
# → 5 five

# Range between two patterns (inclusive)
sed -n '/^3/,/^6/p' "$HOME/.agents/demo/sed/numbers.txt"
# → 3 three
#   4 four
#   5 five
#   6 six

# Negated match (lines NOT matching)
sed -n '/TODO/!p' "$HOME/.agents/demo/sed/src/main.c"
# → (prints all lines except those with TODO)
```

### Combined Address + Command

```bash
# Substitute only on lines matching a different pattern
echo -e "server: localhost\nserver: myserver\nclient: localhost" | sed '/server/s/localhost/127.0.0.1/'
# → server: 127.0.0.1
#   server: myserver
#   client: localhost

# Delete lines 1 and 3
sed '1d; 3d' "$HOME/.agents/demo/sed/src/main.c"
```

## Regular Expressions

### Basic vs Extended (-E)

GNU sed supports two regex dialects. The `-E` flag enables Extended Regular Expressions where `+`, `?`, `|`, `(`, `)`, `{`, `}` have special meaning without backslashes.

```bash
# Basic regex: special chars need backslash
echo "abc123 def456" | sed 's/[0-9]\+/NUM/'
# → abcNUM def456

# Extended regex: special chars are bare (prefer -E for readability)
echo "abc123 def456" | sed -E 's/[0-9]+/NUM/'
# → abcNUM def456
```

| Feature | Basic regex | Extended regex (`-E`) |
|---------|-------------|----------------------|
| One or more | `\+` | `+` |
| Zero or one | `\?` | `?` |
| Alternation | `\|` | `\|` |
| Grouping | `\( \)` | `( )` |
| Repetition | `\{n,m\}` | `{n,m}` |
| Word boundary | `\b`, `\B` | `\b`, `\B` |
| Backreference | `\1`–`\9` | `\1`–`\9` |

### Common Regex Patterns

```bash
# Backreferences — swap two words
echo "foo bar" | sed -E 's/(foo) (bar)/\2 \1/'
# → bar foo

# & in replacement = entire match
echo "The quick brown fox" | sed 's/quick/(&)/'
# → The (quick) brown fox

# Character classes
echo "The year is 2024" | sed -E 's/[0-9]{4}/2026/'
# → The year is 2026

# Word boundaries (GNU extension)
echo "cat catalog scat cat" | sed 's/\bcat\b/dog/g'
# → dog catalog scat dog

# Start/end anchors
echo -e "one\ntwo\nthree" | sed -n '/^t/p'
# → two
#   three

echo -e "one\ntwo\nthree" | sed -n '/e$/p'
# → one
#   three
```

### Case Conversion in Replacement (GNU extensions)

```bash
# \U = uppercase until \E or end
# \L = lowercase until \E or end
# \u = uppercase next character only
# \l = lowercase next character only

echo "HELLO world" | sed -E 's/(.*) (.*)/\L\1 \U\2/'
# → hello WORLD

echo "hello" | sed 's/./\u&/'
# → Hello

echo "HELLO" | sed 's/./\l&/'
# → hELLO
```

## Match Flags

| Flag | Meaning |
|------|---------|
| `g` | Replace all occurrences on the line |
| `i` | Case-insensitive match |
| `p` | Print the line if a substitution was made (use with `-n`) |
| `w file` | Write the line to `file` if a substitution was made |
| *number* | Replace the *nth* occurrence only |
| *number*`g` | Replace from the *nth* occurrence onward |

```bash
# Case-insensitive
echo "Hello HELLO hello" | sed 's/hello/hi/ig'
# → hi hi hi

# Print only lines where substitution happened
echo -e "foo\nbar\nfoo" | sed -n 's/foo/REPLACED/p'
# → REPLACED
#   REPLACED

# Write matched lines to file
sed -n 's/Error/ISSUE/w /dev/stdout' "$HOME/.agents/demo/sed/logs/error.log"
# → ISSUE on line 42: null pointer
#   ISSUE on line 57: out of memory
#   ISSUE on line 142: null pointer
```

## Delete, Print, Quit

```bash
# Delete lines matching pattern
sed '/TODO/d' "$HOME/.agents/demo/sed/src/main.c"

# Delete empty lines
echo -e "line1\n\nline2\n\nline3" | sed '/^$/d'
# → line1
#   line2
#   line3

# Print only matching lines (quiet mode)
sed -n '/TODO/p' "$HOME/.agents/demo/sed/src/main.c"

# Quit after first match
sed '/FIXME/q' "$HOME/.agents/demo/sed/src/main.c"
# → (prints up to and including the FIXME line, then stops)

# Double-space a file (append blank line after each line)
sed G "$HOME/.agents/demo/sed/numbers.txt"
```

## Insert, Append, Change

```bash
# Append text AFTER matching line
sed '/TODO/a\// NEW: implement feature' "$HOME/.agents/demo/sed/src/main.c"

# Insert text BEFORE matching line
sed '/FIXME/i\// PRIORITY: critical bug' "$HOME/.agents/demo/sed/src/main.c"

# Change (replace) entire matching line
sed '/FIXME/c\// DONE: all bugs resolved' "$HOME/.agents/demo/sed/src/main.c"

# Insert before first line
sed '1i\START OF FILE' "$HOME/.agents/demo/sed/numbers.txt"

# Append after last line
sed '$a\END OF FILE' "$HOME/.agents/demo/sed/numbers.txt"
```

## Transliteration (y command)

The `y` command translates characters one-to-one, like `tr`:

```bash
echo "hello world" | sed 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/'
# → HELLO WORLD

echo "abc123" | sed 'y/abc/xyz/'
# → xyz123
```

The source and target character sets must have the same length.

## In-Place Editing (`-i`)

```bash
# Edit file in-place (no backup)
sed -i 's/TODO/DONE/g' "$HOME/.agents/demo/sed/src/main.c"

# Edit with backup (creates file.bak)
sed -i.bak 's/TODO/DONE/g' "$HOME/.agents/demo/sed/src/main.c"
# → file is modified, original saved as file.bak

# In-place on multiple files (use -s for per-file address scoping)
sed -i -s '1s/Error/ISSUE/' file1.log file2.log
# Without -s: line 1 means first line of the combined stream
# With -s: line 1 means first line of each file separately
```

⚠️ **`-i` overwrites files.** Always test with `sed ... file | head` first, or use `-i.bak` for a safety net.

## Multiple Expressions

```bash
# With semicolons
sed 's/TODO/DONE/; s/FIXME/FIXED/' "$HOME/.agents/demo/sed/src/main.c"

# With multiple -e flags
sed -e 's/TODO/DONE/' -e 's/FIXME/FIXED/' "$HOME/.agents/demo/sed/src/main.c"

# With a script file
echo 's/TODO/DONE/' > /tmp/edits.sed
echo 's/FIXME/FIXED/' >> /tmp/edits.sed
sed -f /tmp/edits.sed "$HOME/.agents/demo/sed/src/main.c"
```

Script files are useful when the sed program is complex or contains characters that are painful to escape on the command line.

## Advanced: Hold Space & Multi-line

sed has two buffers: **pattern space** (default, per-line) and **hold space** (auxiliary storage). Commands:

| Command | Action |
|---------|--------|
| `h` | Copy pattern → hold |
| `H` | Append pattern → hold (with newline) |
| `g` | Copy hold → pattern |
| `G` | Append hold → pattern (with newline) |
| `x` | Exchange pattern and hold |
| `n` | Read next line into pattern space |
| `N` | Append next line to pattern space |

```bash
# Reverse file lines (tac-like)
sed -n '1!G; h; $p' "$HOME/.agents/demo/sed/numbers.txt"
# → 10 ten
#   9 nine
#   ... (reversed)

# Join line pairs with N
echo -e "TODO:\n  implement feature\nFIXME:\n  fix bug" | sed '/TODO:/{N; s/\n  / /}'
# → TODO: implement feature
#   FIXME:
#     fix bug

# Swap adjacent line pairs
echo -e "line1\nline2\nline3\nline4" | sed -n 'h; n; p; g; p'
# → line2
#   line1
#   line4
#   line3
```

## The `=` Command (Line Numbers)

```bash
# Print line numbers of matches
sed -n '/TODO/=' "$HOME/.agents/demo/sed/src/main.c"
# → 6
#   8

# Number all lines (like cat -n)
sed = "$HOME/.agents/demo/sed/numbers.txt" | sed 'N; s/\n/\t/'
# → 1	1 one
#   2	2 two
#   ...
```

## The `l` Command (Visual Debugging)

Shows non-printable characters in a line — tabs as `\t`, line ends as `$`:

```bash
echo -e "hello\tworld" | sed -n 'l'
# → hello\tworld$
```

Useful for debugging whitespace and control characters.

## Null-Separated Mode (`-z`)

Treats NUL characters (`\0`) as line separators instead of newlines. Useful for processing `find ... -print0` output:

```bash
printf 'line1\0line2\0line3\0' | sed -z 's/line/LINE/g' | tr '\0' '\n'
# → LINE1
#   LINE2
#   LINE3
```

## Debugging (`--debug`)

GNU sed's `--debug` flag prints the program, each input line, the pattern space before/after each command, and the final output:

```bash
echo "hello" | sed --debug 's/h/H/' 2>&1
# → SED PROGRAM:
#     s/h/H/
#   INPUT:   'STDIN' line 1
#   PATTERN: hello
#   COMMAND: s/h/H/
#   MATCHED REGEX REGISTERS
#     regex[0] = 0-1 'h'
#   PATTERN: Hello
#   END-OF-CYCLE:
#   Hello
```

## Common Recipes

```bash
### Code & Config
# Comment out lines matching a pattern (prefix with #)
sed '/^host/s/^/# /' "$HOME/.agents/demo/sed/config/settings.ini"

# Uncomment lines (remove leading "# ")
echo "# this is commented" | sed 's/^# //'

# Replace version strings
sed -E 's/VERSION "[0-9.]+"/VERSION "2.0.0"/' "$HOME/.agents/demo/sed/src/config.h"

### Whitespace
# Strip leading/trailing whitespace
sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "$HOME/.agents/demo/sed/spaces.txt"

### CSV
# Extract 2nd column
sed -E 's/^[^,]*,([^,]*).*/\1/' "$HOME/.agents/demo/sed/data.csv"

### Logs
# Filter ERROR and WARN lines only
sed -n '/\[ERROR\]\|\[WARN\]/p' "$HOME/.agents/demo/sed/logs/app.log"

# Redact IP addresses
echo "Connected from 192.168.1.100" | sed -E 's/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[REDACTED]/'

### HTML/XML
# Strip tags
echo "<p>Hello <b>World</b></p>" | sed 's/<[^>]*>//g'

### Extract a config section
sed -n '/\[server\]/,/^\[/p' "$HOME/.agents/demo/sed/config/settings.ini" | sed '$d'
# → [server]
#   host = 0.0.0.0
#   port = 8080
```

## Quirks & Platform Notes

### ⚠️ Literal Backslash in Patterns (MSYS2 Shell)

On this MSYS2/Windows shell, `\\\\` must be used in the terminal command to pass `\\` to sed. The shell consumes one level of escaping, even inside single quotes:

```bash
# ❌ Fails — sed sees s|\|/|g (unterminated)
sed 's|\\|/|g' /tmp/bs_test.txt

# ✅ Works — sed sees s|\\|/|g (literal backslash → forward slash)
sed 's|\\\\|/|g' /tmp/bs_test.txt
# → C:/Users/76288/project/src/main.c
```

This only affects consecutive backslashes. Single backslash patterns (`\n`, `\t`, `\+`, `\(`, `\1`) work normally because they're already a single backslash in the sed script.

### CRLF Handling

By default, GNU sed treats `\r\n` line endings: it strips the `\r` on input and adds it back on output (if the input had CRLF). This means patterns won't match `\r` unless you use `-b`:

```bash
# Default: \r is stripped
printf 'hello\r\n' | sed 's/hello/HELLO/' | od -c
# → HELLO\n  (no \r)

# Binary mode: \r is preserved
printf 'hello\r\n' | sed -b 's/hello/HELLO/' | od -c
# → HELLO\r\n
```

For Windows text files with CRLF endings, the default behavior is usually what you want. Use `-b` when you need to match or preserve `\r` literally.

### Macros in Double Quotes

The shell expands `$VAR` and backticks inside double quotes. Prefer single quotes for sed scripts:

```bash
# ❌ Shell expands $100 to 00 before sed runs
echo "price: $100" | sed "s/\$100/USD 100/"
# → price: 00

# ✅ Single quotes prevent expansion
echo 'price: $100' | sed 's/\$100/USD 100/'
# → price: USD 100
```

Also use single quotes around `!` in patterns to prevent history expansion in bash.

### `-i` on Symlinks

By default, `-i` breaks symlinks (replaces with a regular file). Use `--follow-symlinks` to edit the target file through the symlink.

### GNU vs POSIX

GNU sed adds many extensions. To restrict to POSIX-compliant features, use `--posix`. Notable GNU-only features:

- `\b`, `\B` word boundaries
- `\u`, `\l`, `\U`, `\L` case conversion in replacement
- `\n` in replacement (inserts a newline)
- `M~N` step addressing (e.g., `1~2` for odd lines)
- `-z` null-separated mode
- `--debug` tracing
- `i`, `I` flags for case-insensitive matching

### `-n` with `p` Flag

The `s/pattern/replacement/p` flag prints the line *only if the substitution was made*, unlike `p` command which always prints:

```bash
echo -e "foo\nbar\nfoo" | sed -n 's/foo/XXX/p'
# → XXX
#   XXX
# (bar is not printed because no substitution occurred on that line)
```
