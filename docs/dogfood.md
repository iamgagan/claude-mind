# Dogfood Notes — v0.1.0 → v0.1.2

**Period:** 2026-04-15 to 2026-04-16
**Author:** maintainer (self-dogfood)
**Purpose:** Honest post-mortem of the alpha dogfood window. Records what actually
happened, not what we hoped would happen.

---

## 1. Scope

Dogfooding during the v0.1.0 → v0.1.2 window covered three things: self-install
from source on the author's machine, running the v0 benchmark harness against
the plugin under `claude -p` and the Claude Agent SDK, and iterating on bugs
that surfaced during those runs. It did **not** cover real long-session usage
(multi-hour coding sessions against a live project with brain-compounding and
taste gates firing on real PRs). The "30 minutes of normal Claude Code work"
scenario from spec §10 has not been exercised against a real codebase by a
real user yet — all observations here come from the benchmark harness and
from the author's own install.

---

## 2. What worked

Grounded in the commit history and benchmark artifacts, not vibes:

- **`/sc-init` scaffolds `./brain/` cleanly.** The command template from
  commit `0fbbef1` produces the expected directory layout on a fresh repo.
  No observed failures.
- **Skills load.** All 10 SKILL.md files are picked up by the resolver. No
  skill-loading errors appeared in any of the 18 benchmark runs.
- **Resolver routing held up.** The routing described in `docs/resolver.md`
  (commit `4a29193`) behaved as documented across the benchmark tasks — the
  right skills triggered for the right prompts, with no cross-talk.
- **100% pass rate on benchmark tasks.** 18/18 runs passed correctness tests
  in both baseline and plugin modes (see `BENCHMARK.md`). The plugin doesn't
  break anything.
- **Marketplace manifest is well-formed.** `.claude-plugin/` manifest added
  in `16380b5` installs without complaint via `claude plugins install`.
- **CI held.** `bun test` + shellcheck workflow (`e47c56b`) caught shell
  issues before they reached main. Release-on-tag workflow (`176015e`)
  worked on the v0.1.1 and v0.1.2 tags.

---

## 3. What broke (and got fixed)

This is where dogfooding actually earned its keep. Two real bugs shipped in
v0.1.0 and v0.1.1 respectively — both caught by running the plugin against
itself, neither caught by tests-as-written.

### v0.1.0 → v0.1.1: hook packaging bug (`06411fd`)

Hooks declared in the root `plugin.json` **silently did not fire** under
either `claude -p` or the `@anthropic-ai/claude-agent-sdk` runner. The
declared-but-broken configuration meant no error was raised — the hooks
were simply never invoked. This was only discovered when the v0 benchmark
runner (`ca1a89d`, SDK probe) showed that signal-capture side effects that
were supposed to write to `./brain/timeline/` never appeared.

The fix: move hook declarations from `plugin.json` to the standard
`hooks/hooks.json` format that Claude Code actually reads.

**Dogfooding win:** this bug would have shipped silently if no one had run
the plugin end-to-end under a real harness. Unit tests passed because they
tested the hook scripts in isolation, not the plugin's wiring.

### v0.1.1 → v0.1.2: stdin-vs-env hook input regression (`a227d6a`)

With hooks now firing, only `UserPromptSubmit` actually did useful work.
`Stop` and `PreToolUse` read their input from environment variables — but
Claude Code passes hook payloads as JSON on stdin. The hooks fired, read
nothing useful, and exited cleanly, so again: silent failure.

The fix: rewrite `hooks/stop.sh` and `hooks/pre-tool-use.sh` to parse stdin
JSON, and update `test/hooks.test.ts` to match the real calling convention.

**Dogfooding win (again):** the benchmark comparison between v0.1.1 and
v0.1.2 (see `BENCHMARK.md` "Version comparison") revealed that the v0.1.1
"speedup" was partly an artifact of two of three hooks being no-ops. Once
they fired for real, performance on non-trivial tasks got worse — a much
more informative result than the flattering v0.1.1 numbers.

### Relevant commits

```
738bbd9 docs: v0.1.2 benchmark results — honest picture
a227d6a fix(hooks): Stop + PreToolUse now read stdin JSON; bump v0.1.2
bfc3221 docs: v0.1.1 benchmark results + updated README
06411fd fix(hooks): use standard hooks.json format — hooks now fire
ca1a89d feat(benchmark): SDK probe — test whether hooks fire under @anthropic-ai/claude-agent-sdk
a1e0648 docs: report v0 benchmark null finding + diagnose claude -p hook bypass
```

---

## 4. Success-criteria scorecard

From spec §10. Honest scoring against evidence available as of v0.1.2:

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | `./brain/` populated with real, useful compiled-truth entries after 30 min of normal work | **Untested** | No real 30-min session has been run against a real project. Benchmark tasks are one-shot. |
| 2 | Smaller, more minimal code changes than baseline (measurable via diff sizes) | **Unmet** | `BENCHMARK.md`: plugin diffs are the same (tasks 01, 03) or larger (task 02, +3 lines). `surgical-editing` / `minimalism` show no measurable effect at n=3. |
| 3 | `<thinking>` blocks before non-trivial edits | **Untested** | No instrumentation yet to count thinking-block emissions. `PreToolUse` think-first reminder fires (since v0.1.2), but we haven't measured whether the model actually produces thinking blocks more often. |
| 4 | Taste gate catches at least one "gold-plating" moment | **Untested** | `/ship` command exists (`983e1c7`) but has not been run against a real PR. Benchmark tasks don't have a ship step. |
| 5 | Zero hook failures in normal operation | **Met (since v0.1.2)** | All 3 hooks fire correctly on stdin JSON. 0 hook failures across 18 benchmark runs on v0.1.2. Was **Unmet** in v0.1.0 (hooks didn't fire) and **Partial** in v0.1.1 (only 1 of 3 worked). |

**Summary:** 1 Met, 1 Unmet, 3 Untested. Not ready to claim v1.0 against
spec §10 — that requires 5 Met across 5 beta users, and we have 1 Met
across n=1 self-dogfood.

---

## 5. What's still untested

The whole long-horizon value proposition:

- **Brain-compounding over long sessions.** The pitch is that `/recall` and
  signal-capture pay off after the brain accumulates entries. We have no
  data on sessions longer than a single prompt. `BENCHMARK.md` roadmap
  flags this as the "v0.2 long-session benchmark."
- **Taste gate on real PRs.** `/ship` has never been run in anger. We
  don't know whether it actually catches gold-plating, or just adds
  friction.
- **Signal-detector recall.** We don't know what fraction of real signals
  the detector captures, or what its false-positive rate looks like. The
  `BENCHMARK.md` roadmap lists "signal-detector precision/recall" as a
  component-level eval to build.
- **Multi-turn session behavior.** The benchmark is one-shot prompts only.
  Resolver routing, brain-first lookup, and synthesis on `Stop` all
  behave differently across a real multi-turn session — untested.
- **Real-user install.** Only the author has installed this plugin. Spec
  §10's "5 beta users" bar is at 1.

---

## 6. Decision

**v0.1.2 is safe to ship.** 100% pass rate, 0 hook failures, no
correctness regressions, and the two silent-failure bugs from v0.1.0 and
v0.1.1 are fixed.

**But README claims about code quality must stay hedged** until a v0.2
benchmark run with n≥10 provides real evidence. Specifically:

- The `surgical-editing` and `minimalism` skills are **not** measurably
  producing smaller diffs. Any wording in README or skill docs that
  implies "the plugin makes your diffs smaller" is not supported by data
  and should read as aspirational, not empirical.
- The "faster on fizzbuzz" result (−28%) is interesting but n=3 and
  standard deviations overlap. It is not a headline-grade finding.
- The long-session value proposition is real in theory but zero in
  evidence. It stays in the roadmap section, not the pitch.

Ship v0.1.2. Keep the hedges. Do the v0.2 benchmark before tightening any
quality claims.
