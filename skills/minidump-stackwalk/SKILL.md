---
name: minidump-stackwalk
description: Use `terminal` minidump-stackwalk (v0.26.1) to analyze Windows minidump (.mdmp) crash files — extract crash reason, backtrace, register state, loaded modules, and thread info in human-readable or JSON format. Use when you need to diagnose a crash dump, triage EXCEPTION_ACCESS_VIOLATION or other crash types, or extract structured crash data for further processing.
disable-model-invocation: true
---

# minidump-stackwalk — Minidump Crash Analyzer

rust-minidump v0.26.1. A CLI tool that parses Windows minidump (`.mdmp`) files and produces structured crash reports. Outputs human-readable summaries, JSON for programmatic consumption, or raw dumps for debugging the minidump format itself.

## Quick Reference

| Task                          | Command                                                         |
| ----------------------------- | --------------------------------------------------------------- |
| Quick crash summary           | `minidump-stackwalk --human --brief dump.mdmp`                  |
| Full human-readable report    | `minidump-stackwalk --human dump.mdmp`                          |
| JSON report (compact)         | `minidump-stackwalk --json dump.mdmp`                           |
| JSON report (pretty-printed)  | `minidump-stackwalk --json --pretty dump.mdmp`                  |
| Both human + JSON to file     | `minidump-stackwalk --cyborg json-out.json dump.mdmp`           |
| Raw dump (debug the minidump) | `minidump-stackwalk --dump --brief dump.mdmp`                   |
| With remote symbols           | `minidump-stackwalk --symbols-url https://... dump.mdmp`        |
| With local symbol files       | `minidump-stackwalk --symbols-path symbols.sym dump.mdmp`       |
| Write output to file          | `minidump-stackwalk --human --output-file report.txt dump.mdmp` |
| Verbose unwind tracing        | `minidump-stackwalk --verbose trace dump.mdmp`                  |

## Output Formats

Four mutually exclusive output modes control what is produced:

### `--human` (default)

Produces a human-readable crash report. This is the default if no format flag is specified.

```bash
minidump-stackwalk --human "$HOME/.agents/demo/minidump-stackwalk/cs2_2026_0703_211823_0_accessviolation.mdmp"
# → Operating system: Windows NT
#                   10.0.26200
#   CPU: amd64
#        family 6 model 183 stepping 1
#        20 CPUs
#
#   Crash reason:  EXCEPTION_ACCESS_VIOLATION_READ
#   Crash address: 0x000005d402eb4010
#   Crashing instruction: `mov rax, qword [rbx + 0x10]`
#   ...
#   Thread 38  (crashed) - tid: 14300
#    0  rendersystemdx11.dll + 0x5ce3b
#        rax = 0x000005d45629a030    rdx = ...
#       Found by: given as instruction pointer in context
#    1  rendersystemdx11.dll + 0x42452f
#       Found by: stack scanning
#   ...
#
#   Loaded modules:
#   0x00007ff7e99a0000 - 0x00007ff7e9dd2000  cs2.exe  ???  (main)
#   ...
```

The human report has no specified schema; its format may change between versions. It is intended for quick inspection or debugging rust-minidump itself.

### `--json`

Produces a machine-readable JSON report. The JSON schema is documented at [rust-minidump json-schema.md](https://github.com/rust-minidump/rust-minidump/blob/master/minidump-processor/json-schema.md).

```bash
minidump-stackwalk --json "$HOME/.agents/demo/minidump-stackwalk/cs2_2026_0703_211823_0_accessviolation.mdmp"
# → {"crash_info":{"address":"0x000005d402eb4010",...,"type":"EXCEPTION_ACCESS_VIOLATION_READ"},"crashing_thread":{"frame_count":38,"frames":[{"file":null,"frame":0,...,"module":"rendersystemdx11.dll","module_offset":"0x000000000005ce3b","trust":"context"},...]},"modules":[...],"status":"OK","system_info":{...},"thread_count":280,"threads":[...]}
```

The root object contains:

- `crash_info` — crash type, address, instruction, memory accesses
- `crashing_thread` — frame array with register state, trust level, module offsets
- `modules` — all loaded modules with base/end addresses, debug IDs, versions
- `threads` — all threads (frame arrays, thread IDs, names if available)
- `system_info` — OS, CPU, CPU count
- `status` — `"OK"` or error information

#### `--pretty`

Pretty-prints the JSON output:

```bash
minidump-stackwalk --json --pretty "$HOME/.agents/demo/minidump-stackwalk/cs2_2026_0703_211823_0_accessviolation.mdmp"
# → {
#     "crash_info": {
#       "address": "0x000005d402eb4010",
#       "crashing_thread": 38,
#       "instruction": "mov rax, qword [rbx + 0x10]",
#       "type": "EXCEPTION_ACCESS_VIOLATION_READ"
#     },
#     ...
#   }
```

### `--cyborg <PATH>`

Combines `--human` and `--json`: writes the JSON report to `<PATH>` and prints the human report to stdout (or `--output-file`). Useful when you want both formats from a single pass.

```bash
minidump-stackwalk --cyborg /tmp/crash.json "$HOME/.agents/demo/minidump-stackwalk/cs2_2026_0703_211823_0_accessviolation.mdmp"
# → [human output on stdout]
#   /tmp/crash.json contains the JSON report
```

### `--dump`

Produces a "raw" dump of the minidump's internal structure — streams, directories, headers. This is primarily for debugging minidump-stackwalk itself or a misbehaving minidump generator.

```bash
minidump-stackwalk --dump --brief "$HOME/.agents/demo/minidump-stackwalk/cs2_2026_0703_211823_0_accessviolation.mdmp"
# → MDRawHeader
#     signature            = 0x504d444d
#     version              = 0x6c02a793
#     stream_count         = 11
#     stream_directory_rva = 0x20
#   mDirectory[0]
#   MDRawDirectory
#     stream_type        = 0x3 (ThreadListStream)
#   ...
```

## Core Analysis: Interpreting the Output

### Crash Info Block

Every report starts with a crash info block:

```
Crash reason:  EXCEPTION_ACCESS_VIOLATION_READ
Crash address: 0x000005d402eb4010
Crashing instruction: `mov rax, qword [rbx + 0x10]`
Memory accessed by instruction:
  0. Address: 0x000005d402eb4010
     Size: 8
     Access type: Read
```

Common crash reasons:

- `EXCEPTION_ACCESS_VIOLATION_READ` / `EXCEPTION_ACCESS_VIOLATION_WRITE` — null/invalid pointer dereference
- `EXCEPTION_ILLEGAL_INSTRUCTION` — corrupted code, jumped to data, or unsupported instruction
- `EXCEPTION_STACK_OVERFLOW` — stack exhaustion
- `EXCEPTION_BREAKPOINT` — intentional debug break

The crash address is the address that was being accessed (for access violations) or the instruction pointer (for illegal instructions).

### Backtrace Frames

Each frame in the crashing thread includes:

```
 0  rendersystemdx11.dll + 0x5ce3b
     rax = 0x000005d45629a030    rdx = 0x0000000000000008
     rip = 0x00007ff951c9ce3b
    Found by: given as instruction pointer in context
```

- **Module** + **offset** — the DLL and relative offset within it (e.g., `rendersystemdx11.dll + 0x5ce3b`)
- **Registers** — values at the time of the crash (frame 0) or as recovered by the unwinder (subsequent frames)
- **Found by** (trust level) — how the unwinder discovered this frame:
  - `given as instruction pointer in context` — directly from the CPU context (highest trust)
  - `call frame info` — from unwind metadata (`.pdata` / `.eh_frame`)
  - `stack scanning` — heuristically found on the stack (lowest trust, may be false positives)
  - `frame pointer` — via frame-pointer-based unwinding (EBP/RBP chain)

Without symbols, only module + offset is shown. With symbols, you'd see function names, file paths, and line numbers.

### Module Info

The modules section lists every DLL/EXE loaded at crash time:

```json
{
  "base_addr": "0x00007ff7e99a0000",
  "code_id": "6a1e080f432000",
  "debug_file": "cs2.pdb",
  "debug_id": "88CDC0C6E84E4623BC67CFC120F9C5273",
  "end_addr": "0x00007ff7e9dd2000",
  "filename": "cs2.exe",
  "version": null
}
```

- `base_addr` / `end_addr` — load range in virtual memory
- `code_id` — timestamp + size-of-image hex string (used for symbol server lookups)
- `debug_file` / `debug_id` — PDB filename and identifier
- `version` — file version string (when available)

## Filtering & Detail Level

### `--brief`

Trims output for quick inspection:

- In `--human` mode: omits non-crashing threads and non-crashing-thread backtraces. Shows only the crash summary + crashing thread backtrace.
- In `--dump` mode: omits memory hexdumps.

```bash
# Quick triage — just the crash and crashing thread
minidump-stackwalk --human --brief "$HOME/.agents/demo/minidump-stackwalk/cs2_2026_0703_211823_0_accessviolation.mdmp"
# → Crash reason: EXCEPTION_ACCESS_VIOLATION_READ
#   Thread 38 (crashed) - tid: 14300
#    0  rendersystemdx11.dll + 0x5ce3b
#    1  rendersystemdx11.dll + 0x42452f
#   ... (only the crashing thread's 38 frames)
```

### `--features <LEVEL>`

Controls the depth of analysis performed:

| Value          | Meaning                                                   |
| -------------- | --------------------------------------------------------- |
| `stable-basic` | Default. Solid, reliable analysis suitable for production |
| `stable-all`   | Extra detailed analysis (currently same as stable-basic)  |
| `unstable-all` | Experimental features including `--recover-function-args` |

```bash
minidump-stackwalk --features unstable-all --human "$HOME/.agents/demo/minidump-stackwalk/cs2_2026_0703_211823_0_accessviolation.mdmp"
# → enables experimental features, currently just --recover-function-args
```

### `--recover-function-args`

**Unstable.** Heuristically recovers function arguments from register/stack state. Only affects `--human` output.

```bash
minidump-stackwalk --recover-function-args --human "$HOME/.agents/demo/minidump-stackwalk/cs2_2026_0703_211823_0_accessviolation.mdmp"
```

### `--verbose <LEVEL>`

Controls log verbosity written to stderr (or `--log-file`). The unwinder is heavily instrumented with `trace`-level logging; all unwinder messages contain `unwind` (e.g., `unwind_thread{...}` or `unwind_frame{...}`).

| Level   | Use case                                |
| ------- | --------------------------------------- |
| `off`   | Silence all logs                        |
| `error` | Default. Only errors                    |
| `warn`  | Warnings and errors                     |
| `info`  | High-level progress                     |
| `debug` | Detailed unwinding decisions            |
| `trace` | Per-frame unwinder state (very verbose) |

```bash
minidump-stackwalk --verbose trace --human --brief "$HOME/.agents/demo/minidump-stackwalk/cs2_2026_0703_211823_0_accessviolation.mdmp" 2>&1 | head -n 20
# → [unwind trace logging on stderr, showing each unwinding step]
```

## Symbol Resolution

Without symbols, minidump-stackwalk shows only module + offset. To get function names, file paths, and line numbers, provide symbol files.

### `--symbols-url <URL>`

Specify a symbol server conforming to the [Tecken protocol](https://tecken.readthedocs.io/en/latest/). Multiple `--symbols-url` values are tried in order.

```bash
# Microsoft's public symbol server
minidump-stackwalk --human \
  --symbols-url https://msdl.microsoft.com/download/symbols/ \
  dump.mdmp

# Mozilla's symbol server (Firefox crashes)
minidump-stackwalk --human \
  --symbols-url https://symbols.mozilla.org/ \
  dump.mdmp
```

### `--symbols-cache <DIR>`

Downloaded symbol files are cached here to avoid re-downloading. Defaults to a `rust-minidump-cache` subdirectory of the system temp dir.

```bash
minidump-stackwalk --human \
  --symbols-url https://msdl.microsoft.com/download/symbols/ \
  --symbols-cache /tmp/symcache \
  dump.mdmp
```

### `--symbols-tmp <DIR>`

Temp directory for in-flight downloads before they're atomically moved to the cache. Must be on the same filesystem as `--symbols-cache`. Defaults to the system temp dir.

### `--symbols-download-timeout-secs <SECS>`

Maximum time (in seconds) a single symbol file download may take. Default: `1000`.

### `--symbols-path <FILE>`

Provide a local symbol file (Breakpad `.sym` format). Multiple `--symbols-path` values are merged.

```bash
minidump-stackwalk --human --symbols-path mymodule.sym dump.mdmp
```

The deprecated positional form (`minidump-stackwalk dump.mdmp symbols.sym`) still works but `--symbols-path` is preferred.

### `--use-local-debuginfo`

If the minidump contains references to local PDB/DWARF files (e.g., on the machine that generated the dump), attempt to load them directly.

## Output Control

### `--output-file <PATH>`

Write the report to a file instead of stdout:

```bash
minidump-stackwalk --human --output-file crash_report.txt dump.mdmp
```

### `--log-file <PATH>`

Write logs (stderr) to a file:

```bash
minidump-stackwalk --verbose info --log-file unwind.log dump.mdmp
```

### `--no-color`

Strip ANSI color codes from terminal output. Output written to files via `--output-file`, `--log-file`, or `--cyborg` is always `--no-color`.

### `--no-interactive`

Disable interactive progress feedback (spinners, progress bars). The tool auto-detects non-TTY output; this flag is a manual override.

## Common Recipes

### Quick Triage

```bash
# What crashed, where, and what's the crashing thread's backtrace?
minidump-stackwalk --human --brief "$HOME/.agents/demo/minidump-stackwalk/cs2_2026_0703_211823_0_accessviolation.mdmp"
# → Crash reason:  EXCEPTION_ACCESS_VIOLATION_READ
#   Crash address: 0x000005d402eb4010
#   Thread 38 (crashed)
#    0  rendersystemdx11.dll + 0x5ce3b
#   ...
```

### JSON for Programmatic Processing

```bash
# Extract crash reason and crashing module
minidump-stackwalk --json dump.mdmp | jq '{reason: .crash_info.type, module: .crashing_thread.frames[0].module, offset: .crashing_thread.frames[0].module_offset}'
```

### Extract All Loaded Modules

```bash
minidump-stackwalk --json dump.mdmp | jq '.modules[] | {name: .filename, base: .base_addr, debug_id: .debug_id, version: .version}'
```

### Find Threads Touching a Specific Module

```bash
minidump-stackwalk --json dump.mdmp | jq '[.threads[] | select(.frames[0].module == "ntdll.dll") | {thread_index, thread_id, thread_name}]'
```

### Compare Two Crashes (Same Crash Type?)

```bash
diff <(minidump-stackwalk --human --brief crash1.mdmp) <(minidump-stackwalk --human --brief crash2.mdmp)
```

### Debug Why an Unwind Went Wrong

```bash
minidump-stackwalk --verbose trace --human --brief dump.mdmp 2>&1 | grep 'unwind'
```

### Batch Process Multiple Dumps to JSON

```bash
for dump in *.mdmp; do
  minidump-stackwalk --json --output-file "${dump%.mdmp}.json" "$dump"
done
```

## Quirks & Platform Notes

### ⚠️ Large Output — Use `--json` for Programmatic Consumers

The `--human` format has no specification and may change. For scripting or automated pipelines, always use `--json`. The JSON schema is documented and stable within a major version.

### ⚠️ `--brief` Changes Behavior Per Format

`--brief` means different things in different formats:

- `--human --brief`: shows only crash info + crashing thread backtrace (omits other threads)
- `--dump --brief`: omits memory hexdumps
- `--json --brief`: not applicable (no effect on JSON output)

### Stack Scanning Frames

Frames found by `stack scanning` are heuristic — they inspect the stack for values that look like return addresses. They can be false positives, especially deep in the trace. Higher trust should be given to `call frame info` and `context` frames.

### Missing Symbols

Without `--symbols-url`, `--symbols-path`, or `--use-local-debuginfo`, all frames will show `missing_symbols: true` and only module + offset. The PDB identifiers (`debug_file` + `debug_id` in the modules list) tell you exactly which symbol files to obtain.

### Module Offsets in JSON vs Human

In `--json`, offsets are hex strings with leading zeros (e.g., `"0x000000000005ce3b"`). In `--human`, they're compact hex (e.g., `0x5ce3b`). Both represent the same offset — the zero-padding in JSON is for fixed-width alignment.

### Long-Running Analysis

Large minidumps (many threads, large memory regions) can take seconds to process. The `--no-interactive` flag disables progress bars. The symbol download timeout (`--symbols-download-timeout-secs`) defaults to 1000 seconds — large PDBs from Microsoft's server can be slow on first download.

### `--cyborg` Requires a Path

Unlike other format flags, `--cyborg` must be followed by a file path for the JSON output. It cannot write JSON to stdout because stdout is already used for the human output.
