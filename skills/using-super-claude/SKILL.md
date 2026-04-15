---
name: using-super-claude
description: Read this once per session — the five-thinker mental model and how all Super Claude skills fit together
when-to-use: At the start of any session where Super Claude is installed; when the user invokes `/sc-help`
---

# Using Super Claude

Super Claude is the synthesis of five practitioners' engineering philosophies, encoded as 10 skills, 3 hooks, and 4 commands. Read this once per session to understand how the pieces fit.

## The five contributors

1. **Karpathy — philosophy of the code.** Code is liability. Std-lib first. Reject-by-default for new dependencies. Smallest diff that works. → Skills: `minimalism`, `surgical-editing`, `uv-python`, `bun-javascript`.

2. **Forrest Chang — format of the skills.** Thinker-philosophies encoded as fat markdown skill files. The skill IS the executable knowledge. → All skills follow this format.

3. **Boris Cherny — infrastructure of the harness.** Hooks, memory, tools, slash commands. → All hooks and commands.

4. **IndyDevDan — loop of the session.** Always-on capture, persistence, context engineering. → Skill: `signal-detector` + UserPromptSubmit hook + Stop hook.

5. **Garry Tan — brain and taste.** Brain-first lookup. Compiled-truth + timeline pages. Ship gate. → Skills: `brain-first`, `memory-protocol`, `taste`.

## Operating principles (in order of precedence)

1. **Brain-first.** Before any external lookup or new file, consult the brain (see `brain-first`).
2. **Think-first.** Before any file modification, produce a `<thinking>` block (see `think-first`).
3. **Minimalist by default.** Reject new dependencies; use std lib; smallest diff (see `minimalism`).
4. **Surgical edits.** Patch, don't rewrite (see `surgical-editing`).
5. **Taste before ship.** Before any commit/PR/release, ask "is this the version I'd be proud of?" (see `taste`).

## Discovery flow

User prompt → UserPromptSubmit hook fires `signal-detector` (async) → agent reads `RESOLVER.md` → agent invokes the relevant skill(s) → PreToolUse hook checks for `<thinking>` before edits → Stop hook synthesizes session into brain at end.

## When NOT to use Super Claude

Super Claude's opinions are strong. They're wrong for:
- One-line typo fixes (overhead exceeds value)
- Greenfield prototypes where speed > taste
- Codebases that have a different established philosophy you're contributing to

In those cases, disable via `settings.json` or use Claude Code without the plugin.

## Skill index

| Skill | Purpose |
|---|---|
| `signal-detector` | Always-on capture (auto via hook) |
| `brain-first` | Lookup before action |
| `think-first` | Reasoning before edits |
| `minimalism` | Reject deps, smallest version |
| `surgical-editing` | Patch, don't rewrite |
| `memory-protocol` | Brain page format and placement |
| `uv-python` | Python toolchain |
| `bun-javascript` | JS/TS toolchain |
| `taste` | Ship gate |
| `using-super-claude` | This file |

## Commands

- `/sc-init` — bootstrap brain in current repo
- `/remember <note>` — explicit capture
- `/recall [query]` — brain lookup
- `/ship` — taste gate before commit/PR
