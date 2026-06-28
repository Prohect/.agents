# search_code → rate-limit-exceeded

## Error

```
API rate limit exceeded (403)
```

GitHub's Search API rejected the request due to rate limiting.

## Root Cause

- Too many unauthenticated requests to the GitHub Search API in a short time window.
- No GitHub token configured, hitting the lower unauthenticated rate limit.
- Repeated `search_code` calls in quick succession.

## Solution

1. **Wait and retry**: The rate limit resets after ~60 seconds for unauthenticated requests.
2. **Use local tools instead**: Prefer `grep` for searching within the local project — it has no rate limit and is faster.
3. **Configure a GitHub token**: Add a personal access token to increase the rate limit.
4. **Cache results**: Avoid repeated identical queries.

## Prevention

- Always try `grep` before `search_code` when searching within the current project.
- Reserve `search_code` for cross-repository searches only.
- Batch queries when possible.

## Attempts Log

_Add specific attempts here when documenting a new occurrence._

---

_Last updated: 2026-06-28_
