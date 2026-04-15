---
name: recall
description: Brain-first lookup before starting a task; surfaces relevant pages
arguments: [query]
---

# /recall [query]

Query the brain before reaching externally.

## Behavior

If `query` is provided:
1. If `gbrain` MCP is available and `gbrain_bridge_enabled: true` → call `gbrain.search` with the query.
2. Else → grep `./brain/` for the query (case-insensitive, with fuzzy matching on the title field).
3. Return up to 5 matches with: title, page type, last-updated date, and the compiled-truth excerpt (first 200 chars).

If `query` is omitted:
1. Print the top-5 most-recently-updated pages.
2. Print pending items from `_signals.md` and `_errors.log` (last 10 of each).

## Output format

```
3 hits for "auth":

1. brain/decisions/auth-rewrite.md (decision, updated 2026-04-15)
   Decided to use the new token store; old one had a thread-safety bug.

2. brain/concepts/jwt-signing.md (concept, updated 2026-03-22)
   We sign with HS256; rotation handled by the secret-mgr cron.

3. brain/people/alice.md (person, updated 2026-02-10)
   Lead on the auth rewrite. Prefers async over Slack.
```

## When the brain is empty

Print: `no brain in this repo — run /sc-init to enable` and exit 0.
