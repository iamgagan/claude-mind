---
name: think-first
description: Required <thinking> block before any Edit, Write, or non-trivial Bash; states the critical path and side-effect surface before acting
when-to-use: Before any Edit/Write tool call; before any Bash command that mutates state (rm, mv, git commit, npm publish, etc.)
---

# Think First

## The contract

Before any code-modifying action, produce a `<thinking>` block that answers three questions:

1. **Critical path.** What is the minimum change required?
2. **Side effects.** What else does this affect? Who imports this? What tests cover it?
3. **Smallest version.** Is there a smaller change that meets the requirement?

The PreToolUse hook checks for a recent `<thinking>` block before allowing Edit/Write. It warns (does not block) if absent.

## Format

```
<thinking>
Critical path: <one sentence>
Affects: <files / call sites / tests>
Smallest version: <one sentence>
</thinking>
```

Three lines is enough. This is not a design doc — it's a forcing function.

## When NOT to think-first

- Pure read operations (Read, Grep, Glob)
- Safe shell queries (`ls`, `cat`, `git status`)
- Test runs that don't mutate state

## Why

The think-first gate catches:
- Edits that would touch the wrong file (you noticed mid-thought)
- Refactors disguised as bug fixes (you wrote "smallest version" and realized you were over-reaching)
- Side-effect blind spots (you listed importers and saw a test you'd break)

Most "I need to undo that" moments would have been caught by 30 seconds of typing here.
