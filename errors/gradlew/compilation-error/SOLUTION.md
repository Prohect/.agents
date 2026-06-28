# gradlew → compilation-error

## Error

```
error: package <name> does not exist
error: cannot find symbol
```

The Gradle build failed due to compilation errors in the Java/Kotlin source.

## Root Cause

- Missing dependency not declared in `build.gradle`.
- Typo in import statement.
- Referenced class or method signature changed.
- Source file has syntax errors.

## Solution

1. **Read the error output carefully**: Identify the exact class/package that is missing.
2. **Check if the import is used**: If unused, remove it. If needed, proceed.
3. **Search for the dependency**: Use Maven Central, Google, or the project's own source.
4. **Add the dependency**: Edit `build.gradle` and add the correct `implementation` or `compileOnly` line.
5. **Rebuild**: Run `./gradlew build` again.
6. **For signature changes**: Read the target class with `read_file` to verify current method signatures.

## Prevention

- Run `./gradlew dependencies` to audit dependency tree before adding new imports.
- Use IDE auto-complete when available to avoid typos.
- Keep dependencies up to date.

## Attempts Log

_Add specific attempts here when documenting a new occurrence._

---

_Last updated: 2026-06-28_
