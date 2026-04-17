# brain-first Retrieval Eval

**Status:** TODO. Scaffold only — suite is not wired up.

## What this will measure

For each (query, expected-page) pair, does the brain-first five-step protocol
(or `gbrain.search` when configured) surface the right brain page in its
top-k results. Reported as **Precision@1** and **Precision@3**.

P@1 matters more — the agent usually acts on the first hit. P@3 is a sanity
check that the right page is *reachable* even when not top-ranked.

## Why it's blocked

A fixture brain needs to *look like* a real agent-built brain to produce
meaningful signal. Hand-crafted five-page brains overfit the retrieval
logic; a real in-progress brain is messy but realistic.

Blocking on v0.2 of the main benchmark, which will generate multi-turn
session transcripts — the first source of "natural" brain content we can
curate into fixtures.

## Intended structure

```
brain-first/
  fixtures/
    brain/                      # copied to tmp before each eval run
      people/linus-torvalds.md
      companies/anthropic.md
      concepts/crdt.md
      concepts/opaque-tokens.md
      _journal.md
      _errors.log
      _signals.md
    queries.jsonl               # {"query": "...", "expected_page": "concepts/crdt.md"}
  eval.sh                       # run the five-step protocol per query, compute P@1 / P@3
```

## Open questions

- Test pure grep-based protocol, gbrain-backed protocol, or both? (Probably both, reported separately.)
- How to score "partially correct" — right entity page, wrong section? (Defer until real failure modes appear.)
