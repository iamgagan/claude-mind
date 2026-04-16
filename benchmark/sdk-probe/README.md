# SDK probe

**Question:** Does the Anthropic Claude Agent SDK fire Claude Code hooks
(`UserPromptSubmit`, `Stop`, `PreToolUse`) when invoked from a Node.js script?

**Answer:** Yes — but with two important caveats. Read below.

---

## SDK package

- **Package:** `@anthropic-ai/claude-agent-sdk`
- **Version tested:** `0.2.111`
- **Entry point:** `query({ prompt, options })` from the package's default export
  (`sdk.mjs`). Returns a `Query` object that's an `AsyncGenerator<SDKMessage>`.
- **Key option:** `cwd` sets the session's working directory.
- **Hook gating option:** `settingSources?: ('user' | 'project' | 'local')[]`.
  When omitted/empty, the SDK runs in **isolation mode** — no filesystem
  settings are loaded, so no plugin hooks from `~/.claude/settings.json` fire.
- **Plugin loading option:** `plugins?: [{ type: 'local', path: string }]` —
  load a plugin explicitly by absolute path.
- **In-memory hook option:** `hooks?: Partial<Record<HookEvent, HookCallbackMatcher[]>>` —
  pass JS callbacks directly, no plugin or filesystem config needed.
- **Diagnostic option:** `includeHookEvents: true` makes the SDK emit
  `hook_started` / `hook_response` system messages on the stream so you can
  see exactly which hooks fired.

The full list of hook events the SDK exposes
(`HOOK_EVENTS` const in `sdk.d.ts`):
`PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `Notification`,
`UserPromptSubmit`, `SessionStart`, `SessionEnd`, `Stop`, `StopFailure`,
`SubagentStart`, `SubagentStop`, `PreCompact`, `PostCompact`,
`PermissionRequest`, `PermissionDenied`, `Setup`, `TeammateIdle`,
`TaskCreated`, `TaskCompleted`, `Elicitation`, `ElicitationResult`,
`ConfigChange`, `WorktreeCreate`, `WorktreeRemove`, `InstructionsLoaded`,
`CwdChanged`, `FileChanged`.

## What the probe tested

`probe.ts` runs `query()` twice in the same process, against the same prompt,
in the same `./brain/`-seeded tmp directory:

1. **Run 1 — defaults** (`settingSources` omitted, no `plugins`).
   Expectation: SDK isolation mode, no user-scope plugin hooks should fire.
2. **Run 2 — `settingSources: ['user']`**.
   Expectation: load `~/.claude/settings.json` and any plugins enabled there
   (the user has `claude-mind@claude-mind: true` in `enabledPlugins`).

After both runs complete, `run.sh` waits 30 s for the async-disowned
signal-detector subprocess, then checks whether `brain/_signals.md` (written
by claude-mind's `UserPromptSubmit` hook) or `brain/_journal.md` (written by
claude-mind's `Stop` hook) is non-empty.

## Result

| Run                                  | Brain `_signals.md` | Brain `_journal.md` |
| ------------------------------------ | ------------------- | ------------------- |
| 1 — defaults (isolation)             | empty               | empty               |
| 2 — `settingSources: ['user']`       | empty               | empty               |

Both probe runs returned successful assistant responses
(`subtype: "success"`), so the SDK is functional. The claude-mind hooks
themselves never fired.

### What we learned by going deeper

A diagnostic run with `includeHookEvents: true` confirmed the SDK absolutely
**does** fire hooks. With `settingSources: ['user']`, the following hooks
fired during a single query:

- 4 SessionStart:startup events (Warp plugin, superpowers plugin, gsd hooks, etc.)
- 1 UserPromptSubmit event (gsd)
- 5 Stop events (continuous-learning, gsd, etc.)

None of them was a claude-mind hook. We then explicitly loaded the plugin
via `plugins: [{ type: 'local', path: '/Users/gagan/.claude/plugins/cache/claude-mind/claude-mind/0.1.0' }]` —
no change. And finally we passed an in-memory JS callback for
`UserPromptSubmit` and `Stop`:

```ts
options: {
  hooks: {
    UserPromptSubmit: [{ hooks: [async (input) => { /* write to brain */ return { continue: true }; }] }],
    Stop:             [{ hooks: [async (input) => { /* write to brain */ return { continue: true }; }] }],
  },
}
```

Both callbacks fired and wrote to `brain/_signals.md` and `brain/_journal.md`.

### Root cause

The reason claude-mind's hooks don't fire is **not an SDK limitation** — it's
a plugin packaging mismatch. Compare the two layouts:

**claude-mind/plugin.json** (current — at plugin root):

```json
{
  "name": "claude-mind",
  "hooks": {
    "UserPromptSubmit": "./hooks/user-prompt-submit.sh",
    "PreToolUse": "./hooks/pre-tool-use.sh",
    "Stop": "./hooks/stop.sh"
  }
}
```

**warp/.claude-plugin/plugin.json + warp/hooks/hooks.json** (works under
both `claude` CLI and SDK):

```jsonc
// .claude-plugin/plugin.json — manifest only, no hook map
{ "name": "warp", "version": "2.0.0" }

// hooks/hooks.json — full settings.json hook config format
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/on-stop.sh" }
        ]
      }
    ]
  }
}
```

Two issues with claude-mind's current layout:

1. `plugin.json` should live in `.claude-plugin/plugin.json`, not the plugin
   root.
2. Hooks should be declared in `hooks/hooks.json` in the standard format
   (with optional `matcher`, `hooks: [{ type: "command", command: "..." }]`),
   not as a bare string-path map in `plugin.json`. Use `${CLAUDE_PLUGIN_ROOT}`
   for paths.

This explains why hooks don't fire under `claude -p` *or* under the SDK — the
loader doesn't recognize the format in either case.

## Implication for the benchmark

**The benchmark harness CAN be ported from `claude -p` to the SDK.** The SDK
fires `UserPromptSubmit` and `Stop` hooks reliably when:

- `settingSources: ['user']` is set (or some equivalent scope), AND
- Plugins are packaged in the supported layout.

Two unblocking paths, in priority order:

1. **Fix claude-mind's plugin packaging.** Move `plugin.json` to
   `.claude-plugin/plugin.json` and add `hooks/hooks.json` in the standard
   format. This fixes hook firing under both `claude -p` and the SDK and is
   the right long-term fix regardless of the benchmark.
2. **For the benchmark specifically,** you can also sidestep packaging by
   passing the hook commands inline via the SDK's `hooks: { ... }` option.
   That guarantees the harness exercises the same scripts in `hooks/*.sh`
   regardless of how the plugin loader treats them.

Either way, port the harness — the SDK is the right substrate.

## Next step recommendation

1. Verify the packaging hypothesis by reorganizing claude-mind's manifest to
   `.claude-plugin/plugin.json` + `hooks/hooks.json` and re-running this probe
   with `settingSources: ['user']`. Both brain files should populate.
2. Once confirmed, port `benchmark/run.sh` to call the SDK with
   `settingSources: ['user']` instead of shelling out to `claude -p`.
   This will make the existing tasks actually exercise the plugin's hooks.

## Files

- `probe.ts` — runs `query()` twice (defaults + `settingSources: ['user']`),
  prints per-run timing, message count, and assistant snippet.
- `run.sh` — seeds an isolated `./brain/` in a tmp dir, runs `probe.ts` inside
  it, waits 30 s for async hooks, prints the HOOK FIRING REPORT.
- `package.json` — bun project pinning `@anthropic-ai/claude-agent-sdk`.
- `tsconfig.json` — strict TypeScript with `skipLibCheck: true` (the SDK's
  bundled `.d.ts` ships several internal type errors at v0.2.111 that would
  otherwise block compilation).

## Reproduce

```bash
cd benchmark/sdk-probe
bun install
./run.sh
```

The run takes about 90 s wall-clock (two ~30 s SDK queries plus a 30 s
async-hook wait). The tmp dir is preserved at the end so you can inspect
`./brain/` yourself.
