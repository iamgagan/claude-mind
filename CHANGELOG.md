# Changelog

All notable changes to Claude Mind. Hand-written; written for users, not machines.

## v0.1.1 — 2026-04-16

**Critical bug fix.** Hooks did not fire in v0.1.0.

- Fixed: Plugin packaging — moved hook declarations from broken root `plugin.json` to standard `hooks/hooks.json` format.
- Verified: Hooks now fire under @anthropic-ai/claude-agent-sdk and `claude -p`.
- All users on v0.1.0 should run `claude plugins update claude-mind` to get the fix.

## v0.1.0 — 2026-04-15

Initial release.

- 10 skills: signal-detector, brain-first, think-first, minimalism, surgical-editing, memory-protocol, uv-python, bun-javascript, taste, using-claude-mind
- 3 hooks: UserPromptSubmit, PreToolUse, Stop
- 4 commands: /sc-init, /remember, /recall, /ship
- Compiled-truth + timeline brain page format
- Optional bridge to garrytan/gbrain for hybrid retrieval
- macOS + Linux + WSL supported
