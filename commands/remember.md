---
name: remember
description: Append a compiled-truth note to the appropriate brain page; create the page if needed
arguments: <note>
---

# /remember <note>

Explicit mid-session capture. Use when you want to lock something into memory before the session ends.

## Behavior

1. Parse the note — extract the **subject** (entity, concept, decision).
2. Run `brain-first` to find an existing page for the subject.
3. If a page exists:
   - Append a timeline entry with date + note.
   - If the note materially updates the compiled truth, rewrite it.
4. If no page exists:
   - Determine the page type and directory (per `memory-protocol`).
   - Create the page using `templates/brain-page.md`.
   - Compiled truth = one-sentence summary of the note.
   - Timeline = one entry with the note verbatim.

## Output

Print the path of the page and a one-line summary of what changed:

```
brain/decisions/auth-rewrite.md
+ timeline: 2026-04-15 — Decided to use the new token store; old one had a thread-safety bug
```

## Anti-patterns

- Vague notes ("look into this later") → reject; ask for a concrete subject
- Notes that are really tasks → suggest using a task tracker, not the brain
- Notes that duplicate an existing entry → flag and merge, don't append
