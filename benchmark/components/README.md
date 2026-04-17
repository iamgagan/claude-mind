# Component-Level Evals

End-to-end benchmarks (see `benchmark/README.md`) tell us whether the whole
plugin makes sessions faster or diffs smaller. They can't tell us *why*. When
the v0.1.2 numbers show `02-bug-fix-surgical` slowed down by 27%, the
end-to-end harness can't distinguish between:

- signal-detector fired on a no-signal prompt and wasted tokens
- brain-first retrieved the wrong page and biased the agent
- synthesis produced a low-density journal entry that didn't help next turn
- none of the above — it was model variance

Component evals isolate each moving part so we can regress or improve them
independently of the whole system.

## Three eval suites

### a) signal-detector — precision / recall / F1

**What it measures.** Given a user prompt, does `hooks/prompts/signal-detector.md`
correctly decide (1) whether any signal exists, and (2) which category it
belongs to.

**Dataset.** `signal-detector/fixtures.jsonl` — JSONL where each line is:

```json
{"prompt": "…", "expected_signal": true, "expected_category": "decision"}
```

Categories mirror signal-detector/SKILL.md: `preference`, `decision`, `fact`,
`rabbit-hole`, `none`. (Internally the prompt emits finer types — person,
company, concept, constraint, error — which we coarsen for eval purposes.)

**Metrics.**
- **Precision** — of prompts flagged as signal, how many truly were
- **Recall** — of truly-signal prompts, how many we flagged
- **F1** — harmonic mean; the one number to track over releases
- (Stretch) **category accuracy** on the signal-true subset

**Runner.** `signal-detector/eval.sh` — reads fixtures, calls `claude -p`
per line using the production signal-detector prompt, diffs expected vs
actual, prints the confusion matrix + P/R/F1.

### b) brain-first — retrieval hit-rate

**What it measures.** Given a fixture brain (a handful of pages with known
topics) plus a query, does the brain-first five-step protocol (or gbrain
when installed) surface the right page in its top-k.

**Metrics.**
- **Precision@1** — correct page is the top result
- **Precision@3** — correct page is in top 3

**Status.** TODO. Requires a fixture brain that reflects real agent usage
patterns (concept pages, entity pages, timeline entries, error log). See
`brain-first/README.md` for the intended structure.

### c) synthesis — quality rubric (LLM-as-judge)

**What it measures.** Given a session transcript, does `hooks/prompts/synthesis.md`
produce a journal entry worth keeping.

**Method.** LLM-as-judge with Haiku. Three axes, 1–5 scale:
1. **Completeness** — does the synthesis capture the decisions, errors, and
   named entities that appeared in the transcript?
2. **Signal density** — ratio of useful lines to filler; penalize restating
   obvious tool calls.
3. **No fabrication** — every claim in the synthesis traces back to the
   transcript.

A reference synthesis (human-written) anchors each golden transcript; the
judge scores both the model output and the reference, and we report the
delta.

**Status.** TODO, post-v0.2. We need golden transcripts captured from real
sessions (not benchmark tasks), and we don't have enough of those yet.

## How to run

```bash
# signal-detector (the only suite wired up today)
./benchmark/components/signal-detector/eval.sh

# brain-first (TODO — see brain-first/README.md)
./benchmark/components/brain-first/eval.sh

# synthesis (TODO — see synthesis/README.md)
./benchmark/components/synthesis/eval.sh
```

## Cost estimate

Rough per-run cost so you know what you're signing up for:

| Suite | Calls | Model | Est. tokens | Est. cost |
|---|---|---|---|---|
| signal-detector (10-row fixtures) | 10 | haiku-4-5 | ~5k in / ~1k out | < $0.01 |
| signal-detector (50-row v1) | 50 | haiku-4-5 | ~25k in / ~5k out | ~$0.03 |
| brain-first (planned, 30 queries) | 30 | embedding + haiku | ~15k | ~$0.02 |
| synthesis (planned, 10 transcripts × judge) | 20 | haiku-4-5 | ~40k in / ~10k out | ~$0.06 |

Full component-eval run: **well under $0.20** once all three suites exist.
Cheap enough to run on every PR.
