## Rules & workflow for skill creation (generic)

### 0. Audit the tool first
```bash
<tool> --help       # capture full option list
<tool> --version    # confirm it's running
```
Never write a skill without understanding the tool's actual CLI surface.

### 1. Build a controlled demo directory
Create a small, representative file tree covering every edge case the examples will touch (multiple types, nested dirs, hidden dirs, spaces in names, varied sizes, camelCase) under 
```bash
"$HOME/.agents/demo/<skill>"
```
This makes results **deterministic and reproducible**.

### 2. Test every example before writing it
No guessed syntax. Run each command against the demo directory, capture the actual output, and use that as the documented expected output. If something behaves unexpectedly, investigate and document it — don't paper over it.

### 3. Use portable paths
`$HOME` expands in double quotes and is portable. Never hardcode a username or machine-specific path.

### 4. Watch shell vs tool syntax conflicts
- `!` → history expansion in bash → wrap in single quotes
- `*` → globbing → single-quote
- `\` → escape char → prefer forward slashes; double-escape if unavoidable
- possible solution: **single-quote anything with `!` or `*`**

### 5. Prefer literal code blocks over tables for syntax references
Markdown tables require escaping `|` inside code spans (`\|`), which obscures the actual syntax. A plain code block shows the syntax exactly as the user would type it.

### 6. Verify independently — spawn a sub-agent
After writing the skill, spawn a sub-agent to load the skill fresh and run **every single code block** against the demo directory. Fresh eyes catch errors you've become blind to. Report pass/fail for each example and suggest fixes.

### 7. Fix → re-verify → iterate
The sub-agent will find bugs. Fix them, then have the sub-agent re-verify just the failing examples. Repeat until all pass.
The last step of this loop must be a pass report for all examples.

### 8. `edit_file` struggles with heavy backslash escaping
When a replacement contains many `\` characters (regex patterns, Windows paths), `edit_file`'s JSON encoding can fail. Fall back to `write_file` for the whole file, or use `terminal` + `sed` with a script file.

### 9. Document discovered quirks prominently
If testing reveals tool behavior that contradicts the documented syntax (e.g., a feature that doesn't work as advertised, or a syntax interaction that breaks), add a clearly marked **⚠️ Quirk** callout with broken vs. working examples.

### 10. Leave no trace
Remove temp files (`*.sed`, backup copies) when done. The demo directory should contain only the controlled test fixtures.
