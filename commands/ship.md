---
name: ship
description: Invoke the taste skill on the staged diff, then hand off to git/gh — never auto-commits
---

# /ship

The ship gate. Run before any commit, PR, or release.

## Behavior

1. Determine the diff:
   - If staged changes exist → `git diff --staged`
   - Else if on a branch with upstream → `git diff <upstream>...HEAD`
   - Else → `git diff HEAD` (working tree)
2. Invoke the `taste` skill with the diff as context.
3. The skill answers the one question.
4. If the answer is "yes":
   - Print a one-line summary of what's about to ship
   - Print the exact `git commit` (or `gh pr create`) command for the user to run
   - **Never auto-execute.** The user runs the final command.
5. If the answer is "no":
   - State the specific thing wrong
   - Offer to fix that one thing
   - On user OK → fix → re-run `/ship` recursively

## Why no auto-commit

`/ship` is a thinking gate, not an executor. The user retains the muscle memory of typing `git commit`. This also prevents the failure mode where the gate "passes" something the user wouldn't have shipped.

## Anti-patterns

- Combining `/ship` with `--no-verify` style bypasses → if you need to bypass, you don't need `/ship`
- Running `/ship` after the commit is already pushed → the gate is before, not after
- Treating `/ship` as a code review → see `taste` skill: it's not a checklist
