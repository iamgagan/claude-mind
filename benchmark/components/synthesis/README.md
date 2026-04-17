# Synthesis Quality Eval

**Status:** TODO. Scaffold only — suite is not wired up. Post-v0.2.

## What this will measure

Given a session transcript, does `hooks/prompts/synthesis.md` produce a
journal entry worth keeping? Scored via LLM-as-judge (Haiku) on three axes,
1–5 each:

1. **Completeness** — are the decisions, errors, and named entities from
   the transcript represented in the synthesis?
2. **Signal density** — ratio of useful lines to filler. Restating obvious
   tool calls ("read foo.ts") is penalized; capturing original thinking is
   rewarded.
3. **No fabrication** — every claim in the synthesis must trace back to
   the transcript. Hallucinated decisions are an instant 1.

A human-written **reference synthesis** anchors each golden transcript. The
judge scores the model output *and* the reference; we report the delta so
the rubric's bias cancels out.

## Why it's blocked

The eval needs golden transcripts — real multi-turn sessions with meaningful
deltas. Benchmark-task transcripts (fizzbuzz, surgical bug fix) are too thin
to exercise the synthesis prompt. Blocking on (1) v0.2 multi-turn sessions,
or (2) opt-in scrubbed contributions from real operator use.

## Intended layout

```
synthesis/
  fixtures/
    transcripts/001-auth-refactor.jsonl     # real session transcripts
    references/001-auth-refactor.md         # human-written gold synthesis
  rubric.md                                 # judge prompt
  eval.sh                                   # run prompt, invoke judge, report per-axis + deltas
```

## Open questions

- One judge call per axis or all-three at once? (All-three is cheaper but may conflate.)
- Show the judge the reference while scoring? (Biases toward reference — prefer blind scoring then compare.)
