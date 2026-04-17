# claude-mind benchmark — v0.2 design

Status: **design / scaffold**. No runs yet.

v0.1 answered "does the plugin break anything?" (no) and "does it change
output on toy prompts?" (barely). It could not answer the questions that
matter. v0.2 is the plan for answering them.

## Goal

A statistically meaningful comparison of baseline Claude Code vs
claude-mind on tasks that actually exercise the plugin's hook loop.

Concretely, **n ≥ 10** runs per (task × mode) cell, bigger and more
realistic tasks, and at least one multi-turn session format so the
compounding claims (signal capture, brain-first, synthesis) have a
chance to show up.

### Specific questions v0.1 couldn't answer

1. **Does the plugin produce smaller diffs on non-toy tasks?** v0.1
   diffs were byte-identical on 2/3 tasks. The `surgical-editing` and
   `minimalism` skills never had a real test.
2. **Is the taste gate worth its wall-clock cost?** v0.1 showed +27% /
   +47% duration regressions on 2/3 tasks with no measurable quality
   payoff. We need a quality proxy that can reward the extra time.
3. **Does signal capture compound over a session?** v0.1 was one-shot;
   the brain stayed empty. A multi-turn task where turn 2 can reuse a
   signal from turn 1 is the minimum honest test.
4. **Do hooks even fire in the harness we're using?** v0.1 discovered
   `claude -p` skips `UserPromptSubmit` and `Stop`. v0.2 must either
   drive the interactive app or use the Agent SDK — see below.

## Task set (proposed, 5–7 tasks)

A graded set from toy → realistic → multi-turn. See `tasks.md` for
the enumerated list with IDs, sources, and success criteria.

- **2 toy tasks** carried over from v0.1 (fizzbuzz, bug-fix-surgical) as
  controls — if v0.2 numbers on these disagree with v0.1, the harness
  changed something.
- **2–3 realistic single-shot tasks** sourced from real GitHub issues
  at pinned commit SHAs. Candidate repos must be:
  - small (< 5 kLOC), so `claude -p` can load context without bloat;
  - test-covered, so `test.sh` can rerun the project's own suite;
  - deterministic-ish (no network, no time-sensitive fixtures);
  - MIT / Apache / BSD licensed.
  Working candidate list:
  - `sindresorhus/slugify` — tiny, 100% covered, real issues.
  - `kennethreitz/requests-html` — medium, has good "bug" issues.
  - `pallets/click` subset — we'd scope to a single subcommand file.
  - `python-attrs/attrs` — well-tested, clean issues.
  The v0.2 runner does a scripted `git checkout <SHA>` of a fixture
  into `.tmp/<task-id>/`, applies a known-failing test from the
  issue, and hands the agent the issue body as the prompt.
- **1–2 multi-turn tasks**, see protocol below.

## Multi-turn protocol

Hook-driven behavior (signal capture, synthesis) cannot be measured in a
single one-shot prompt. We need at least two turns where turn N+1 can
benefit from state left by turn N.

We drive this via the **Claude Agent SDK** (Python or TS) rather than
`claude -p`, because the SDK exposes session IDs and resume semantics
and — critically — fires hooks the same way the interactive app does.
`benchmark/sdk-probe/` already exists for this exploration; v0.2 builds
on it.

### State machine (4 turns)

```
turn 1  SCOPE     "Read the codebase. Describe the change in 3-5
                  bullets. Do NOT edit."
turn 2  PLAN      "Given that scope, write a plan: which files change,
                  in what order, what tests you'll run. Do NOT edit."
turn 3  IMPLEMENT "Implement the plan. Run tests. Iterate until green."
turn 4  REVIEW    "Review your diff. List anything you'd clean up if
                  you had more time."
```

The runner launches the SDK session once, sends each prompt sequentially
on the same session ID, records per-turn metrics, and the aggregate at
the end. Hooks fire naturally between turns.

Pass criteria: turn 3 ends with `test.sh` exit 0. Turns 1/2/4 are
observation-only.

## Metrics added vs v0.1

v0.1 recorded: `duration_seconds`, `claude_exit_code`, `test_passed`,
`diff_lines`. All kept. Added:

| Metric | Source |
|---|---|
| `token_usage` (in/out/cache) | `claude -p --output-format json` or SDK usage event |
| `tool_call_count` | count of `tool_use` blocks in JSON output |
| `files_touched` | `diff -ruN` filename count, not line count |
| `thinking_block_count` | count of `thinking` blocks in JSON output |
| `hook_invocations` | grep journal/signals count before vs after run |
| `turn_count` | for multi-turn, how many turns were actually used |

Hook invocations require reading `brain/_journal.md` and
`brain/_signals.md` timestamps — v0.2 snapshots these before and after
each run and diffs the line count. Not perfect, but it answers "did the
hooks fire at all?" which v0.1 could not.

## Sample-size math

From v0.1.2 (BENCHMARK.md headline table), duration stddevs on the
plugin side are 3.0 / 6.7 / 3.1 s with means 13.9 / 16.9 / 24.1 s.
Taking the worst case (task 02: σ ≈ 6.7 s, μ ≈ 16.9 s, so CV ≈ 0.40):
to detect a 20% difference (≈ 3.4 s) between two independent means
at α = 0.05 with β = 0.20 (80% power), the two-sample t approximation
gives n ≈ 2 σ² · (z\_{α/2} + z\_β)² / Δ² ≈ 2 · 44.9 · 7.85 / 11.6
≈ **n ≈ 61 per cell** — much worse than "n ≥ 10". So for the high-CV
tasks, n ≥ 10 only buys us the ability to detect **~50%** deltas, not
20% ones. Smaller tasks (σ ≈ 3.0–3.1) need n ≈ 12–15 per cell for the
same 20% detection, which fits the budget. Honest framing: n ≥ 10 lets
us reliably detect large effects; subtler effects need either more
iterations or lower-variance tasks.

## Non-goals for v0.2

- **No human raters.** Code quality is approximated by diff size,
  files-touched, and test pass rate. Taste judgments are out of scope
  until v0.3.
- **No production-code integration tests.** We rerun the target repo's
  own suite, not Netflix-scale end-to-end validation.
- **Single machine, single user.** No distributed runs, no hermetic
  container. We document the machine in the result JSON.
- **No replacement of v0.1.** This directory is additive. v0.1's
  `run.sh` and tasks are untouched.

## Directory layout (planned)

```
benchmark/v0.2/
├── README.md       (this file — design doc)
├── tasks.md        (enumerated task list)
├── run.sh          (scaffold; TODOs marked)
├── report.sh       (scaffold; TODOs marked)
└── tasks/          (to be populated; see tasks.md)
```

Results land in `benchmark/results/v0.2/` so v0.1 aggregation is
unaffected.
