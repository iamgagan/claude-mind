# Long-Session Benchmark (scaffold)

> **Status:** design doc + scaffolded harness. No real runs yet.
> Metrics, fixtures, and replay machinery are **all TODO**.
> Listed on the `BENCHMARK.md` roadmap as the next-tier evaluation.

## Thesis

The one-shot benchmark in `benchmark/run.sh` runs each task in a *fresh repo
with an empty brain*. That is precisely the regime where claude-mind has the
**least** to offer — the hooks add overhead and the brain cannot contribute
recall because it is empty.

claude-mind's value proposition is **compounding**: every turn writes signals,
every `Stop` hook grows the journal, every `brain-first` consult replaces an
external lookup with a local one. The benefit is a function of session length
and brain density. A benchmark that never lets the brain grow cannot see it.

This suite simulates realistic **multi-turn** sessions (10–15 turns) in which
the brain is allowed to accumulate across turns, and measures whether the
plugin-on run pulls ahead of the plugin-off run as the session progresses.

## Protocol

Each scenario is a scripted persona narrative — a sequence of user prompts
an agent would plausibly receive from a human working on one task over one
sitting. Examples (see `scenarios/`):

- `onboarding.md` — new contributor learning a codebase over 15 turns
- `bug-hunt.md` *(TODO)* — tracking down a regression over ~10 turns
- `refactor.md` *(TODO)* — a refactor that spans ~12 turns

For each scenario we run two conditions:

- **baseline** — plugin disabled, empty `./brain/` (writes go nowhere useful)
- **plugin** — plugin enabled, `./brain/` persists across turns within a run

Within a condition we run all N turns as one conversation. Hooks fire normally.
Between conditions we `git reset --hard` the fixture repo and wipe the brain.

## Metrics

All TODO. Targets:

1. **Turn-by-turn duration curve.** Plot wall-clock duration per turn. If
   brain-first is working we expect the plugin curve to bend below baseline
   as turns accumulate.
2. **Brain size over time.** Pages created, bytes written, entries in
   `_journal.md` and `_signals.md`. Sanity check that the brain is growing.
3. **Repeated-question latency.** Ask the same factual question at turn 3
   and again at turn 13. Plugin should be faster at 13 if `brain-first`
   kicks in; baseline should be comparable (or re-learn from source).
4. **Error rate.** Wrong-file edits, re-learned facts, contradictions with
   earlier turns. Mostly heuristic; needs a grader.
5. **Total session token usage.** Input + output tokens across all turns.
   Plugin trades hook-invocation tokens now for brain-lookup tokens later;
   we want to know where the crossover is.

## Why this is hard

- **Determinism.** LLM outputs are noisy. A single run tells us nothing; we
  need n≥5 per (scenario, condition). Mitigation: fixed prompts verbatim,
  fixed model version, `--seed` if/when supported.
- **Conversation state.** `claude -p` is one-shot. Holding a conversation
  across 15 turns means either the Agent SDK or `claude --continue` with a
  stable session id. Both have footguns. See `run.sh` TODOs.
- **Environmental state.** The agent edits files, makes commits, runs tests.
  Between runs we must `git reset --hard` the fixture and restore the brain
  to a known state (empty, or a pre-seeded snapshot). The harness does this
  — but it is easy to get wrong and silently contaminate a run.
- **Brain snapshotting.** To study compounding we need the brain *at each
  turn*, not just at the end. Harness tars `./brain/` after every turn.
- **Grading.** "Error rate" and "repeated-question latency" need a rubric,
  not just a stopwatch. TODO: an LLM-as-judge pass over each turn's output.

## Scaffold status

| Piece | Status |
|---|---|
| Design (this doc) | drafted |
| `onboarding.md` scenario | 15 turns drafted |
| Other scenarios | TODO |
| `run.sh` harness | stub — loops turns, snapshots brain; conversation-state wiring is TODO |
| Per-turn token parsing | TODO |
| Metrics aggregator / report | TODO |
| Fixture repo (`fixture-repo/`) | TODO — scenarios reference it but it does not exist yet |
| LLM-as-judge grader | TODO |
| Determinism harness (seeding, pinning) | TODO |

## Layout

```
benchmark/long-session/
  README.md                 # this file
  run.sh                    # scaffold harness (executable, stubbed)
  scenarios/
    README.md               # scenario file format
    onboarding.md           # 15-turn persona scenario
  # fixture-repo/           # TODO: the codebase the scenario operates on
```

Results are written under `benchmark/results/long-session/<scenario>/`.

## How to think about this

If the v0.1.2 one-shot benchmark showed the plugin is **+27% slower** on a
surgical bug fix, the long-session benchmark is the place where that cost
must be earned back. If the plugin cannot demonstrate a downward-bending
duration curve, a higher brain-first hit rate at turn 10 than at turn 2,
and fewer re-learned facts across a session, then the "brain compounds"
claim is unsupported and should be retracted.

This scaffold exists so that the argument can be had on evidence rather
than vibes. Building out the real runs is the next piece of work.
