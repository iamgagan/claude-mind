# RESOLVER.md — How Routing Works

`skills/RESOLVER.md` is the single entry point for skill discovery. The agent reads it before any non-trivial task.

## Why a single file

Skills are designed to be discovered by description, but a routing layer makes the priority explicit:

- **Always-on skills** must fire regardless of intent (`signal-detector`, `brain-first`)
- **Gated skills** must fire before specific tools (`think-first` before Edit)
- **Toolchain skills** must fire when their ecosystem is detected (`uv-python` for Python projects)
- **Ship gate** must fire before commit/PR (`taste`)

A flat skill index can't express priority; RESOLVER.md does.

## Format

The file is human-readable markdown with sections grouped by trigger:

```markdown
## Always-on (every turn)
- skill-name — short description

## Before any file modification
- skill-name — when

## Brain operations
- skill-name — when
```

The agent reads top-to-bottom; earlier sections take precedence.

## Adding a new skill

1. Add `skills/<new-skill>/SKILL.md` with valid frontmatter
2. Add a one-line entry under the appropriate section in RESOLVER.md
3. The skills test will fail if RESOLVER.md doesn't reference the new skill

## Borrowed from gbrain

This pattern is lifted directly from gbrain's `skills/RESOLVER.md`. Credit Garry Tan.
