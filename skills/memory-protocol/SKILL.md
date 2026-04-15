---
name: memory-protocol
description: Compiled-truth + timeline brain-page format and placement protocol
when-to-use: When writing to ./brain/, when creating a new brain page, when responding to /remember
---

# Memory Protocol

## The page format

Every brain page has the same shape: **compiled truth above, timeline below.**

```markdown
---
type: concept | person | company | task | decision | error | reference
title: <subject>
tags: [...]
---

<Compiled truth: your current best understanding of this subject. Rewritable.>

---

- YYYY-MM-DD: <evidence entry>
- YYYY-MM-DD: <another entry>
```

Above the second `---`: **compiled truth.** Edit freely as understanding improves.
Below: **timeline.** Append-only. Never edit; only add.

## Where pages live

Decision protocol — the **primary subject** determines the directory, not the format:

- About a person → `./brain/people/<slug>.md`
- About a company → `./brain/companies/<slug>.md`
- About a concept → `./brain/concepts/<slug>.md`
- About a project decision → `./brain/decisions/<slug>.md`
- About a recurring error → `./brain/errors/<slug>.md`
- About an external reference → `./brain/references/<slug>.md`

A meeting with Alice about the cache redesign is not in `meetings/` — it's in `decisions/cache-redesign.md` (with Alice mentioned in the timeline) and `people/alice.md` (with the meeting in her timeline).

## Slug rules

- Lowercase, kebab-case
- No dates (dates go in the timeline)
- No version numbers (those go in the body)
- Singular when possible (`user-auth` not `user-auths`)

## When to create vs. update

- **Create** when no existing page covers the subject (verify via `brain-first` first)
- **Update** the compiled truth when new evidence changes the picture
- **Append** to timeline always; never edit historical entries

## Compiled-truth rewriting

Compiled truth is your *current best model*. When evidence contradicts it:

1. Add the contradicting evidence to the timeline
2. Rewrite the compiled truth to match the new model
3. Don't keep the old version "for reference" — it's in git history if you need it

## With gbrain

If `gbrain` is the storage backend, the file format is identical (gbrain reads markdown), but the agent should also call `gbrain sync` after writes so the retrieval index updates. The Stop hook will trigger this when the gbrain bridge is enabled in `settings.json`.
