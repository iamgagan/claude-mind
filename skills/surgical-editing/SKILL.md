---
name: surgical-editing
description: Patch don't rewrite — smallest possible diff, named-line edits, no incidental refactoring
when-to-use: Every Edit tool call; whenever modifying existing code
---

# Surgical Editing

## The rule

The diff should contain only what the task requires. Nothing else.

## What "surgical" means

- **Edit, don't rewrite.** Use the Edit tool with old_string/new_string. Don't Write the whole file.
- **Don't reformat lines you didn't change.** If the surrounding code uses tabs and you prefer spaces, keep tabs.
- **Don't rename incidentally.** If a variable is poorly named but works, leave it. Renaming = its own commit.
- **Don't add docstrings/comments to code you didn't change.** They aren't free; they pollute diffs.
- **Don't update unrelated imports.** Even if they're stylistically "wrong."

## When you're tempted to clean up

Ask: "is the cleanup what I was asked to do?"
- Yes → do it
- No → resist; if it really matters, mention it in the response and let the user decide

## Bug fixes don't need cleanup

A bug fix should be the smallest change that fixes the bug. Surrounding code that "could be cleaner" stays. The PR that cleans it up is a separate PR.

## Feature additions don't need refactors

If a feature could be simpler "if we just refactored this first," the right move is usually:
1. Build the feature in the existing structure (ugly but works)
2. Ship
3. Refactor in a separate PR if it still seems worth it later (often it doesn't)

## Anti-patterns

- "While I'm in here, let me also..." → no
- "Let me modernize this real quick" → no
- "This would be cleaner with X pattern" → maybe; not in this commit
- Reformatting a whole file because you changed three lines in it → no
- Adding type annotations to functions you didn't modify → no
