---
name: awk
description: Use `terminal` awk (GNU v5.4.0) for text processing -- field extraction, filtering, reporting, CSV handling, and data transformation. Use when you need to parse columnar data, compute aggregates, or transform structured text in files or pipelines.
disable-model-invocation: false
---

# awk -- GNU Pattern Scanning & Processing Language

`awk` v5.4.0 (GNU). Present in the MSYS2/Git Bash environment. Use for field-based text processing, filtering by pattern or condition, computing sums/averages/counts, and transforming structured data.

All examples use files from `~/.agents/demo/awk/`. cd there to run them:

```nu
cd ~/.agents/demo/awk
```

## ⚠️ Windows/MSYS2/Nushell Quirks

### Backslashes in awk Programs

MSYS2, nu, and awk each process backslashes, creating multi-level escaping that depends on context (single quotes, double quotes, regex, strings). **The universal fix: use forward slashes in paths.**

```nu
# ✅ Forward slashes -- zero escaping issues
awk '{print FILENAME}' ./names.txt
```

If your data contains backslashes, prefer a script file (`-f`) to avoid shell escaping. Write the pattern file from nu with `save --raw` using a single-quoted string (single-quoted nu strings are raw -- no escape processing). Write it to `$nu.temp-dir` and clean up afterward so the demo directory stays pristine:

```nu
let script = ($nu.temp-dir | path join 'pattern.awk')
'/C:\\Program Files\\/' | save --raw -f $script
awk -f $script paths.txt
rm -f $script
```

If you see `warning: escape sequence \X treated as plain X`, you have a backslash count mismatch. In nu, single-quoted strings are raw (backslashes stay literal) while double-quoted strings interpret `\n`, `\t`, `\\`, etc. Prefer forward slashes or `save --raw` with a single-quoted string.

### Single Quotes Inside the awk Program

nu has no bash-style `'\''` trick inside single-quoted strings, and nu mangles single-quote characters in arguments passed to external commands. Use awk's octal escape `"\047"` to print a literal single quote:

```nu
# ✅ Works in nu -- single quote via awk octal escape
awk '{print "\047" $1 "\047"}' names.txt
# Output: 'Alice'
```

Do not try the bash idiom `awk -v q="'" ...` in nu; the `'` does not survive nu's external-command argument handling.

### `!` Inside awk Programs

`!` inside single-quoted awk programs is safe in nu -- there is no history expansion, and a single-quoted string is literal:

```nu
# Safe -- single-quoted, no history expansion
awk '!seen[$0]++' dups.txt
```

### Passing nu Variables into awk

nu only interpolates inside double-quoted strings, and a quote character in the middle of a bare token is literal (not a string delimiter). Build the `-v` assignment as a single interpolated string:

```nu
let threshold = 28
awk -v $"t=($threshold)" '$2 > t' names.txt
```

```nu
# ❌ Not interpolated -- awk receives the literal text q=$threshold
let threshold = 28
awk -v q=$threshold '$2 > q' names.txt

# ✅ Interpolated
let threshold = 28
awk -v $"t=($threshold)" '$2 > t' names.txt
```

### `-F` Values with Spaces or Brackets

Put a space between `-F` and its value when the value contains spaces or `[`:

```nu
# ✅ Space before the value
awk -F '[ ,]' '{print $1, $3}' scores.csv

# ❌ Attached quoted value reaches awk with the quotes, so it does not split as intended
awk -F'[ ,]' '{print $1, $3}' scores.csv
```

A plain attached separator such as `-F,` is fine; only quoted/space/bracket values need the space.

## Basic Usage

```nu
# Print specific fields (default FS is whitespace)
awk '{print $1, $3}' names.txt

# Print all lines matching a pattern
awk '/Alice/' names.txt

# Filter by field comparison
awk '$2 > 28 {print $1, $2}' names.txt

# Use a different field separator
awk -F, '{print $1, $3}' scores.csv

# Pass a nu variable into awk
let threshold = 28
awk -v $"t=($threshold)" '$2 > t' names.txt

# BEGIN and END blocks
awk 'BEGIN {print "---start---"} {print $0} END {print "---end---"}' names.txt
```

## Built-in Variables

```nu
# NF -- number of fields on the current line
awk '{print NF, $0}' names.txt

# NR -- current record number (cumulative across all files)
awk '{print NR, $0}' names.txt

# FNR -- record number within the current file (resets per file)
awk '{print "NR="NR, "FNR="FNR, $0}' names.txt dups.txt

# FILENAME -- name of the current input file
awk '{print FILENAME": "$0}' names.txt dups.txt

# OFS -- output field separator (default: space)
awk 'BEGIN {OFS=":"} {print $1, $2, $3}' names.txt

# ORS -- output record separator (default: newline)
awk 'BEGIN {ORS="|"} {print $1}' names.txt

# FS -- input field separator, can be a regex
awk -F '[ ,]' '{print $1, $3}' scores.csv
```

## Field Operations

```nu
# Conditional field extraction
awk '$3 == "Engineer" {print $1}' names.txt

# Regex match on a specific field
awk '$3 ~ /Engineer/' names.txt

# Negation: lines NOT matching
awk '$3 !~ /Engineer/' names.txt
awk '! /Alice/' names.txt

# Multiple conditions (AND / OR)
awk '$2 >= 30 || $3 == "Manager"' names.txt
awk '$2 >= 25 && $2 <= 30' names.txt

# Line range (between two patterns)
awk '/Bob/,/David/' names.txt
```

## Aggregation & Math

```nu
# Sum a column
awk '{sum += $2} END {print sum}' names.txt

# Average
awk '{sum += $2; count++} END {print sum/count}' names.txt

# Conditional sum (only Engineers)
awk '$3 == "Engineer" {sum += $2} END {print sum}' names.txt

# Count occurrences
awk '{count[$3]++} END {for (role in count) print role, count[role]}' names.txt

# Find max value
awk '$2 > max {max = $2; name = $1} END {print name, max}' names.txt
```

## String Functions

```nu
# toupper / tolower
awk '{print toupper($1)}' names.txt

# substr -- extract substring (1-based index)
awk '{print substr($1, 1, 3)}' names.txt

# length -- string length
awk '{print $1, length($1)}' names.txt

# index -- find position of substring (0 if not found)
awk '{print index($1, "i")}' names.txt

# gsub -- global replace (in-place on $0 or target)
awk '{gsub(/Engineer/, "DEV"); print}' names.txt

# match + RSTART/RLENGTH -- capture position
awk 'match($0, /[A-Z][a-z]+/) {print substr($0, RSTART, RLENGTH)}' names.txt

# split -- split string into array
awk '{n = split($0, a, ","); print a[1], a[3]}' scores.csv

# sprintf -- format into a string
awk '{print sprintf("%s (%d)", $1, $2)}' names.txt
```

## Formatted Output (printf)

```nu
# Column-aligned output
awk '{printf "%-10s %3d\n", $1, $2}' names.txt

# CSV-safe quoting
awk -F, '{printf "\"%s\",\"%s\"\n", $1, $3}' scores.csv
```

## Deduplication & Counting

```nu
# Print unique lines (first occurrence only)
awk '!seen[$0]++' dups.txt

# Count duplicate occurrences
awk '{count[$0]++} END {for (item in count) print item, count[item]}' dups.txt

# Sort output by value (via asorti)
awk '{arr[$2] = $1} END {n = asorti(arr, dest); for (i = 1; i <= n; i++) print dest[i], arr[dest[i]]}' names.txt
```

## Flow Control

```nu
# if / else
awk '{if ($2 >= 30) print $1, "senior"; else print $1, "junior"}' names.txt

# next -- skip to next record
awk 'NR <= 1 {next} {print $0}' names.txt

# nextfile -- skip to next file
awk '{print $0} /David/ {nextfile}' names.txt

# exit -- stop processing
awk '{print $0} $2 > 30 {exit}' names.txt

# for loop (in BEGIN block, no input needed)
awk 'BEGIN {for (i = 1; i <= 5; i++) print i}'
```

## Array Operations

```nu
# Check if key exists in array
awk 'BEGIN {a["Alice"] = 1; print ("Alice" in a)}'

# Delete an array element
awk '{a[$1] = $2} END {delete a["Alice"]; for (i in a) print i, a[i]}' names.txt

# Iterate array keys
awk '{count[$3]++} END {for (role in count) print role, count[role]}' names.txt
```

## Input Sources

```nu
# Pipe input
"hello world" | awk '{print $2, $1}'

# Redirect file via stdin
open names.txt | awk '{print NR": "$0}'

# Multiple input files
awk '{print FILENAME": "$0}' names.txt dups.txt

# Skip empty lines
awk 'NF > 0' file.txt

# Multi-character record separator
"a##b##c\n" | awk 'BEGIN {RS = "##"} {print $0}'
```

## Advanced

```nu
# Case-insensitive matching
awk 'BEGIN {IGNORECASE = 1} /alice/' names.txt

# CSV-aware parsing (-k flag, GNU extension)
awk -k '{print $1, $2}' scores.csv

# Write to stderr
awk '{print "error" > "/dev/stderr"; print $0}' names.txt

# Execute shell command (returns exit status)
awk 'BEGIN {print system("echo hello")}'

# Multiple -e blocks (combined)
awk -e '{print $1}' -e '{print $2}' names.txt
```

## Common Recipes

```nu
# Extract column N from whitespace-separated file
awk '{print $3}' names.txt

# Extract column N from CSV
awk -F, '{print $2}' file.csv

# Filter rows by column value (score column is $2)
# Note: header row passes string comparison; use NR > 1 to skip it
awk -F, 'NR > 1 && $2 >= 90' scores.csv

# Count lines
awk 'END {print NR}' file.txt

# Sum column and print single number
awk '{sum += $2} END {print sum}' file.txt

# Print lines between START and END markers
awk '/START/,/END/' multiline.txt

# Remove duplicate lines while preserving order
awk '!seen[$0]++' dups.txt

# CSV to TSV conversion
awk -F, 'BEGIN {OFS = "\t"} {$1 = $1; print}' file.csv

# Extract unique values from a column
awk '{print $1}' dups.txt | awk '!seen[$0]++'

# Format numbers with thousands separator
awk '{printf "%\047d\n", $1}' big.txt
```

## Notes

- Default field separator is whitespace (spaces and tabs); use `-F,` for CSV, `-F '\t'` for TSV.
- `$0` is the entire line; `$1` through `$NF` are individual fields.
- `{print}` with no arguments prints `$0` (the whole line).
- `-v` variables are set before `BEGIN` executes. To pass a nu value, build an interpolated string: `awk -v $"t=($threshold)" ...` -- do not write a nu variable directly as `$name` inside the program; that `$` is awk's own field-reference syntax (`$i` reads field number `i`), not nu interpolation.
- For complex multi-line programs, prefer a script file: `awk -f script.awk file.txt`.
- On MSYS2, prefer forward slashes in paths to avoid backslash escaping headaches (see Quirks section above).
