# Super Claude — Skill Resolver

This file routes user intent to the right skill. Read this first on any non-trivial task.

## Always-on (every turn)

- `signal-detector` — fires automatically via UserPromptSubmit hook. Captures original thinking and entities into the brain. Never blocks.
- `brain-first` — before any external lookup, web search, or new file creation, consult the brain.

## Before any file modification

- `think-first` — produce a `<thinking>` block stating the critical path.
- `surgical-editing` — patch, don't rewrite.
- `minimalism` — what's the smallest version that works?

## Brain operations

- `memory-protocol` — when reading or writing brain pages.

## Toolchain

- `uv-python` — Python projects (`pyproject.toml` or `*.py` present).
- `bun-javascript` — JS/TS projects (`package.json` or `*.ts` present).

## Ship gate

- `taste` — before any `git commit`, `gh pr create`, or release tag.

## Discovery

- `using-super-claude` — read this once per session for the full mental model.
