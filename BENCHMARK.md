# Claude Mind — Benchmark Results

**Last updated:** 2026-04-16
**Plugin version under test:** v0.1.1
**Sample size:** 3 iterations per (task × mode), 3 tasks, 2 modes — **18 total runs**

> ⚠️ **n=3 is not statistically significant.** These numbers should be read as
> a sanity check on the plugin's wiring after the v0.1.1 hook fix, not as
> definitive performance claims. A v1 benchmark with n≥10 is on the roadmap.

---

## Headline numbers

| Task | Baseline duration | Plugin duration | Δ | Both diffs |
|---|---|---|---|---|
| **01-fizzbuzz** (sanity) | 27.8 ± 1.4s | 16.6 ± 2.1s | **-40.2%** ⚡ | 16 lines (identical) |
| **02-bug-fix-surgical** | 17.8 ± 2.2s | 14.7 ± 0.7s | **-17.6%** ⚡ | 17 lines (identical) |
| **03-refactor-restraint** | 25.6 ± 3.1s | 26.9 ± 8.8s | +5.1% | 8 lines (identical) |

Pass rate: **100% in both modes on all 3 tasks** (18/18).

---

## What this actually tells us

### 1. The plugin doesn't break anything ✅
All 18 runs passed. No crashes, no broken tests, no regressions in solution quality. Adding claude-mind to your Claude Code setup is safe.

### 2. There's a measurable speedup on simple tasks
Tasks 01 and 02 are **17–40% faster** with the plugin enabled. This is surprising — we expected the plugin to *add* overhead from skill loading, not remove it.

**Possible explanations:**
- Skill prompts may give the model a clearer context window so it converges faster
- Could be measurement artifact — cache warmth between consecutive runs
- Could be variance — n=3 with ±1–2s standard deviations doesn't strongly reject the null

**Honest read:** "Plugin appears faster on small tasks, but n=3 is too small to claim this with confidence."

### 3. Diff sizes are byte-identical across modes
This is the **most important honest finding.** Every claim claude-mind makes about producing smaller, more surgical edits — `surgical-editing` skill, `minimalism` skill, `taste` ship gate — **shows zero observable effect on these three tasks**. Both modes wrote exactly the same code (within whitespace tolerance: 16/17/8 lines respectively).

**Likely cause:** the tasks are too small to discriminate. Fixing a one-line CSV bug or adding a kwarg can't really be "more or less surgical." A benchmark that measures these claims needs bigger tasks where scope creep is possible (real GitHub issues with complex codebases).

### 4. Refactor task (#03) shows no benefit and high noise
Plugin mode duration was 26.9 ± 8.8s. That ±8.8s standard deviation means individual runs varied by tens of percent. n=3 is far too few to draw conclusions.

---

## Plugin status — known bugs

| Hook | Fires under SDK? | Fires under `claude -p`? |
|---|---|---|
| **UserPromptSubmit** (signal-detector) | ✅ yes (verified, 24 entries written) | ✅ yes (verified, 8 hits) |
| **Stop** (synthesis) | ❌ **broken** — known bug | ❌ **broken** — known bug |
| **PreToolUse** (think-first) | ❌ **broken** — known bug | ❌ **broken** — known bug |

The `Stop` and `PreToolUse` hooks read `CLAUDE_TRANSCRIPT_PATH` and `CLAUDE_TOOL_NAME` from environment variables, but Claude Code passes hook input as JSON on stdin. **Fix planned for v0.1.2.**

So the v0.1.1 benchmark is measuring a setup where:
- Skills load and may influence the model's planning ✅
- Slash commands are available (but unused in the benchmark prompts) ✅
- UserPromptSubmit hook fires (writes to brain async) ✅
- Stop hook does NOT fire ❌
- PreToolUse hook does NOT fire ❌

The speedup we're seeing, if it's real, is happening **without** the think-first reminder hook and **without** the session synthesis hook. Those would only matter on multi-turn or long sessions, neither of which the benchmark exercises.

---

## What this means for users

✅ **Safe to install.** Doesn't break anything; may speed up small tasks.

⚠️ **2 of 3 hooks currently broken.** v0.1.2 will fix them. If your use case depends on think-first warnings or end-of-session synthesis, wait for v0.1.2.

⚠️ **Code-quality claims unsupported.** The plugin says it produces smaller diffs and more surgical edits. The benchmark currently shows neither effect. We need bigger tasks (real GitHub issues) to test these claims.

❓ **Speedup claim provisional.** -40% on a fizzbuzz is suspicious. We need n≥10 and ideally cold-cache runs to know if it's real.

---

## Methodology

```
Task:    01-fizzbuzz, 02-bug-fix-surgical, 03-refactor-restraint
Mode:    baseline (plugin disabled) vs plugin (claude-mind v0.1.1 enabled)
Runner:  ./benchmark/run.sh --mode <mode> --task <task>
Engine:  claude -p --permission-mode acceptEdits --output-format text
Iter:    3 per (task, mode), interleaved
Recorded: wall-clock duration, claude exit code, test.sh pass/fail, diff lines
```

**Caveats baked into the methodology:**
- Other plugins (`everything-claude-code`, `superpowers`, `warp`, `minimalist-entrepreneur`) were enabled in BOTH modes. The comparison is "claude-mind on top of these vs without." Not "vanilla Claude Code."
- The runner only toggles claude-mind; doesn't isolate from network/API jitter.
- Token usage not measured (`claude -p` doesn't expose stable per-call counts).
- No human raters, no "taste" measurement.

## Reproduction

```bash
git clone https://github.com/iamgagan/claude-mind.git
cd claude-mind

# Baseline (plugin disabled)
claude plugins disable claude-mind
for run in 1 2 3; do
  for task in 01-fizzbuzz 02-bug-fix-surgical 03-refactor-restraint; do
    ./benchmark/run.sh --mode baseline --task $task
  done
done

# Plugin (v0.1.1+ enabled)
claude plugins enable claude-mind
for run in 1 2 3; do
  for task in 01-fizzbuzz 02-bug-fix-surgical 03-refactor-restraint; do
    ./benchmark/run.sh --mode plugin --task $task
  done
done
```

## Roadmap

- **v0.1.2** — fix Stop and PreToolUse hooks (stdin JSON parsing); re-benchmark
- **v0.2 benchmark** — n≥10 per cell; bigger tasks (real GitHub issues); cold-cache runs; component-level evals (signal-detector precision/recall, brain-first hit rate)
- **v0.3 benchmark** — interactive driver to test the full hook loop in the actual Claude Code app
