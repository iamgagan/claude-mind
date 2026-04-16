# claude-mind benchmark harness (v0)

A small, honest benchmark for measuring whether the `claude-mind` plugin
helps vs baseline Claude Code on a tiny set of coding tasks.

> **This is v0.** It is deliberately minimal. Read the disclaimers below
> before drawing any conclusions from the numbers.

## What this measures

For each task, the harness records:

- **Task success** — did the agent's solution pass `test.sh`?
- **Wall-clock time** — how long the `claude -p` invocation took, in seconds.
- **Diff size** — total added + removed lines between the starter and the
  agent's final state, computed via `diff -ruN`.

These are the numbers that come out of `report.sh`.

## What this does NOT measure

- **Token usage / cost.** The CLI does not expose stable per-call token
  counts in `--print` mode, so we don't try to fake it.
- **"Taste" / code quality.** The closest proxy here is diff size (smaller
  is generally better on a bug-fix or surgical-edit task), but real taste
  needs human raters and a much larger task set.
- **Hook behavior.** It is uncertain whether `claude -p` non-interactive
  mode fires hooks (`UserPromptSubmit`, `PostToolUse`, etc.) the same way
  an interactive session does. If `claude-mind`'s `signal-detector` hook
  matters for a task, this harness may not exercise it.
- **Skill invocation.** Same caveat: whether skills marked "auto" actually
  load in `--print` mode is harness-dependent and may not match your
  daily-driver experience.
- **Anything that depends on conversation length.** Each task is a single
  one-shot prompt.

## Sample size warning

**Three tasks is NOT statistically significant.** A 5-percentage-point
gap on three samples is noise. A 30-line difference in one of three diffs
could easily be a single stylistic decision. Treat the report as a
sanity check on the harness wiring, not as evidence that the plugin
helps or hurts.

If you want a real result, you need:

1. More tasks (10+), drawn from a representative distribution of work.
2. Multiple runs per (task, mode) pair (5+) to estimate variance.
3. A pre-registered metric and a defined "what counts as a meaningful
   difference" threshold, decided before you look at the numbers.

## How to run

The runner does **not** enable or disable the plugin for you. You toggle
it explicitly between modes so you stay honest about what each result
actually represents.

```bash
# 1. Disable the plugin and capture a baseline.
claude plugins disable claude-mind
./benchmark/run.sh --mode baseline

# 2. Enable the plugin and capture a plugin run.
claude plugins enable claude-mind
./benchmark/run.sh --mode plugin

# 3. Generate the comparison report.
./benchmark/report.sh > BENCHMARK.md
```

You can also run a single task while iterating on the harness:

```bash
./benchmark/run.sh --task 01-fizzbuzz --mode baseline
```

## Layout

```
benchmark/
├── README.md              # this file
├── tasks/
│   ├── 01-fizzbuzz/       # sanity check — both modes should solve it
│   ├── 02-bug-fix-surgical/   # 1-line fix in an 80-line file; tests restraint
│   └── 03-refactor-restraint/ # add a kwarg without cleaning surrounding cruft
├── run.sh                 # runner; --mode and --task flags
├── report.sh              # aggregates results/ into a markdown table
├── results/               # *.json output, gitignored
└── .gitignore
```

Each task directory contains:

- `problem.md` — the prompt handed to the agent verbatim.
- `starter/` — the initial filesystem state copied into `.tmp/` per run.
- `test.sh` — exit 0 = passed, nonzero = failed. Receives the work dir
  via `cd "$(dirname "$0")"` (the harness copies it in alongside the
  agent's edits).

## Interpreting results

A row in the report looks like:

```
| 02-bug-fix-surgical | PASS / 18s / 35 lines | PASS / 22s / 12 lines | -23 |
```

Read this as: baseline solved it in 18 seconds with 35 changed lines;
plugin solved it in 22 seconds with 12 changed lines (a smaller, more
surgical edit). The Δ Diff column is `plugin - baseline`, so negative
means the plugin produced a smaller diff.

**Be skeptical.** With three tasks, anything but a stark, repeatable gap
is consistent with noise. If you see something interesting, the next
step is to run each (task, mode) 5–10 times and look at the
distribution.

## Known limitations

- The harness invokes `claude -p` with `--permission-mode acceptEdits`
  so the agent is not blocked by interactive permission prompts. If your
  daily-driver setup is more restrictive, results here will not match.
- Plugin enable/disable is left to the operator. The harness does not
  verify which plugins were active during a run.
- `claude -p` is given the full prompt and the working directory, but
  no other priming. Skills, hooks, and any "remember to consult brain
  first"-style behaviors are entirely up to whatever fires in that
  mode.
- One run per (task, mode) is high-variance. Use multiple runs and
  trust the median, not any single number.

## Honest summary

This harness is the smallest thing that could possibly produce a
comparable number. It exists so we stop arguing about whether the
plugin helps and start collecting data. It is not yet enough data to
answer the question.
