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

**v0.1.1 results** (n=3 per task × mode, 18 total runs):

| Task | Baseline | Plugin | Δ |
|---|---|---|---|
| 01-fizzbuzz | 27.8±1.4s | 16.6±2.1s | **-40%** |
| 02-bug-fix-surgical | 17.8±2.2s | 14.7±0.7s | **-18%** |
| 03-refactor-restraint | 25.6±3.1s | 26.9±8.8s | +5% (noise) |

100% pass rate in both modes. **Diff sizes byte-identical across modes** — meaning the "smaller diffs" claim is not yet supported.

**Provisional reading:** plugin appears faster on small tasks (likely real on simpler tasks; could be cache warmth or variance — n=3 too small to claim definitively). No measurable code-quality delta yet.

**Honest caveats:** 2 of 3 hooks are currently broken (Stop and PreToolUse — stdin parsing bug, fix in v0.1.2). The plugin v0.1.0 had ALL hooks broken due to a packaging bug. v0.1.1 fixed the packaging and the UserPromptSubmit hook now fires.

See [BENCHMARK.md](./BENCHMARK.md) for full methodology, caveats, and roadmap.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT
