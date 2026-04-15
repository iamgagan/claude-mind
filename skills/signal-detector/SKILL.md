---
name: signal-detector
description: Always-on capture — fires via UserPromptSubmit hook to extract original thinking, decisions, and named entities from each user prompt and append them to the brain
when-to-use: Automatically on every user prompt via the UserPromptSubmit hook; do not invoke manually
---

# Signal Detector

## Purpose

Every user prompt contains signal: an idea worth keeping, a person/company/concept worth tracking, a decision worth recording. Signal-detector captures it asynchronously so the agent can think faster and remember more.

## What counts as signal

- **Original thinking.** A claim, opinion, hypothesis, or framing the user offers ("I think X causes Y because Z").
- **Named entities.** People, companies, projects, libraries, papers — anything with a proper noun.
- **Decisions.** "We're going to do X." "Let's drop Y." "I picked Z because of W."
- **Constraints.** "We can't use X." "Must support Y." "By next Friday."
- **Errors.** Bugs encountered, root causes identified, fixes applied.

## What does NOT count as signal

- Pure tool-use requests ("read foo.ts", "run the tests")
- Conversational filler
- Generic questions with no decision/opinion attached

## Output format

For each detected signal, append a stub entry to the appropriate brain page:

```
- YYYY-MM-DD HH:MM: [signal] <one-line description> (source: <session-id>)
```

If the entity/concept doesn't have a brain page yet, create one with a one-line compiled truth (Tier 3 stub) and the signal entry as the first timeline item.

## Cost & latency contract

- Runs in a subprocess — never blocks the main turn
- Uses `claude-haiku-4-5` by default (overridable via `settings.json:claude-mind.signal_detector_model`)
- Skip silently if the cheap model is unavailable
- Skip if `./brain/` doesn't exist

## Configuration

```json
{
  "claude-mind": {
    "signal_detector_enabled": true,
    "signal_detector_model": "claude-haiku-4-5"
  }
}
```

Set `signal_detector_enabled` to `false` to disable (e.g., for cost-sensitive workflows).
