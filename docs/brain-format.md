# Brain Page Format

Every Claude Mind brain page follows the **compiled-truth + timeline** pattern, borrowed from [`garrytan/gbrain`](https://github.com/garrytan/gbrain).

## Structure

```markdown
---
type: <type>
title: <title>
tags: [<tag>, <tag>]
---

<Compiled truth: your current best understanding. Rewritable.>

---

- YYYY-MM-DD: <evidence entry>
- YYYY-MM-DD: <evidence entry>
```

## Frontmatter fields

| Field | Required | Values |
|---|---|---|
| `type` | yes | `concept`, `person`, `company`, `decision`, `task`, `error`, `reference`, `identity` |
| `title` | yes | Human-readable title |
| `tags` | no | Array of lowercase strings |

## Compiled truth (above the second `---`)

- Your **current best model** of the subject.
- Rewritable. Replace freely as understanding improves.
- Length: a few sentences to a few paragraphs.
- Past versions live in git history if you need them.

## Timeline (below the second `---`)

- **Append-only.** Never edit; never reorder.
- One line per entry. Date prefix in `YYYY-MM-DD` format.
- Format: `- YYYY-MM-DD: <evidence>`
- Optional details sub-bullets: `  - <detail>`

## File placement

The **primary subject** determines the directory:

| Subject | Directory |
|---|---|
| Person | `brain/people/` |
| Company | `brain/companies/` |
| Concept | `brain/concepts/` |
| Project decision | `brain/decisions/` |
| Recurring error | `brain/errors/` |
| External reference | `brain/references/` |
| Agent or user identity | `brain/` (root) |

A meeting with Alice about the cache redesign goes in **two** pages: `decisions/cache-redesign.md` and `people/alice.md`. Each page links the other in its compiled truth.

## Slug rules

- Lowercase, kebab-case
- No dates (those go in the timeline)
- No version numbers (those go in the body)
- Singular when possible

## When compiled truth changes

1. Add the contradicting evidence to the timeline
2. Rewrite the compiled truth to match
3. Don't keep the old version "for reference" — it's in git

## Cross-references

Use markdown links between brain pages:

```markdown
Lead on the auth rewrite (see [decisions/auth-rewrite](../decisions/auth-rewrite.md)).
```
