---
name: errors
description: Reference index of documented tool call errors and their solutions. Consult errors Skill when any tool call (builtin, CLI, MCP, Skill-introduced CLI) fails.
---

# Tool Error Reference

This Skill is the **entrance index** to the error documentation system.

## Reference List

### Builtin Tools

| Tool | Error Type | Link |
|------|-----------|------|
| `read_file` | `ENOENT` (file not found) | [~/.agents/errors/read_file/ENOENT/](~/.agents/errors/read_file/ENOENT/) |
| `write_file` | — | *(none yet)* |
| `edit_file` | — | *(none yet)* |
| `terminal` | — | *(none yet)* |
| `grep` | — | *(none yet)* |
| `find_path` | — | *(none yet)* |
| `search_code` | — | *(none yet)* |
| `list_directory` | — | *(none yet)* |

### MCP Tools

| Tool | Error Type | Link |
|------|-----------|------|
| `search_code` (GitHub) | `rate-limit-exceeded` | [~/.agents/errors/search_code/rate-limit-exceeded/](~/.agents/errors/search_code/rate-limit-exceeded/) |

### CLI Tools

| Tool | Error Type | Link |
|------|-----------|------|
| `gradlew` | `compilation-error` | [~/.agents/errors/gradlew/compilation-error/](~/.agents/errors/gradlew/compilation-error/) |

### Skill-Introduced CLI Tools

| Skill | Tool | Error Type | Link |
|-------|------|-----------|------|
| — | — | — | *(none yet)* |

---

## **If no entry matches**

If no entry matches, **STOP and CONSULT the user how to solve that or RESPOND to the sub-agent spawner** . 
When the error is solved, **If the solution could be reused encountering the same error again**, document the solution by creating the following:

- Directory: `~/.agents/errors/<tool-name>/<error-type>/`
- Files in that directory:
  - `~/.agents/errors/<tool-name>/<error-type>/SOLUTION.md`
  - `~/.agents/errors/<tool-name>/<error-type>/counter_<n>`

Then add a row to the reference table above linking to the new entry.

## Naming Rules for Error Directories

- `<tool-name>`: Use the **exact name** from the tool call JSON (e.g., `read_file`, `search_code`, `terminal`). For CLI tools introduced by a Skill, use the Skill name. For other CLI tools, use the binary name (e.g., `find`, `gradlew`).
- `<error-type>`: The unique identifier for the error. Determine it using this strict priority order:
  1. **Canonical Code:** If the error contains a standard code string (e.g., `ENOENT`, `EACCES`, `429`, `rate-limit-exceeded`), use it exactly as printed.
  3. **Normalized Message:** If only a raw string message exists, strip all dynamic variables (paths, lines, hex addresses, numbers). Take the first few (suggested 3-5, longer enough to differ errors with similar static words yet having different root cause and solution) words of the static error message, convert to lowercase, and join with hyphens.
