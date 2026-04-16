# Claude Mind

> The opinionated senior-engineer brain for Claude Code.

A Claude Code plugin that synthesizes five engineering practitioners into one tightly-curated package — 10 skills, 3 hooks, 4 commands, brain-first memory protocol.

| Contributor | Contribution |
|---|---|
| **Andrej Karpathy** | Minimalism, code as liability |
| **Forrest Chang** | Thinker-philosophies as executable skills |
| **Boris Cherny** | Claude Code's hooks/memory/tool infrastructure |
| **IndyDevDan** | Agentic loops and context engineering |
| **Garry Tan** | Brain-first lookup, signal capture, taste |

See [PHILOSOPHY.md](./PHILOSOPHY.md) for the long version.

## Install

```bash
# From the marketplace (once published):
claude plugins install <user>/claude-mind

# Or from source:
git clone https://github.com/<user>/claude-mind.git ~/.claude/plugins/claude-mind
```

## Quickstart

In any project repo:

```bash
/sc-init        # scaffold ./brain/ and settings
/recall         # check what the brain knows about your topic
/remember <note>  # capture mid-session
/ship           # taste gate before commit/PR
```

## What's inside

**10 skills.** [`signal-detector`](./skills/signal-detector/SKILL.md), [`brain-first`](./skills/brain-first/SKILL.md), [`think-first`](./skills/think-first/SKILL.md), [`minimalism`](./skills/minimalism/SKILL.md), [`surgical-editing`](./skills/surgical-editing/SKILL.md), [`memory-protocol`](./skills/memory-protocol/SKILL.md), [`uv-python`](./skills/uv-python/SKILL.md), [`bun-javascript`](./skills/bun-javascript/SKILL.md), [`taste`](./skills/taste/SKILL.md), [`using-claude-mind`](./skills/using-claude-mind/SKILL.md).

**3 hooks.** UserPromptSubmit (signal capture), PreToolUse (think-first reminder), Stop (session synthesis).

**4 commands.** `/sc-init`, `/remember`, `/recall`, `/ship`.

**1 brain format.** Compiled-truth + timeline (see [docs/brain-format.md](./docs/brain-format.md)).

## Configuration

`./settings.json` (project-scoped) or `~/.claude/settings.json` (global):

```json
{
  "claude-mind": {
    "memory_location": "project",
    "memory_gitignored": true,
    "signal_detector_enabled": true,
    "signal_detector_model": "claude-haiku-4-5",
    "stop_hook_enabled": true,
    "gbrain_bridge_enabled": false
  }
}
```

## With gbrain

If you have [`garrytan/gbrain`](https://github.com/garrytan/gbrain) installed, set `gbrain_bridge_enabled: true` and Claude Mind will delegate brain ops for hybrid (vector + keyword) retrieval. See [docs/integrations/gbrain-bridge.md](./docs/integrations/gbrain-bridge.md).

## Compatibility

- macOS, Linux, Windows-with-WSL: full support
- Native Windows (no WSL): hooks skip silently; skills still work

## Benchmarks

**v0.1.2 results** (n=3 per task × mode, 18 total runs, all 3 hooks firing):

| Task | Baseline | Plugin | Δ dur | Δ diff |
|---|---|---|---|---|
| 01-fizzbuzz | 19.3±4.1s / 16 lines | 13.9±3.0s / 16 lines | **-28%** ⚡ | 0 |
| 02-bug-fix-surgical | 13.3±4.6s / 17 lines | 16.9±6.7s / 20±5 lines | +27% 🐢 | +3 |
| 03-refactor-restraint | 16.4±0.8s / 9±2 lines | 24.1±3.1s / 8 lines | +47% 🐢 | -1 |

100% pass rate in both modes.

**Honest reading:** Plugin is faster on trivial tasks, slower on non-trivial ones. Diff sizes are the same or slightly larger. The "smaller diffs" and "more surgical" claims are **not yet supported by data**. The overhead comes from hooks now actually firing (v0.1.1 showed false speedups because most hooks were broken).

**Where the value likely is:** brain-compounding over long sessions, taste-gate on real PRs, think-first preventing wrong-file edits — none of which a one-shot benchmark can measure.

See [BENCHMARK.md](./BENCHMARK.md) for full methodology, version comparison, and roadmap.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT
