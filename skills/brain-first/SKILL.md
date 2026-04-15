---
name: brain-first
description: Five-step protocol — before any external lookup, web search, or new file, consult the brain
when-to-use: Before web search, before reading external documentation, before creating a new file, before any "research" task
---

# Brain First

## The protocol

Before reaching for the web, the docs, or a fresh file, run these five steps:

1. **Recall by topic.** `grep -ri "<topic>" ./brain/` — does a brain page already cover this?
2. **Recall by entity.** Does any person/company/library mentioned have an existing page?
3. **Check the journal.** `tail -100 ./brain/_journal.md` — has this come up recently?
4. **Check errors.** `grep -i "<keyword>" ./brain/_errors.log 2>/dev/null` — has this failed before?
5. **Check signals.** `grep -i "<topic>" ./brain/_signals.md 2>/dev/null` — has it been flagged?

Only after all five return empty (or insufficient) do you reach externally.

## Why

External lookups are slow, lossy, and don't compound. Brain lookups are fast, precise, and every hit is one more piece of context the agent didn't have to reload. The brain gets smarter as you use it.

## When you DO go external

After a successful external lookup, write what you learned back to the brain (see `memory-protocol`). The next agent — including future-you — should not have to repeat the search.

## With gbrain installed

If `gbrain` MCP is configured, this skill delegates to `gbrain.search` for hybrid (vector + keyword) retrieval. Same five-step protocol applies; the recall mechanism is just stronger.

## Anti-patterns

- "Let me search the web first" → check the brain first
- "I'll look at the docs" → check the brain first; then docs; then write back
- "I don't think we've done this before" → don't think; check
