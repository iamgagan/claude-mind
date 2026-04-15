# Super Claude — Design Spec

**Status:** Draft (v0.1)
**Date:** 2026-04-15
**Working name:** `super-claude` (see [Naming](#12-naming--open-risk) — collision with `NomenAK/SuperClaude_Framework`)
**Intended form factor:** Claude Code plugin, published to the marketplace

---

## 1. Vision

### 1.1 Positioning

**The opinionated senior-engineer brain for Claude Code.**

A single, tightly-curated Claude Code plugin that synthesizes the engineering
philosophy of five practitioners into one coherent agent behavior:

| Thinker | Contribution |
|---|---|
| **Andrej Karpathy** | *Philosophy of the code* — minimalism, std-lib first, code as liability, smallest diff |
| **Forrest Chang** ([`forrestchang/andrej-karpathy-skills`](https://github.com/forrestchang)) | *Format of the skills* — thinker-philosophies encoded as fat markdown skill files |
| **Boris Cherny** | *Infrastructure of the harness* — hooks, memory, tools, slash commands |
| **IndyDevDan** | *Loop of the session* — context engineering, always-on capture, persistence |
| **Garry Tan** ([`garrytan/gbrain`](https://github.com/garrytan/gbrain)) | *Brain + taste* — brain-first lookup, signal-detector, compiled-truth + timeline, ship gate |

Each contributes something structurally non-overlapping. The pitch in one
sentence: *Karpathy's philosophy, Chang's format, Cherny's infrastructure,
Dan's loop, Tan's brain and taste — one plugin, ten skills.*

### 1.2 Naming — open risk

Working name `super-claude` collides with
[`NomenAK/SuperClaude_Framework`](https://github.com/NomenAK/SuperClaude_Framework)
(popular existing project, different philosophy). **Rename decision deferred to
pre-publish.** Candidates under consideration:

- `super-claude` (keep; accept collision, rely on namespace)
- `claude-mind`, `synthesis`, `pentad`, `atelier` (synthesis-framed)
- `claw` (adjacent to Garry's `OpenClaw` namespace — potential or problem)
- `minima` (earlier working name — likely too small-sounding for this scope)

### 1.3 Non-goals (explicit)

- **No language skill sprawl.** No Go/Rust/Java/Swift skills; users compose with `everything-claude-code` or language-specific plugins for those.
- **No agents in v1.** Skills, hooks, and commands only. Agents can come in v2 if one earns its place.
- **No bundled MCP servers.** We may *bridge to* user-installed MCP servers (e.g., `gbrain`), but we do not ship one.
- **No AI-generated boilerplate.** `/sc init` creates a brain scaffold, nothing else.

---

## 2. Architecture

### 2.1 High-level shape

```
User prompt
  │
  ▼
┌──────────────────────────────────────────────────────┐
│  UserPromptSubmit hook                                │
│    → signal-detector skill (async, cheap model)       │
│       appends to brain pages                          │
└──────────────────────────────────────────────────────┘
  │
  ▼
┌──────────────────────────────────────────────────────┐
│  RESOLVER.md                                          │
│    routes intent → skill                              │
└──────────────────────────────────────────────────────┘
  │
  ▼
┌──────────────────────────────────────────────────────┐
│  Skill execution                                      │
│    brain-first → (recall context)                     │
│    think-first → (required before file mods)          │
│    minimalism / surgical-editing / taste / ...        │
└──────────────────────────────────────────────────────┘
  │
  ▼
┌──────────────────────────────────────────────────────┐
│  PreToolUse hook (Edit/Write)                         │
│    enforce think-first; warn if no <thinking>         │
└──────────────────────────────────────────────────────┘
  │
  ▼
┌──────────────────────────────────────────────────────┐
│  Stop hook                                            │
│    session → brain synthesis                          │
│    compiled-truth + timeline format                   │
└──────────────────────────────────────────────────────┘
```

### 2.2 Plugin layout (on-disk)

```
super-claude/                         # the published plugin repo
├── plugin.json                       # Claude Code plugin manifest
├── README.md                         # the pitch, install, quickstart
├── LICENSE                           # MIT
├── PHILOSOPHY.md                     # the five-thinker synthesis, in depth
├── docs/
│   ├── specs/                        # design specs (this file)
│   ├── brain-format.md               # compiled-truth + timeline spec
│   ├── resolver.md                   # how routing works
│   └── integrations/
│       └── gbrain-bridge.md          # optional gbrain integration
├── skills/
│   ├── RESOLVER.md                   # routes user intent → skill
│   ├── using-super-claude/SKILL.md   # entry skill
│   ├── signal-detector/SKILL.md
│   ├── brain-first/SKILL.md
│   ├── think-first/SKILL.md
│   ├── minimalism/SKILL.md
│   ├── surgical-editing/SKILL.md
│   ├── memory-protocol/SKILL.md
│   ├── uv-python/SKILL.md
│   ├── bun-javascript/SKILL.md
│   └── taste/SKILL.md
├── commands/
│   ├── sc-init.md                    # /sc init
│   ├── remember.md                   # /remember
│   ├── recall.md                     # /recall
│   └── ship.md                       # /ship
├── hooks/
│   ├── user-prompt-submit.sh         # async signal-detector trigger
│   ├── pre-tool-use.sh               # think-first enforcement
│   └── stop.sh                       # session → brain synthesis
├── templates/
│   ├── brain-page.md                 # compiled-truth + timeline template
│   ├── SOUL.md                       # agent identity template
│   └── USER.md                       # user profile template
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                    # lint + skill-manifest check
│   │   └── release.yml               # tag → marketplace publish
│   └── ISSUE_TEMPLATE/
└── test/
    ├── skills.test.ts                # every skill has valid frontmatter
    ├── hooks.test.ts                 # hooks are executable + produce expected artifacts
    └── fixtures/
```

Counts: **10 skills** (including `using-super-claude` entry skill), **3 hooks**, **4 commands**, **1 resolver**, **1 brain-format spec**.

---

## 3. Components

### 3.1 Skills (10 total)

Each skill is a **fat markdown file** with YAML frontmatter (`name`, `description`, `when-to-use`). Philosophy: thin harness, fat skills — the intelligence lives in the skill content, not the plugin runtime.

| Skill | Category | Thinker | Purpose |
|---|---|---|---|
| `using-super-claude` | Entry | All | Discovery skill — explains the five pillars and how the skills fit together |
| `signal-detector` | Always-on | Tan + Dan | Fires on every prompt. Captures original thinking + entities into brain asynchronously |
| `brain-first` | Always-on | Tan | Before any external lookup or new file, check the brain. Five-step protocol |
| `think-first` | Craft | Karpathy | Required `<thinking>` block before any Edit/Write. Enforced by PreToolUse hook |
| `minimalism` | Craft | Karpathy | Code-is-liability; reject-by-default for new deps; "what's the smallest version that works?" |
| `surgical-editing` | Craft | Karpathy | Patch, don't rewrite. Smallest diff. Named-line edits |
| `memory-protocol` | Brain | Tan | Compiled-truth + timeline page format; decision protocol for where new brain pages go (subject, not format, determines directory) |
| `uv-python` | Toolchain | Karpathy | `uv` for run/add/sync; no `pip install` by default |
| `bun-javascript` | Toolchain | Karpathy | `bun` as runtime/pm/bundler/test-runner; no `npm install` by default |
| `taste` | Ship gate | Tan | Invoked before commit/PR/release. One question: *"Is this the version you'd be proud of?"* |

#### Skill interaction patterns

- `signal-detector` and `brain-first` are **always-on**: they apply to every turn
- `think-first` gates Edit/Write tool use
- `taste` gates Bash tools matching `git commit`, `git push`, `gh pr create`, etc.
- `minimalism` + `surgical-editing` are invoked for any code-writing task
- `memory-protocol` is invoked when brain pages are written or new entries are added
- `uv-python` / `bun-javascript` are invoked for their respective ecosystems

### 3.2 Hooks (3 total)

| Hook event | Script | Purpose | Failure mode |
|---|---|---|---|
| `UserPromptSubmit` | `user-prompt-submit.sh` | Async fire signal-detector skill to capture thinking/entities. Never blocks. | Log-and-continue; never error the user prompt |
| `PreToolUse` (Edit/Write) | `pre-tool-use.sh` | Check if recent turn contained `<thinking>` block. Warn if absent. | Warn, never block |
| `Stop` | `stop.sh` | Invoke `claude -p` with a synthesis prompt; append compiled-truth + timeline entries to `./brain/` | Skip silently if `claude` CLI unavailable |

**Hook implementation language:** bash. All three are <50 lines. Intelligence lives in the prompt, not the shell (consistent with Approach A chosen during brainstorming).

**Cross-platform note:** bash hooks work on macOS, Linux, and Windows-with-WSL out of the box. Native Windows (PowerShell-only) users will get a graceful skip (`#!/usr/bin/env bash` missing → Claude Code skips the hook) and a one-line note in README pointing them at WSL. A pure-Windows port of the hooks is tracked as out-of-scope for v1.

**Signal-detector model default:** `claude-haiku-4-5` — cheap, fast, good enough for entity extraction. User-overridable via `settings.json`.

**Example: `stop.sh` skeleton**

```bash
#!/usr/bin/env bash
# Invoked by Claude Code at session end.
# Reads the session transcript, synthesizes a brain delta, appends to ./brain/
set -euo pipefail

[ -z "${CLAUDE_TRANSCRIPT_PATH:-}" ] && exit 0                        # no transcript
[ ! -d ./brain ] && exit 0                                            # no brain in this repo
command -v claude >/dev/null || exit 0                                # claude CLI missing

TRANSCRIPT=$(cat "$CLAUDE_TRANSCRIPT_PATH")
SYNTHESIS_PROMPT=$(cat "$CLAUDE_PLUGIN_ROOT/hooks/prompts/synthesis.md")

echo "$TRANSCRIPT" | claude -p "$SYNTHESIS_PROMPT" >> ./brain/_journal.md
```

(Synthesis prompt lives in a separate markdown file so users can customize without touching bash.)

### 3.3 Commands (4 total)

| Command | Purpose | Behavior |
|---|---|---|
| `/sc init` | Bootstrap brain in current repo | Creates `./brain/` with `SOUL.md`, `USER.md`, `_journal.md`; writes default `settings.json` for memory location |
| `/remember <note>` | Explicit mid-session capture | Appends a compiled-truth entry to the appropriate brain page (or creates new) |
| `/recall [query]` | Brain-first lookup before task | Greps + fuzzy-searches `./brain/`; if `gbrain` installed, delegates for hybrid search |
| `/ship` | Invoke `taste` gate before commit/PR/release | Runs the taste skill, then hands off to git/gh — never auto-commits |

### 3.4 RESOLVER.md

Borrowed directly from gbrain's pattern (credited). A single markdown file that reads like a decision tree, telling the agent which skill to invoke for which user intent. Agent reads it first on any non-trivial task.

### 3.5 Brain format

See `docs/brain-format.md`. The compiled-truth + timeline pattern (Tan's):

```markdown
---
type: concept | person | company | task | decision | ...
title: <subject>
tags: [...]
---

<Compiled truth: current best understanding. Rewritable.>

---

- YYYY-MM-DD: <evidence entry>
- YYYY-MM-DD: <another entry>
```

Above the second `---`: **compiled truth** — your agent's best current model.
Below: **timeline** — append-only evidence trail.

### 3.6 Storage tiers

| Tier | What it is | Default? |
|---|---|---|
| **Markdown-only** | `./brain/*.md` files, git-committed (or gitignored — user choice via `settings.json`). Zero dependencies. Portable. | **Yes (default)** |
| **gbrain bridge** | If user has `gbrain` installed, `brain-first` and `/recall` delegate to gbrain's MCP tools for Postgres+pgvector hybrid search | Opt-in via `settings.json` |

The gbrain bridge is pure delegation — we do not bundle, fork, or embed gbrain.
We just detect it and hand off.

### 3.7 Memory location config

Per user's global CLAUDE.md, memory can live in several places. Super Claude
respects a `memory_location` setting:

```json
{
  "super-claude": {
    "memory_location": "project",
    "memory_gitignored": true,
    "gbrain_bridge_enabled": false
  }
}
```

- `"project"` (default): `./brain/` in repo root
- `"global"`: `~/.claude/projects/<project>/brain/` (plays nice with existing user setup)
- `"custom"`: user-specified absolute path

---

## 4. Data flow

### 4.1 Normal turn

1. User sends prompt.
2. `UserPromptSubmit` hook fires → `signal-detector` runs async in a subprocess. Captures "interesting" content (user ideas, decisions, entities) → appends stub entries to `./brain/_signals.md`. **Never blocks the main turn.**
3. Agent reads `RESOLVER.md`, picks skill(s) to invoke.
4. If the intent is code or research: `brain-first` runs first → recalls relevant brain pages.
5. If the intent will write files: `think-first` is invoked → agent produces a `<thinking>` block.
6. `PreToolUse` hook on Edit/Write: checks for recent `<thinking>`; warns if absent.
7. Agent executes. `minimalism` / `surgical-editing` / toolchain skills shape *how* it writes.
8. If the turn ends with a ship-worthy artifact: user invokes `/ship` → `taste` gate runs.

### 4.2 Session end

1. User exits session or starts a new one.
2. `Stop` hook fires. Reads session transcript.
3. Invokes `claude -p` with synthesis prompt → gets a structured delta (new compiled-truth entries, timeline entries, errors encountered).
4. Appends to appropriate brain pages, creates new pages as needed.
5. If gbrain bridge is enabled, also syncs via gbrain MCP.

### 4.3 Explicit capture

1. User types `/remember user prefers no stubs in mocks — got burned by silent pass-throughs`.
2. Command parses intent, picks target brain page (feedback/testing), appends to timeline.
3. If no matching page exists, creates one with compiled-truth derived from the note.

---

## 5. Error handling

### 5.1 Hook failure modes

Every hook fails-closed toward "don't break the user's session":

- `UserPromptSubmit`: errors are logged to `./brain/_errors.log`, never surfaced
- `PreToolUse`: only warns, never blocks
- `Stop`: if `claude` CLI is missing or fails, skip silently (log to `_errors.log`)

Rationale: memory is a *nice-to-have*. A broken hook should never prevent the user from using Claude Code.

### 5.2 Missing brain

If `./brain/` doesn't exist:

- `brain-first`, `/recall`, `/remember`: print a one-line "no brain in this repo — run `/sc init` to enable" and proceed
- All other skills: unaffected

### 5.3 Missing toolchain

If `uv` or `bun` isn't installed when `uv-python` / `bun-javascript` is invoked:

- Skill detects via `command -v`
- Offers to install (`curl -LsSf https://astral.sh/uv/install.sh | sh` or `curl -fsSL https://bun.sh/install | bash`)
- Falls back to `pip` / `npm` with a one-line note if user declines

---

## 6. Testing

### 6.1 Skill manifest tests

Every skill file must have:

- Valid YAML frontmatter with `name`, `description`, `when-to-use`
- Body ≥ 100 words (fat skills, not stub files)
- Listed in `RESOLVER.md`

Runs in CI: `bun test test/skills.test.ts`

### 6.2 Hook tests

For each hook, a fixture-based test:

- Given a synthetic transcript / prompt / tool-call
- Invoke hook via the test harness
- Assert expected artifacts in a tmp `./brain/`

Runs in CI: `bun test test/hooks.test.ts`

### 6.3 Integration (manual, documented)

A `test/manual/` dir with scripted walkthroughs for:

- Fresh `/sc init` on an empty repo
- Full turn cycle with signal-detector active
- `Stop` hook synthesis on a recorded session
- `/ship` invocation of `taste` gate

These don't run in CI (they call out to Claude) but are referenced from CONTRIBUTING.md.

### 6.4 No TDD for skill *content*

Skill bodies are prompt engineering; they're verified through manual review and
dogfooding, not unit tests. What CI tests is **structure and wiring** (frontmatter
valid, hooks executable, RESOLVER.md covers all skills), not **intelligence**.

---

## 7. Distribution

### 7.1 Marketplace

Published to the Claude Code plugin marketplace as `<user>/super-claude`.

Marketplace manifest (`plugin.json`) declares skills/hooks/commands, a short
description, and the PHILOSOPHY.md URL as the long-form pitch.

### 7.2 Versioning

- **Semver.** 0.x during the shakedown period, 1.0 when skills and hook contracts are stable.
- **CHANGELOG.md.** Kept by hand, written for users not machines.
- **Releases.** Tag → `release.yml` workflow → publishes to marketplace.

### 7.3 License

MIT.

---

## 8. Out-of-scope for v1 (tracked for future)

- Agents (add if one genuinely earns its place in v2)
- Multi-language toolchain skills beyond uv/bun
- Own MCP server (delegate to gbrain instead)
- Voice, email, calendar ingestion (gbrain's territory)
- Hybrid vector search without gbrain (we delegate; we don't rebuild)
- GUI/web dashboard

---

## 9. Risks and open questions

| # | Risk | Mitigation |
|---|---|---|
| 1 | Name collision with `NomenAK/SuperClaude_Framework` | Decide at pre-publish; working name OK for now |
| 2 | `signal-detector` cost (extra cheap-model call per turn) | Make async + opt-out via `settings.json`; document token impact |
| 3 | `Stop` hook cost (synthesis call per session) | Same as above; opt-out available; prompt is small |
| 4 | gbrain bridge brittleness (gbrain evolves fast) | Pin to gbrain MCP contract; bridge doc lists tested versions |
| 5 | Attribution — am I correctly characterizing each thinker? | Draft PHILOSOPHY.md explicitly; invite corrections via GH issues before 1.0 |
| 6 | Marketplace approval — does it require anything special? | Research before finalizing `plugin.json` |

---

## 10. Success criteria

A user who installs Super Claude and runs `/sc init` in a fresh repo, then does
30 minutes of normal Claude Code work, should see:

1. A `./brain/` directory populated with real, useful compiled-truth entries
2. Smaller, more minimal code changes than their baseline (measurable via diff sizes)
3. `<thinking>` blocks before non-trivial edits
4. A `taste` gate that catches at least one "gold-plating" moment
5. Zero hook failures in normal operation

If those five hold across 5 beta users, v1.0 is ready.

---

## 11. Acknowledgments

Direct intellectual lineage (to be expanded in PHILOSOPHY.md):

- Andrej Karpathy — https://karpathy.ai
- Forrest Chang — https://github.com/forrestchang
- Boris Cherny — creator of Claude Code
- IndyDevDan — https://www.youtube.com/@indydevdan
- Garry Tan — https://github.com/garrytan, https://github.com/garrytan/gbrain

Related plugins this one explicitly does not replace:

- [`garrytan/gbrain`](https://github.com/garrytan/gbrain) — the brain. We bridge.
- [`garrytan/gstack`](https://github.com/garrytan/gstack) — the full coding skill stack.
- [`superpowers`](https://github.com/obra/superpowers) — general-purpose agentic discipline.
- [`everything-claude-code`](https://github.com/everything-claude-code) — the 100+-skill Costco.

---

## 12. Naming — open risk (cross-reference)

See [§1.2](#12-naming--open-risk). This must be resolved before `git push origin v0.1.0`.

---

*End of design spec v0.1.*
