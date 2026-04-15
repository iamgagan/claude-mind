---
name: taste
description: Ship gate — invoked before any commit, PR, or release; one question, then act
when-to-use: Before `git commit`, `gh pr create`, `bun publish` / `npm publish`, version-tag pushes; invoked by /ship command
---

# Taste

## The one question

> *Is this the version you'd be proud to have your name on?*

If yes: ship. Don't gold-plate.
If no: name **the specific thing** that's wrong, fix **only that**, and re-ask.

## What this is NOT

- A code review checklist (those exist elsewhere)
- An invitation to refactor unrelated code
- A reason to add tests for things outside the change
- A "while we're here, let's also..." gate

## What this IS

A 30-second pause before publishing that catches:
- The variable name you knew was wrong but kept
- The error message that says "error" instead of what failed
- The TODO you left in
- The console.log you forgot
- The case the diff doesn't handle but obviously should
- The test that's actually testing the wrong thing

## The flow

1. `/ship` is invoked.
2. Read the diff (`git diff --staged` or `git diff main...HEAD`).
3. Ask the one question.
4. If yes:
   - Print the diff summary
   - Hand off to git/gh — never auto-commit
5. If no:
   - State the **specific** thing wrong (one sentence)
   - Fix that one thing
   - Re-read the diff
   - Re-ask

## Anti-patterns

- Punting decisions ("we can fix it later") — fix it now or note it explicitly in the PR description
- Cleaning up things outside the diff — that's a separate PR
- Adding "more tests" without a specific case — name the case or skip
- Asking the user "should I clean up X?" — decide; they trusted you with `/ship`

## The Tan rule

Ship the version you'd be **proud** of, not the version you'd merely **defend**. Big difference.
