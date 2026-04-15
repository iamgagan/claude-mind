# Super Claude

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
claude plugins install <user>/super-claude

# Or from source:
git clone https://github.com/<user>/super-claude.git ~/.claude/plugins/super-claude
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

**10 skills.** [`signal-detector`](./skills/signal-detector/SKILL.md), [`brain-first`](./skills/brain-first/SKILL.md), [`think-first`](./skills/think-first/SKILL.md), [`minimalism`](./skills/minimalism/SKILL.md), [`surgical-editing`](./skills/surgical-editing/SKILL.md), [`memory-protocol`](./skills/memory-protocol/SKILL.md), [`uv-python`](./skills/uv-python/SKILL.md), [`bun-javascript`](./skills/bun-javascript/SKILL.md), [`taste`](./skills/taste/SKILL.md), [`using-super-claude`](./skills/using-super-claude/SKILL.md).

**3 hooks.** UserPromptSubmit (signal capture), PreToolUse (think-first reminder), Stop (session synthesis).

**4 commands.** `/sc-init`, `/remember`, `/recall`, `/ship`.

**1 brain format.** Compiled-truth + timeline (see [docs/brain-format.md](./docs/brain-format.md)).

## Configuration

`./settings.json` (project-scoped) or `~/.claude/settings.json` (global):

```json
{
  "super-claude": {
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

If you have [`garrytan/gbrain`](https://github.com/garrytan/gbrain) installed, set `gbrain_bridge_enabled: true` and Super Claude will delegate brain ops for hybrid (vector + keyword) retrieval. See [docs/integrations/gbrain-bridge.md](./docs/integrations/gbrain-bridge.md).

## Compatibility

- macOS, Linux, Windows-with-WSL: full support
- Native Windows (no WSL): hooks skip silently; skills still work

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT
