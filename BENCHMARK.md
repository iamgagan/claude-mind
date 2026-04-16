# Claude Mind — Benchmark Results

**Last updated:** 2026-04-16
**Plugin version under test:** v0.1.2 (all 3 hooks firing)
**Sample size:** 3 iterations per (task × mode), 3 tasks, 2 modes — **18 total runs**

> ⚠️ **n=3 is not statistically significant.** These numbers are directional,
> not definitive. Standard deviations often exceed mean differences.
> A v1 benchmark with n≥10 is on the roadmap.

---

## Headline numbers (v0.1.2)

| Task | Baseline dur | Plugin dur | Δ dur | Baseline diff | Plugin diff | Δ diff |
|---|---|---|---|---|---|---|
| **01-fizzbuzz** (sanity) | 19.3 ± 4.1s | 13.9 ± 3.0s | **-28%** ⚡ | 16 | 16 | 0 |
| **02-bug-fix-surgical** | 13.3 ± 4.6s | 16.9 ± 6.7s | **+27%** 🐢 | 17 | 20 ± 5.2 | **+3** |
| **03-refactor-restraint** | 16.4 ± 0.8s | 24.1 ± 3.1s | **+47%** 🐢 | 9 ± 1.7 | 8 | -1 |

**Aggregate:** baseline 16.4 ± 4.1s / 14.0 diff, plugin 18.3 ± 6.0s / 14.7 diff.

Pass rate: **100% in both modes on all 3 tasks** (18/18).

---

## What this actually tells us

### 1. The plugin doesn't break anything ✅
All 18 runs passed. No crashes, no broken tests, no regressions in solution correctness.

### 2. Plugin is faster on trivial tasks, slower on non-trivial ones
- **Fizzbuzz (-28%):** Plugin still shows a speedup on the simplest task. Possibly real — skill context may help the model converge faster when the task is obvious.
- **Bug fix (+27%):** Plugin is slower. One of three plugin runs produced a 26-line diff instead of the 17-line baseline — the agent did extra work. This is the **opposite** of what `surgical-editing` promises.
- **Refactor (+47%):** Plugin is significantly slower with essentially the same diff size. Hook overhead + skill loading may eat time when the agent doesn't benefit from the extra context.

### 3. The plugin occasionally produces larger diffs
Task 02 plugin run 2 wrote 26 lines vs the baseline's consistent 17. This is a single outlier (n=1), but it's the first time the plugin produced *different code* from baseline — and it was more, not less.

### 4. The "smaller diffs" claim is still unsupported
Across 18 runs, the plugin produced the same or slightly larger diffs than baseline. The `surgical-editing` and `minimalism` skills show no measurable effect.

---

## Version comparison

The story changed between v0.1.1 (UserPromptSubmit only) and v0.1.2 (all hooks firing):

| Task | v0.1.1 Δ dur | v0.1.2 Δ dur | What changed |
|---|---|---|---|
| 01-fizzbuzz | -40% | -28% | Still faster; gap shrank |
| 02-bug-fix-surgical | -18% | +27% | **Flipped** — now slower |
| 03-refactor-restraint | +5% | +47% | Was noise; now clearly slower |

**Interpretation:** with all hooks firing (Stop synthesis, PreToolUse think-first reminder), the plugin adds overhead that outweighs any benefit on small tasks. The v0.1.1 "speedup" was partly an artifact of most hooks not firing.

---

## Hook status — all green

| Hook | Status |
|---|---|
| **UserPromptSubmit** (signal-detector) | ✅ fires (since v0.1.1) |
| **Stop** (synthesis) | ✅ fires (since v0.1.2) |
| **PreToolUse** (think-first) | ✅ fires (since v0.1.2) |

---

## What this means for users

✅ **Safe to install.** 100% pass rate; no correctness regressions.

⚠️ **Expect overhead on small tasks.** The plugin adds ~2-8 seconds on one-shot prompts due to hook execution + skill context loading. This may be worthwhile if the brain-compounding and taste-gate save you time over a full session — but the one-shot benchmark can't measure that.

⚠️ **Code-quality claims still unsupported.** Diff sizes are the same or slightly larger with the plugin. The `surgical-editing` and `minimalism` skills are not measurably improving output on these tasks.

❓ **The real value may only show over long sessions.** Signal capture compounds. Brain-first lookup pays off when the brain has entries. The taste gate matters on real PRs, not benchmarked toy tasks. None of these are tested by this benchmark.

---

## Methodology

```
Task:    01-fizzbuzz, 02-bug-fix-surgical, 03-refactor-restraint
Mode:    baseline (plugin disabled) vs plugin (claude-mind v0.1.2 enabled)
Runner:  ./benchmark/run.sh --mode <mode> --task <task>
Engine:  claude -p --permission-mode acceptEdits --output-format text
Iter:    3 per (task, mode)
Recorded: wall-clock duration, claude exit code, test.sh pass/fail, diff lines
```

**Caveats:**
- Other plugins (`everything-claude-code`, `superpowers`, `warp`, `minimalist-entrepreneur`) enabled in BOTH modes.
- Runner doesn't isolate from network/API jitter.
- Token usage not measured.
- No human raters, no "taste" measurement.
- One-shot prompts only; no multi-turn sessions.

## Reproduction

```bash
git clone https://github.com/iamgagan/claude-mind.git
cd claude-mind

# Clear old results
rm -f benchmark/results/*.json

# Baseline
claude plugins disable claude-mind
for run in 1 2 3; do
  for task in 01-fizzbuzz 02-bug-fix-surgical 03-refactor-restraint; do
    ./benchmark/run.sh --mode baseline --task $task
  done
done

# Plugin
claude plugins enable claude-mind
for run in 1 2 3; do
  for task in 01-fizzbuzz 02-bug-fix-surgical 03-refactor-restraint; do
    ./benchmark/run.sh --mode plugin --task $task
  done
done
```

## Roadmap

- **v0.2 benchmark** — n≥10 per cell; bigger tasks (real GitHub issues); multi-turn sessions
- **Component-level evals** — signal-detector precision/recall, brain-first hit rate, synthesis quality rubric
- **Long-session benchmark** — measure brain compounding over 10+ turns (the actual value proposition)
