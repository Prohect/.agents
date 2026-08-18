# edit_file: regex-pattern-failed-to-compile

## Symptom

```
The edit_file tool cannot run because 1 regex pattern failed to compile. Please fix the invalid patterns in your tool_permissions settings.
```

`edit_file` is blocked entirely — every call fails regardless of target file.

## Root Cause

`tool_permissions` rules (e.g. Zed global `settings.json` ->
`agent.tool_permissions.tools.edit_file.always_allow[].pattern`) are
**regexes, not globs**. A glob-style pattern like `**/.zed/settings.json`
is an invalid regex (`**` = repetition operator with nothing to repeat, or
nested repetition). One non-compiling pattern disables the whole tool.

## Fix

Rewrite the glob as a regex in the settings file, e.g.:

```json
{ "pattern": "/\.zed/settings\.json$" }
```

Notes:

- Patterns match against absolute paths with forward slashes (e.g. `F:/workspace/proj/.zed/settings.json`).
- `edit_file` may be hard-blocked, so apply the fix via `terminal` sed.
- Backup of the fixed file: `~/AppData/Roaming/Zed/settings.json.bak2` (2026-08-18).

## Suspicion (not the cause, but likely bugs)

Patterns written as `\\.agents` decode to regex `\` + any-char + `agents`,
i.e. they match a literal backslash, not a literal dot. They compile but
probably never match forward-slash paths. Intended form: `\.agents`.
