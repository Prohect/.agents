---
name: sed
description: Use `terminal` sed (GNU v4.9) for stream editing — substitution, deletion, insertion, regex text transformation on files or pipelines. Use when you need to find-and-replace, extract, filter, or transform text in a repeatable, scriptable way.
disable-model-invocation: false
---

# sed — Stream Editor

GNU sed v4.9. A non-interactive stream editor for filtering and transforming text. Reads input line by line, applies commands, and prints the result. Use it for substitution, deletion, insertion, extraction, and any regex-driven text manipulation in files or pipelines.

Commands here are written for the `nu` shell. Paths use `~` (home) and demo files live under `~/.agents/demo/sed/`.

## Quick Reference

| Task                          | Command                                |
| ----------------------------- | -------------------------------------- |
| Replace first match per line  | `sed 's/old/new/' file`                |
| Replace all matches per line  | `sed 's/old/new/g' file`               |
| Delete lines matching pattern | `sed '/pattern/d' file`                |
| Print only matching lines     | `sed -n '/pattern/p' file`             |
| In-place edit (no backup)     | `sed -i 's/old/new/g' file`            |
| In-place with backup          | `sed -i.bak 's/old/new/g' file`        |
| Multiple commands             | `sed -e 's/a/A/' -e 's/b/B/' file`     |
| Lines 5–10 only               | `sed -n '5,10p' file`                  |
| Case-insensitive match        | `sed 's/foo/bar/i'`                    |
| Extended regex                | `sed -E 's/pattern/replacement/' file` |
| Quiet mode (no auto-print)    | `sed -n '...'`                         |
| Append after match            | `sed '/pattern/a\new line' file`       |
| Insert before match           | `sed '/pattern/i\new line' file`       |
| Replace entire line           | `sed '/pattern/c\new line' file`       |
| Transliterate chars           | `sed 'y/abc/xyz/'`                     |

## Basic Substitution

```nu
# Replace first occurrence on each line
sed 's/Hello/Hi/' ~/.agents/demo/sed/src/main.c
# → #include "config.h"
#   ...
#       printf("Hi World\n");
#   ...

# Replace ALL occurrences on each line (g flag)
"foo foo foo" | sed 's/foo/bar/g'
# → bar bar bar

# Replace nth occurrence only (2nd)
"foo foo foo" | sed 's/foo/bar/2'
# → foo bar foo

# Replace nth onward (2g: from 2nd to end)
"foo foo foo foo" | sed 's/foo/bar/2g'
# → foo bar bar bar
```

**Delimiters:** You can use any character, not just `/`. This avoids "leaning toothpick syndrome" when the pattern or replacement contains slashes:

```nu
# Change delimiter to | (useful for paths/URLs)
"http://example.com/path" | sed 's|http://|https://|'
# → https://example.com/path

# Change delimiter to # (for patterns with both / and |)
"a/b|c" | sed 's#a/b#X#'
# → X|c
```

## Addresses & Ranges

Addresses select which lines a command applies to. Without an address, the command applies to all lines.

### Line Numbers

```nu
# Single line
sed -n '3p' ~/.agents/demo/sed/numbers.txt
# → 3 three

# Range of lines
sed -n '3,6p' ~/.agents/demo/sed/numbers.txt
# → 3 three
#   4 four
#   5 five
#   6 six

# From line 5 to end
sed -n '5,$p' ~/.agents/demo/sed/numbers.txt
# → 5 five ... 10 ten

# Every Nth line starting from M (GNU extension: M~N)
sed -n '2~3p' ~/.agents/demo/sed/numbers.txt
# → 2 two
#   5 five
#   8 eight
```

### Pattern Matching

```nu
# Lines matching a regex
sed -n '/^5/p' ~/.agents/demo/sed/numbers.txt
# → 5 five

# Range between two patterns (inclusive)
sed -n '/^3/,/^6/p' ~/.agents/demo/sed/numbers.txt
# → 3 three
#   4 four
#   5 five
#   6 six

# Negated match (lines NOT matching)
sed -n '/TODO/!p' ~/.agents/demo/sed/src/main.c
# → (prints all lines except those with TODO)
```

### Combined Address + Command

```nu
# Substitute only on lines matching a different pattern
"server: localhost\nserver: myserver\nclient: localhost" | sed '/server/s/localhost/127.0.0.1/'
# → server: 127.0.0.1
#   server: myserver
#   client: localhost

# Delete lines 1 and 3
sed '1d; 3d' ~/.agents/demo/sed/src/main.c
```

## Regular Expressions

### Basic vs Extended (-E)

GNU sed supports two regex dialects. The `-E` flag enables Extended Regular Expressions where `+`, `?`, `|`, `(`, `)`, `{`, `}` have special meaning without backslashes.

```nu
# Basic regex: one-or-more is expressed with [0-9][0-9]*
"abc123 def456" | sed 's/[0-9][0-9]*/NUM/'
# → abcNUM def456

# Extended regex: special chars are bare (prefer -E for readability)
"abc123 def456" | sed -E 's/[0-9]+/NUM/'
# → abcNUM def456
```

| Feature       | Basic regex | Extended regex (`-E`) |
| ------------- | ----------- | --------------------- |
| One or more   | `\+`        | `+`                   |
| Zero or one   | `\?`        | `?`                   |
| Alternation   | `\|`        | `|`                   |
| Grouping      | `\( \)`     | `( )`                 |
| Repetition    | `\{n,m\}`   | `{n,m}`               |
| Word boundary | `\b`, `\B`  | `\b`, `\B`            |
| Backreference | `\1`–`\9`   | `\1`–`\9`             |

> ⚠️ In `nu`, inline scripts that rely on `\(`, `\)`, `\{`, `\}`, `\?`, `\[`, or `\]` are unreliable (the backslashes can be stripped on the way to sed). Prefer `-E`, or use a `-f` script file for BRE scripts. See **Quirks & Platform Notes**.

### Common Regex Patterns

```nu
# Backreferences — swap two words
"foo bar" | sed -E 's/(foo) (bar)/\2 \1/'
# → bar foo

# & in replacement = entire match
"The quick brown fox" | sed 's/quick/(&)/'
# → The (quick) brown fox

# Character classes
"The year is 2024" | sed -E 's/[0-9]+/2026/'
# → The year is 2026

# Word boundaries (GNU extension)
"cat catalog scat cat" | sed 's/\bcat\b/dog/g'
# → dog catalog scat dog

# Start/end anchors
"one\ntwo\nthree" | sed -n '/^t/p'
# → two
#   three

"one\ntwo\nthree" | sed -n '/e$/p'
# → one
#   three
```

### Case Conversion in Replacement (GNU Extensions)

```nu
# \U = uppercase until \E or end
# \L = lowercase until \E or end
# \u = uppercase next character only
# \l = lowercase next character only

"HELLO world" | sed -E 's/(.*) (.*)/\L\1 \U\2/'
# → hello WORLD

"hello" | sed 's/./\u&/'
# → Hello

"HELLO" | sed 's/./\l&/'
# → hELLO
```

## Match Flags

| Flag        | Meaning                                                   |
| ----------- | --------------------------------------------------------- |
| `g`         | Replace all occurrences on the line                       |
| `i`         | Case-insensitive match                                    |
| `p`         | Print the line if a substitution was made (use with `-n`) |
| `w file`    | Write the line to `file` if a substitution was made       |
| _number_    | Replace the _nth_ occurrence only                         |
| _number_`g` | Replace from the _nth_ occurrence onward                  |

```nu
# Case-insensitive
"Hello HELLO hello" | sed 's/hello/hi/ig'
# → hi hi hi

# Print only lines where substitution happened
"foo\nbar\nfoo" | sed -n 's/foo/REPLACED/p'
# → REPLACED
#   REPLACED

# Write matched lines to stdout
sed -n 's/Error/ISSUE/w /dev/stdout' ~/.agents/demo/sed/logs/error.log
# → ISSUE on line 42: null pointer
#   ISSUE on line 57: out of memory
#   ISSUE on line 142: null pointer
```

## Delete, Print, Quit

```nu
# Delete lines matching pattern
sed '/TODO/d' ~/.agents/demo/sed/src/main.c

# Delete empty lines
"line1\n\nline2\n\nline3" | sed '/^$/d'
# → line1
#   line2
#   line3

# Print only matching lines (quiet mode)
sed -n '/TODO/p' ~/.agents/demo/sed/src/main.c

# Quit after first match
sed '/FIXME/q' ~/.agents/demo/sed/src/main.c
# → (prints up to and including the FIXME line, then stops)

# Double-space a file (append blank line after each line)
sed G ~/.agents/demo/sed/numbers.txt
```

## Insert, Append, Change

```nu
# Append text AFTER matching line
sed '/TODO/a\// NEW: implement feature' ~/.agents/demo/sed/src/main.c

# Insert text BEFORE matching line
sed '/FIXME/i\// PRIORITY: critical bug' ~/.agents/demo/sed/src/main.c

# Change (replace) entire matching line
sed '/FIXME/c\// DONE: all bugs resolved' ~/.agents/demo/sed/src/main.c

# Insert before first line
sed '1i\START OF FILE' ~/.agents/demo/sed/numbers.txt

# Append after last line
sed '$a\END OF FILE' ~/.agents/demo/sed/numbers.txt
```

## Transliteration (y Command)

The `y` command translates characters one-to-one, like `tr`:

```nu
"hello world" | sed 'y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/'
# → HELLO WORLD

"abc123" | sed 'y/abc/xyz/'
# → xyz123
```

The source and target character sets must have the same length.

## In-Place Editing (`-i`)

```nu
# Edit file in-place (no backup)
sed -i 's/TODO/DONE/g' ~/.agents/demo/sed/src/main.c

# Edit with backup (creates file.bak)
sed -i.bak 's/TODO/DONE/g' ~/.agents/demo/sed/src/main.c
# → file is modified, original saved as file.bak

# In-place on multiple files (use -s for per-file address scoping)
sed -i -s '1s/Error/ISSUE/' file1.log file2.log
# Without -s: line 1 means first line of the combined stream
# With -s: line 1 means first line of each file separately
```

⚠️ **`-i` overwrites files.** Always preview with `sed ... file | lines | first` first, or use `-i.bak` for a safety net. The commands above modify the demo file — run them on a copy if you want to keep the fixtures pristine.

## Multiple Expressions

```nu
# With semicolons
sed 's/TODO/DONE/; s/FIXME/FIXED/' ~/.agents/demo/sed/src/main.c

# With multiple -e flags
sed -e 's/TODO/DONE/' -e 's/FIXME/FIXED/' ~/.agents/demo/sed/src/main.c

# With a script file
let script = ($nu.temp-dir | path join 'edits.sed')
"s/TODO/DONE/\ns/FIXME/FIXED/" | save -f $script
sed -f $script ~/.agents/demo/sed/src/main.c
rm -f $script
```

Script files are useful when the sed program is complex or contains characters that are painful to escape on the command line.

## Advanced: Hold Space & Multi-Line

sed has two buffers: **pattern space** (default, per-line) and **hold space** (auxiliary storage). Commands:

| Command | Action                               |
| ------- | ------------------------------------ |
| `h`     | Copy pattern → hold                  |
| `H`     | Append pattern → hold (with newline) |
| `g`     | Copy hold → pattern                  |
| `G`     | Append hold → pattern (with newline) |
| `x`     | Exchange pattern and hold            |
| `n`     | Read next line into pattern space    |
| `N`     | Append next line to pattern space    |

```nu
# Reverse file lines (tac-like)
sed -n '1!G; h; $p' ~/.agents/demo/sed/numbers.txt
# → 10 ten
#   9 nine
#   ... (reversed)

# Join line pairs with N
"TODO:\n  implement feature\nFIXME:\n  fix bug" | sed '/TODO:/{N; s/\n  / /}'
# → TODO: implement feature
#   FIXME:
#     fix bug

# Swap adjacent line pairs
"line1\nline2\nline3\nline4" | sed -n 'h; n; p; g; p'
# → line2
#   line1
#   line4
#   line3
```

## The `=` Command (Line Numbers)

```nu
# Print line numbers of matches
sed -n '/TODO/=' ~/.agents/demo/sed/src/main.c
# → 6
#   8

# Number all lines (like cat -n)
# Quoting '=' is required in nu, because a bare `sed = file` is parsed as an assignment.
sed '=' ~/.agents/demo/sed/numbers.txt | sed 'N; s/\n/\t/'
# → 1	1 one
#   2	2 two
#   ...
```

## The `l` Command (Visual Debugging)

Shows non-printable characters in a line — tabs as `\t`, line ends as `$`:

```nu
"hello\tworld" | sed -n 'l'
# → hello\tworld$
```

Useful for debugging whitespace and control characters.

## Null-Separated Mode (`-z`)

Treats NUL characters (`\0`) as line separators instead of newlines:

```nu
"line1\0line2\0line3\0" | sed -z 's/line/LINE/g' | str replace --all (char nul) "\n"
# → LINE1
#   LINE2
#   LINE3
```

## Debugging (`--debug`)

GNU sed's `--debug` flag prints the program, each input line, the pattern space before/after each command, and the final output:

```nu
"hello" | sed --debug 's/h/H/'
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

### Code & Config

```nu
# Comment out lines matching a pattern (prefix with #)
sed '/^host/s/^/# /' ~/.agents/demo/sed/config/settings.ini

# Uncomment lines (remove leading "# ")
"# this is commented" | sed 's/^# //'

# Replace version strings
sed -E 's/VERSION "[0-9.]+"/VERSION "2.0.0"/' ~/.agents/demo/sed/src/config.h
```

### Whitespace

```nu
# Strip leading/trailing whitespace
sed 's/^[[:space:]]*//; s/[[:space:]]*$//' ~/.agents/demo/sed/spaces.txt
```

### CSV

```nu
# Extract 2nd column (no backreference, avoids nu backslash quirks)
sed -E 's/^[^,]*,//; s/,.*//' ~/.agents/demo/sed/data.csv
```

### Logs

```nu
# Filter ERROR and WARN lines only (literal brackets need doubled backslashes in nu)
sed -E -n '/\\[(ERROR|WARN)\\]/p' ~/.agents/demo/sed/logs/app.log

# Redact IP addresses
"Connected from 192.168.1.100" | sed -E 's/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[REDACTED]/'
```

### HTML/XML

```nu
# Strip tags
"<p>Hello <b>World</b></p>" | sed 's/<[^>]*>//g'
```

### Extract a Config Section

```nu
sed -n '/\\[server\\]/,/^\\[/p' ~/.agents/demo/sed/config/settings.ini | sed '$d'
# → [server]
#   host = 0.0.0.0
#   port = 8080
```

## Quirks & Platform Notes

### ⚠️ Inline scripts lose some backslashes and braces (nu → MSYS2 sed)

`sed` here is a `nu` wrapper around the MSYS2 `sed.exe`. When `nu` passes a script argument to that executable, the Windows command line is rebuilt and the MSYS2 runtime re-parses it. As a result, some characters in inline scripts are dropped or reinterpreted:

- Bare `{` and `}` are removed. `-E 's/[0-9]{4}/2026/'` reaches sed as `s/[0-9]4/2026/`.
- Backslashes before `(`, `)`, `{`, `}`, `?`, `[`, `]` are stripped.
- In some contexts (e.g. scripts containing commas) backslashes before `1`/`2`/`+` are also stripped.
- Commas can trigger argument splitting, which mangles scripts such as `a{1,2}`.

**Workarounds, in order of preference:**

1. Use `-E` (ERE) so `+`, `?`, `|`, `(`, `)` need no backslashes.
2. For ERE `{n,m}` intervals, escape the braces — `\{4\}` arrives as `{4}`.
3. For a literal `[`/`]` in a pattern, double the backslash — `\\[` arrives as `\[`.
4. For BRE scripts that need `\(`, `\)`, `\{`, `\}`, `\?`, put the script in a file and use `-f`.

```nu
# ❌ bare braces vanish → sed sees s/[0-9]4/2026/
"2024" | sed -E 's/[0-9]{4}/2026/'
# → 202026

# ✅ escaped braces arrive as {4}
"2024" | sed -E 's/[0-9]\{4\}/2026/'
# → 2026

# ❌ \ and [ are stripped → [ERROR] becomes a character class and every line matches
sed -E -n '/\[ERROR\]|\[WARN\]/p' ~/.agents/demo/sed/logs/app.log

# ✅ double the backslash before literal brackets
sed -E -n '/\\[(ERROR|WARN)\\]/p' ~/.agents/demo/sed/logs/app.log
# → 2024-01-01 10:01:00 [ERROR] Connection refused
#   2024-01-01 10:02:00 [WARN] High memory usage
#   2024-01-01 10:04:00 [ERROR] Timeout
```

### Literal Backslash in Patterns

`nu` single quotes are fully literal, so write exactly what sed needs: `\\` matches a literal backslash. Use single quotes for Windows paths too (`\U` is an invalid escape in nu double quotes).

```nu
# ✅ two backslashes in the script = one literal backslash in sed
'C:\Users\me' | sed 's|\\|/|g'
# → C:/Users/me
```

### Prefer Single Quotes for sed Scripts

`nu` single quotes do no escaping or interpolation. Double quotes process escape sequences (`\n`, `\t`, `\0`) and reject unknown ones (`\1`, `\2`, `\U`). Interpolated strings (`$"..."`) evaluate `(expr)`; use them deliberately, not for sed scripts. There is no `!` history expansion in `nu`.

```nu
# ❌ double quotes reject \2
"foo bar" | sed -E "s/(foo) (bar)/\2 \1/"
# → nu::parser::error: unrecognized escape sequence '\2'

# ✅ single quotes
"foo bar" | sed -E 's/(foo) (bar)/\2 \1/'
# → bar foo
```

### CRLF Handling

By default, GNU sed treats `\r\n` line endings: it strips the `\r` on input and adds it back on output (if the input had CRLF). This means patterns won't match `\r` unless you use `-b`:

```nu
# Default: \r is stripped
"hello\r\n" | sed 's/hello/HELLO/' | sed -n 'l'
# → HELLO$

# Binary mode: \r is preserved
"hello\r\n" | sed -b 's/hello/HELLO/' | sed -b -n 'l'
# → HELLO\r$
```

For Windows text files with CRLF endings, the default behavior is usually what you want. Use `-b` when you need to match or preserve `\r` literally.

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

The `s/pattern/replacement/p` flag prints the line _only if the substitution was made_, unlike `p` command which always prints:

```nu
"foo\nbar\nfoo" | sed -n 's/foo/XXX/p'
# → XXX
#   XXX
# (bar is not printed because no substitution occurred on that line)
```
