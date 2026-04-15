# Claude Mind — Philosophy

Claude Mind is the synthesis of five practitioners' engineering philosophies, encoded as one Claude Code plugin. This document explains what each contributes and why each is necessary.

## Andrej Karpathy — *philosophy of the code*

> "Code is liability. Maintain the smallest possible surface area."

Karpathy's body of work — from his neural network tutorials to his commentary on software engineering — is consistently about *less*. Less code, fewer abstractions, fewer dependencies. The standard library does most of what people reach for packages for. The "smallest version that works" is almost always smaller than the version someone would naturally write.

In Claude Mind, this shows up in: `minimalism`, `surgical-editing`, `uv-python`, `bun-javascript`, `taste`.

**Read more:** [karpathy.ai](https://karpathy.ai), his GitHub, his "minGPT" / "nanoGPT" repos.

## Forrest Chang — *format of the skills*

> "[Skill files are code.](https://github.com/forrestchang)"

Chang's `andrej-karpathy-skills` repo demonstrated something structurally important: a thinker's engineering philosophy can be packaged as executable skill files that an agent reads and follows. The skill IS the code. This is the format that Claude Mind adopts.

In Claude Mind, this shows up in: every `SKILL.md` file. The format is the contribution.

**Read more:** [github.com/forrestchang](https://github.com/forrestchang).

## Boris Cherny — *infrastructure of the harness*

Boris built Claude Code. The hook system, the slash command system, the skill discovery system, the memory primitives — all of it. Claude Mind is just a particular composition of the primitives Cherny built.

In Claude Mind, this shows up in: every hook, every command, the `plugin.json` manifest itself.

## IndyDevDan — *loop of the session*

> "Context is king. The agent that remembers wins."

Dan's content focuses on context engineering and agentic loops — keeping the agent's state coherent across turns and sessions. Claude Mind's `signal-detector` (always-on capture) and `Stop` hook (session-end synthesis) implement this loop.

In Claude Mind, this shows up in: `signal-detector`, `UserPromptSubmit` hook, `Stop` hook.

**Read more:** [youtube.com/@indydevdan](https://www.youtube.com/@indydevdan).

## Garry Tan — *brain and taste*

> "Build something people want."

Garry's `gbrain` is a production-grade agent brain — Postgres, vector search, 25 skills, signal detection, brain-first lookup, compiled-truth + timeline pages. Claude Mind is much smaller in scope, but adopts gbrain's most portable patterns: brain-first lookup, the compiled-truth + timeline page format, the `taste` ship gate.

If you want the full version, install [`gbrain`](https://github.com/garrytan/gbrain) — Claude Mind will bridge to it automatically.

In Claude Mind, this shows up in: `brain-first`, `memory-protocol`, `taste`.

**Read more:** [github.com/garrytan/gbrain](https://github.com/garrytan/gbrain), [garrytan.com](https://garrytan.com).

## How they fit together

| Layer | Contributor | Manifestation |
|---|---|---|
| What gets written | Karpathy | minimalism, surgical edits |
| How it's encoded | Chang | fat skill files |
| What runs it | Cherny | Claude Code hooks/commands/skills |
| What persists across turns | IndyDevDan | signal capture + session synthesis |
| What gets remembered & shipped | Tan | brain-first, taste |

Each layer is necessary; none alone is sufficient. Karpathy's philosophy with no infrastructure is a Twitter thread. Cherny's infrastructure with no philosophy is a tool, not an opinion. Tan's brain without taste is a database.

Claude Mind is the stack.
