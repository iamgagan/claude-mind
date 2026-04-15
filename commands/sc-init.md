---
name: sc-init
description: Bootstrap ./brain/ in the current repo with SOUL.md, USER.md, settings, and the directory structure
---

# /sc-init

Run this once per project to enable Claude Mind's memory protocol.

## What it does

1. Creates `./brain/` with subdirectories: `people/`, `companies/`, `concepts/`, `decisions/`, `errors/`, `references/`
2. Copies `SOUL.md` and `USER.md` templates into `./brain/`
3. Creates empty `_journal.md`, `_signals.md`, `_errors.log`
4. Writes default `settings.json` (project-scoped, gitignored memory)
5. Adds `brain/_signals.md`, `brain/_journal.md`, `brain/_errors.log` to `.gitignore` (the runtime files; brain pages themselves should be committed)
6. Prints next steps

## Behavior

- If `./brain/` already exists, abort with a one-liner and tell the user to delete it manually if they want to re-init.
- Never overwrite existing files.

## Implementation

The agent should:

```bash
mkdir -p ./brain/{people,companies,concepts,decisions,errors,references}
cp "$CLAUDE_PLUGIN_ROOT/templates/SOUL.md" ./brain/SOUL.md
cp "$CLAUDE_PLUGIN_ROOT/templates/USER.md" ./brain/USER.md
touch ./brain/_journal.md ./brain/_signals.md ./brain/_errors.log
# settings.json merge — preserve existing keys; add claude-mind key only if missing
```

Then prompt the user to fill in `USER.md` and customize `SOUL.md`.
