# Claude Mind Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publish a Claude Code plugin that synthesizes Karpathy, Chang, Cherny, IndyDevDan, and Garry Tan into one tightly-curated package — 10 skills, 3 hooks, 4 commands, brain-first memory protocol, marketplace-ready.

**Architecture:** Thin harness, fat skills. All intelligence lives in the SKILL.md content; bash hooks under 50 lines each; markdown-only brain by default with optional `gbrain` bridge. See spec at [`../specs/2026-04-15-claude-mind-design.md`](../specs/2026-04-15-claude-mind-design.md).

**Tech Stack:** Bash (hooks), Markdown (skills/commands/docs), TypeScript + Bun (tests/CI), GitHub Actions (CI/release).

---

## Approach Notes

- **TDD where it matters:** structural tests for skills/manifest are written first (Phase 1). Hook scripts get fixture-based TDD (Phase 6). Skill *content* is prose; verified by the structural test, not by unit tests of the prose.
- **Frequent commits:** every task ends with a `git commit`. No batched commits across tasks.
- **DRY:** templates live in `templates/`; the brain-page format is defined once in `docs/brain-format.md` and referenced from `memory-protocol/SKILL.md`.
- **YAGNI:** anything in spec §8 ("Out-of-scope for v1") is not in this plan. Resist scope creep during execution.
- **Cross-platform:** bash hooks; native-Windows users get a graceful skip + WSL note. No PowerShell port in v1.

---

## File Structure

| Path | Responsibility |
|---|---|
| `plugin.json` | Claude Code plugin manifest (declares skills/commands/hooks) |
| `README.md` | Pitch, install, quickstart, the five-thinker synthesis |
| `LICENSE` | MIT |
| `PHILOSOPHY.md` | Long-form pitch — each thinker's contribution |
| `CHANGELOG.md` | Hand-written, user-facing |
| `CONTRIBUTING.md` | How to add skills, run tests, propose changes |
| `.gitignore` | node_modules, .DS_Store, brain/_signals.md (in plugin repo only) |
| `package.json` | Bun deps for tests; no runtime deps |
| `tsconfig.json` | TS config for tests |
| `docs/specs/` | Design specs (already populated) |
| `docs/plans/` | Implementation plans (this file) |
| `docs/brain-format.md` | Compiled-truth + timeline format spec |
| `docs/resolver.md` | How RESOLVER.md routing works |
| `docs/integrations/gbrain-bridge.md` | Optional gbrain delegation |
| `skills/RESOLVER.md` | Routes user intent → skill |
| `skills/<name>/SKILL.md` | One per skill (10 total) |
| `commands/<name>.md` | One per slash command (4 total) |
| `hooks/user-prompt-submit.sh` | Async signal-detector trigger |
| `hooks/pre-tool-use.sh` | think-first enforcement |
| `hooks/stop.sh` | Session → brain synthesis |
| `hooks/prompts/synthesis.md` | The synthesis prompt for stop.sh |
| `hooks/prompts/signal-detector.md` | The signal-detector prompt |
| `templates/brain-page.md` | Compiled-truth + timeline starter |
| `templates/SOUL.md` | Agent identity scaffold |
| `templates/USER.md` | User profile scaffold |
| `templates/settings.json` | Default settings written by `/sc init` |
| `test/skills.test.ts` | Structural tests for skill files |
| `test/hooks.test.ts` | Fixture-based hook tests |
| `test/fixtures/` | Synthetic transcripts, prompts, tool calls |
| `.github/workflows/ci.yml` | Lint + tests on PR |
| `.github/workflows/release.yml` | Tag → marketplace publish |
| `.github/ISSUE_TEMPLATE/` | Bug + feature templates |

---

## Phase 0: Scaffolding

### Task 0.1: Initialize git repo

**Files:**
- Create: `.gitignore`

- [ ] **Step 1: Init repo and create .gitignore**

```bash
cd /Users/gagan/Projects/claude-mind
git init
```

Write `.gitignore`:

```gitignore
node_modules/
.DS_Store
*.log
.env
.env.local
brain/_signals.md
brain/_journal.md
brain/_errors.log
test/.tmp/
dist/
.bun/
```

- [ ] **Step 2: First commit (spec only)**

```bash
git add docs/specs/2026-04-15-claude-mind-design.md docs/plans/2026-04-15-claude-mind.md .gitignore
git commit -m "chore: initial commit — design spec + implementation plan"
```

Expected: commit succeeds with three files.

---

### Task 0.2: Plugin manifest & license

**Files:**
- Create: `plugin.json`
- Create: `LICENSE`

- [ ] **Step 1: Write `plugin.json`**

```json
{
  "name": "claude-mind",
  "version": "0.1.0",
  "description": "The opinionated senior-engineer brain for Claude Code. Karpathy + Chang + Cherny + IndyDevDan + Tan, synthesized.",
  "author": "iamgagan",
  "license": "MIT",
  "homepage": "https://github.com/iamgagan/claude-mind",
  "skills": "./skills",
  "commands": "./commands",
  "hooks": {
    "UserPromptSubmit": "./hooks/user-prompt-submit.sh",
    "PreToolUse": "./hooks/pre-tool-use.sh",
    "Stop": "./hooks/stop.sh"
  }
}
```

- [ ] **Step 2: Write `LICENSE` (MIT)**

```
MIT License

Copyright (c) 2026 Gagan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: Commit**

```bash
git add plugin.json LICENSE
git commit -m "chore: add plugin manifest and MIT license"
```

---

### Task 0.3: README skeleton

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write README skeleton (final polish in Phase 9)**

```markdown
# Claude Mind

> The opinionated senior-engineer brain for Claude Code.

A Claude Code plugin that synthesizes the engineering philosophy of five practitioners into one coherent agent behavior:

- **Andrej Karpathy** — minimalism, code as liability
- **Forrest Chang** — thinker-philosophies as executable skills
- **Boris Cherny** — Claude Code's hooks/memory/tool infrastructure
- **IndyDevDan** — agentic loops and context engineering
- **Garry Tan** — brain-first lookup, signal capture, taste

**Status:** v0.1 (alpha)

## Install

> _Marketplace install command goes here once published._

## Quickstart

After install, in any project repo:

```bash
/sc init        # scaffold ./brain/ and settings
/recall         # check what the brain already knows
/remember <note>  # capture mid-session
/ship           # taste gate before commit/PR
```

## Philosophy

See [PHILOSOPHY.md](./PHILOSOPHY.md).

## License

MIT
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: README skeleton"
```

---

## Phase 1: Test Infrastructure

### Task 1.1: Bun + TypeScript setup

**Files:**
- Create: `package.json`
- Create: `tsconfig.json`

- [ ] **Step 1: Write `package.json`**

```json
{
  "name": "claude-mind",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "test": "bun test",
    "lint": "bun run lint:skills && bun run lint:hooks",
    "lint:skills": "bun test test/skills.test.ts",
    "lint:hooks": "bun test test/hooks.test.ts"
  },
  "devDependencies": {
    "@types/bun": "latest",
    "gray-matter": "^4.0.3"
  }
}
```

- [ ] **Step 2: Write `tsconfig.json`**

```json
{
  "compilerOptions": {
    "lib": ["ESNext"],
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "skipLibCheck": true,
    "types": ["bun-types"]
  },
  "include": ["test/**/*.ts"]
}
```

- [ ] **Step 3: Install deps and verify**

```bash
bun install
bun test --help
```

Expected: bun install succeeds; `bun test --help` prints usage.

- [ ] **Step 4: Commit**

```bash
git add package.json tsconfig.json bun.lockb
git commit -m "chore: bun + typescript test setup"
```

---

### Task 1.2: Skill manifest test (TDD — write the failing test first)

**Files:**
- Create: `test/skills.test.ts`

- [ ] **Step 1: Write failing test — "every skill has valid frontmatter"**

```typescript
// test/skills.test.ts
import { describe, expect, test } from "bun:test";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import matter from "gray-matter";

const SKILLS_DIR = join(import.meta.dir, "..", "skills");
const REQUIRED_FIELDS = ["name", "description"] as const;
const MIN_BODY_WORDS = 100;

function listSkills(): string[] {
  return readdirSync(SKILLS_DIR)
    .filter((entry) => {
      const full = join(SKILLS_DIR, entry);
      return statSync(full).isDirectory();
    });
}

describe("skills", () => {
  test("at least one skill exists", () => {
    expect(listSkills().length).toBeGreaterThan(0);
  });

  for (const skill of listSkills()) {
    describe(skill, () => {
      const skillPath = join(SKILLS_DIR, skill, "SKILL.md");
      const raw = readFileSync(skillPath, "utf8");
      const { data, content } = matter(raw);

      test("has SKILL.md", () => {
        expect(raw.length).toBeGreaterThan(0);
      });

      test.each(REQUIRED_FIELDS)("frontmatter has %s", (field) => {
        expect(data[field]).toBeTruthy();
      });

      test(`body has at least ${MIN_BODY_WORDS} words`, () => {
        const wordCount = content.trim().split(/\s+/).length;
        expect(wordCount).toBeGreaterThanOrEqual(MIN_BODY_WORDS);
      });
    });
  }

  test("RESOLVER.md exists and references every skill", () => {
    const resolverPath = join(SKILLS_DIR, "RESOLVER.md");
    const resolver = readFileSync(resolverPath, "utf8");
    for (const skill of listSkills()) {
      expect(resolver).toContain(skill);
    }
  });
});
```

- [ ] **Step 2: Run test — expect it to fail (no skills yet)**

```bash
bun test test/skills.test.ts
```

Expected: FAIL with "ENOENT" or "at least one skill exists" failure (skills/ doesn't exist).

- [ ] **Step 3: Create empty `skills/` and re-run**

```bash
mkdir -p skills
bun test test/skills.test.ts
```

Expected: FAIL — "at least one skill exists" because directory is empty.

- [ ] **Step 4: Commit (red test in place)**

```bash
git add test/skills.test.ts
git commit -m "test: skill manifest validator (red)"
```

---

### Task 1.3: Hook test scaffold (TDD — write the failing test first)

**Files:**
- Create: `test/hooks.test.ts`
- Create: `test/fixtures/transcript-minimal.txt`

- [ ] **Step 1: Write fixture transcript**

```
test/fixtures/transcript-minimal.txt:

User: refactor the auth middleware to use the new token store
Assistant: <thinking>The middleware lives in src/auth/middleware.ts. I need to swap the old token-store import for the new one and update the call site.</thinking>
[edits src/auth/middleware.ts]
User: looks good, ship it
```

- [ ] **Step 2: Write failing test — "stop.sh appends to ./brain/_journal.md"**

```typescript
// test/hooks.test.ts
import { describe, expect, test, beforeEach, afterEach } from "bun:test";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { spawnSync } from "node:child_process";

const HOOK_DIR = join(import.meta.dir, "..", "hooks");
const FIXTURE_DIR = join(import.meta.dir, "fixtures");

describe("stop.sh", () => {
  let tmp: string;

  beforeEach(() => {
    tmp = mkdtempSync(join(tmpdir(), "sc-test-"));
    mkdirSync(join(tmp, "brain"));
  });

  afterEach(() => {
    rmSync(tmp, { recursive: true, force: true });
  });

  test("appends to ./brain/_journal.md when transcript present", () => {
    const result = spawnSync("bash", [join(HOOK_DIR, "stop.sh")], {
      cwd: tmp,
      env: {
        ...process.env,
        CLAUDE_TRANSCRIPT_PATH: join(FIXTURE_DIR, "transcript-minimal.txt"),
        CLAUDE_PLUGIN_ROOT: join(import.meta.dir, ".."),
        // Force the fake-claude shim so test doesn't call the real CLI:
        PATH: `${join(import.meta.dir, "fixtures", "bin")}:${process.env.PATH}`,
      },
    });

    expect(result.status).toBe(0);
    expect(existsSync(join(tmp, "brain", "_journal.md"))).toBe(true);
    const journal = readFileSync(join(tmp, "brain", "_journal.md"), "utf8");
    expect(journal).toContain("[fake-claude-output]");
  });

  test("exits 0 silently if no ./brain/ directory", () => {
    rmSync(join(tmp, "brain"), { recursive: true });
    const result = spawnSync("bash", [join(HOOK_DIR, "stop.sh")], {
      cwd: tmp,
      env: { ...process.env, CLAUDE_TRANSCRIPT_PATH: join(FIXTURE_DIR, "transcript-minimal.txt") },
    });
    expect(result.status).toBe(0);
  });

  test("exits 0 silently if claude CLI missing", () => {
    const result = spawnSync("bash", [join(HOOK_DIR, "stop.sh")], {
      cwd: tmp,
      env: { ...process.env, CLAUDE_TRANSCRIPT_PATH: join(FIXTURE_DIR, "transcript-minimal.txt"), PATH: "/usr/bin" },
    });
    expect(result.status).toBe(0);
  });
});
```

- [ ] **Step 3: Create `test/fixtures/bin/claude` shim**

```bash
mkdir -p test/fixtures/bin
cat > test/fixtures/bin/claude <<'EOF'
#!/usr/bin/env bash
# Test shim: ignores stdin, prints a marker line so tests can assert
echo "[fake-claude-output] $(date)"
EOF
chmod +x test/fixtures/bin/claude
```

- [ ] **Step 4: Run test — expect it to fail (no stop.sh yet)**

```bash
bun test test/hooks.test.ts
```

Expected: FAIL — `hooks/stop.sh` does not exist.

- [ ] **Step 5: Commit (red tests in place)**

```bash
git add test/hooks.test.ts test/fixtures/
git commit -m "test: hook test scaffold + fixtures (red)"
```

---

## Phase 2: Resolver + Entry Skill

### Task 2.1: RESOLVER.md

**Files:**
- Create: `skills/RESOLVER.md`

- [ ] **Step 1: Write the resolver**

```markdown
# Claude Mind — Skill Resolver

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

- `using-claude-mind` — read this once per session for the full mental model.
```

- [ ] **Step 2: Run skills test (still expect failures — no skill dirs)**

```bash
bun test test/skills.test.ts
```

Expected: FAIL on "at least one skill exists" — RESOLVER.md exists but no skill dirs.

- [ ] **Step 3: Commit**

```bash
git add skills/RESOLVER.md
git commit -m "feat(skills): add RESOLVER.md"
```

---

### Task 2.2: `using-claude-mind` entry skill

**Files:**
- Create: `skills/using-claude-mind/SKILL.md`

- [ ] **Step 1: Write the entry skill**

```markdown
---
name: using-claude-mind
description: Read this once per session — the five-thinker mental model and how all Claude Mind skills fit together
when-to-use: At the start of any session where Claude Mind is installed; when the user invokes `/sc help`
---

# Using Claude Mind

Claude Mind is the synthesis of five practitioners' engineering philosophies, encoded as 10 skills, 3 hooks, and 4 commands. Read this once per session to understand how the pieces fit.

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

## When NOT to use Claude Mind

Claude Mind's opinions are strong. They're wrong for:
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
| `using-claude-mind` | This file |

## Commands

- `/sc init` — bootstrap brain in current repo
- `/remember <note>` — explicit capture
- `/recall [query]` — brain lookup
- `/ship` — taste gate before commit/PR
```

- [ ] **Step 2: Run skill test — expect partial pass**

```bash
bun test test/skills.test.ts
```

Expected: PASS for `using-claude-mind` (frontmatter + body word count + RESOLVER.md mentions it). Other "every skill" loops are empty.

- [ ] **Step 3: Commit**

```bash
git add skills/using-claude-mind/
git commit -m "feat(skills): add using-claude-mind entry skill"
```

---

## Phase 3: Always-on Skills

### Task 3.1: `signal-detector`

**Files:**
- Create: `skills/signal-detector/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
---
name: signal-detector
description: Always-on capture — fires via UserPromptSubmit hook to extract original thinking, decisions, and named entities from each user prompt and append them to the brain
when-to-use: Automatically on every user prompt via the UserPromptSubmit hook; do not invoke manually
---

# Signal Detector

## Purpose

Every user prompt contains signal: an idea worth keeping, a person/company/concept worth tracking, a decision worth recording. Signal-detector captures it asynchronously so the agent can think faster and remember more.

## What counts as signal

- **Original thinking.** A claim, opinion, hypothesis, or framing the user offers ("I think X causes Y because Z").
- **Named entities.** People, companies, projects, libraries, papers — anything with a proper noun.
- **Decisions.** "We're going to do X." "Let's drop Y." "I picked Z because of W."
- **Constraints.** "We can't use X." "Must support Y." "By next Friday."
- **Errors.** Bugs encountered, root causes identified, fixes applied.

## What does NOT count as signal

- Pure tool-use requests ("read foo.ts", "run the tests")
- Conversational filler
- Generic questions with no decision/opinion attached

## Output format

For each detected signal, append a stub entry to the appropriate brain page:

```
- YYYY-MM-DD HH:MM: [signal] <one-line description> (source: <session-id>)
```

If the entity/concept doesn't have a brain page yet, create one with a one-line compiled truth (Tier 3 stub) and the signal entry as the first timeline item.

## Cost & latency contract

- Runs in a subprocess — never blocks the main turn
- Uses `claude-haiku-4-5` by default (overridable via `settings.json:claude-mind.signal_detector_model`)
- Skip silently if the cheap model is unavailable
- Skip if `./brain/` doesn't exist

## Configuration

```json
{
  "claude-mind": {
    "signal_detector_enabled": true,
    "signal_detector_model": "claude-haiku-4-5"
  }
}
```

Set `signal_detector_enabled` to `false` to disable (e.g., for cost-sensitive workflows).
```

- [ ] **Step 2: Run skills test**

```bash
bun test test/skills.test.ts
```

Expected: PASS for `signal-detector`.

- [ ] **Step 3: Commit**

```bash
git add skills/signal-detector/
git commit -m "feat(skills): add signal-detector"
```

---

### Task 3.2: `brain-first`

**Files:**
- Create: `skills/brain-first/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
---
name: brain-first
description: Five-step protocol — before any external lookup, web search, or new file, consult the brain
when-to-use: Before web search, before reading external documentation, before creating a new file, before any "research" task
---

# Brain First

## The protocol

Before reaching for the web, the docs, or a fresh file, run these five steps:

1. **Recall by topic.** `grep -ri "<topic>" ./brain/` — does a brain page already cover this?
2. **Recall by entity.** Does any person/company/library mentioned have an existing page?
3. **Check the journal.** `tail -100 ./brain/_journal.md` — has this come up recently?
4. **Check errors.** `grep -i "<keyword>" ./brain/_errors.log 2>/dev/null` — has this failed before?
5. **Check signals.** `grep -i "<topic>" ./brain/_signals.md 2>/dev/null` — has it been flagged?

Only after all five return empty (or insufficient) do you reach externally.

## Why

External lookups are slow, lossy, and don't compound. Brain lookups are fast, precise, and every hit is one more piece of context the agent didn't have to reload. The brain gets smarter as you use it.

## When you DO go external

After a successful external lookup, write what you learned back to the brain (see `memory-protocol`). The next agent — including future-you — should not have to repeat the search.

## With gbrain installed

If `gbrain` MCP is configured, this skill delegates to `gbrain.search` for hybrid (vector + keyword) retrieval. Same five-step protocol applies; the recall mechanism is just stronger.

## Anti-patterns

- "Let me search the web first" → check the brain first
- "I'll look at the docs" → check the brain first; then docs; then write back
- "I don't think we've done this before" → don't think; check
```

- [ ] **Step 2: Run skills test**

```bash
bun test test/skills.test.ts
```

Expected: PASS for `brain-first`.

- [ ] **Step 3: Commit**

```bash
git add skills/brain-first/
git commit -m "feat(skills): add brain-first"
```

---

## Phase 4: Craft Skills

### Task 4.1: `think-first`

**Files:**
- Create: `skills/think-first/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
---
name: think-first
description: Required <thinking> block before any Edit, Write, or non-trivial Bash; states the critical path and side-effect surface before acting
when-to-use: Before any Edit/Write tool call; before any Bash command that mutates state (rm, mv, git commit, npm publish, etc.)
---

# Think First

## The contract

Before any code-modifying action, produce a `<thinking>` block that answers three questions:

1. **Critical path.** What is the minimum change required?
2. **Side effects.** What else does this affect? Who imports this? What tests cover it?
3. **Smallest version.** Is there a smaller change that meets the requirement?

The PreToolUse hook checks for a recent `<thinking>` block before allowing Edit/Write. It warns (does not block) if absent.

## Format

```
<thinking>
Critical path: <one sentence>
Affects: <files / call sites / tests>
Smallest version: <one sentence>
</thinking>
```

Three lines is enough. This is not a design doc — it's a forcing function.

## When NOT to think-first

- Pure read operations (Read, Grep, Glob)
- Safe shell queries (`ls`, `cat`, `git status`)
- Test runs that don't mutate state

## Why

The think-first gate catches:
- Edits that would touch the wrong file (you noticed mid-thought)
- Refactors disguised as bug fixes (you wrote "smallest version" and realized you were over-reaching)
- Side-effect blind spots (you listed importers and saw a test you'd break)

Most "I need to undo that" moments would have been caught by 30 seconds of typing here.
```

- [ ] **Step 2: Run skills test + commit**

```bash
bun test test/skills.test.ts
git add skills/think-first/
git commit -m "feat(skills): add think-first"
```

---

### Task 4.2: `minimalism`

**Files:**
- Create: `skills/minimalism/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
---
name: minimalism
description: Karpathy-style — code is liability, std lib first, reject-by-default for new dependencies, smallest version that works
when-to-use: When considering a new dependency, when starting a new module/file, when faced with "should I add X feature"
---

# Minimalism

## The default

**No.**

- No new dependency unless the std lib genuinely can't do it
- No new abstraction unless you have ≥3 concrete uses
- No configuration option unless someone has actually asked for it
- No file unless something actually needs to be in it
- No feature unless someone has actually asked for it

When in doubt, don't.

## The rules

### 1. Std lib first

Before reaching for a package, ask: can the standard library do this? Often yes:
- HTTP — `fetch` (built into Node 18+, Bun, browsers); `urllib`/`http.client` (Python)
- JSON — built in everywhere
- File I/O — built in everywhere
- Date math — `Date` / `datetime` are usually enough
- Regex — built in everywhere

If the std lib answer is "ugly but works," prefer ugly to a dep.

### 2. Reject-by-default for new deps

When a dependency seems necessary, add this to the thinking block:

```
Dep evaluation:
- What problem does it solve? <one sentence>
- Std lib alternative cost: <lines of code>
- Maintenance burden: <last commit, # of issues, # of forks>
- Verdict: <add | reject | defer>
```

If the std lib alternative is < 30 lines, write the 30 lines.

### 3. Code is liability

Every line is a line you (or future-you) has to read, understand, debug, secure, and eventually delete. The cost is not "writing it" — the cost is "having it." Bias toward less.

### 4. Smallest version that works

For any feature, ask: "what's v0?" — the version that solves the actual problem with no ergonomics, no error handling beyond happy-path-plus-explicit-failures, no configuration. Build v0 first. Add only when something concrete demands it.

### 5. Delete unused code immediately

If a function/file/module is no longer called, delete it in the same commit that removed the last caller. Don't comment it out. Don't move it to `legacy/`. Delete it.

## Anti-patterns

- "Let me add a config option for that" → no, hardcode the right answer
- "I'll abstract this in case we need it for X" → no, wait until X exists
- "I'll add validation here" → only at system boundaries
- "I'll add error handling for that case" → only if that case actually happens
- "I'll add types for this internal helper" → if it's internal, often no
```

- [ ] **Step 2: Run skills test + commit**

```bash
bun test test/skills.test.ts
git add skills/minimalism/
git commit -m "feat(skills): add minimalism"
```

---

### Task 4.3: `surgical-editing`

**Files:**
- Create: `skills/surgical-editing/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
---
name: surgical-editing
description: Patch don't rewrite — smallest possible diff, named-line edits, no incidental refactoring
when-to-use: Every Edit tool call; whenever modifying existing code
---

# Surgical Editing

## The rule

The diff should contain only what the task requires. Nothing else.

## What "surgical" means

- **Edit, don't rewrite.** Use the Edit tool with old_string/new_string. Don't Write the whole file.
- **Don't reformat lines you didn't change.** If the surrounding code uses tabs and you prefer spaces, keep tabs.
- **Don't rename incidentally.** If a variable is poorly named but works, leave it. Renaming = its own commit.
- **Don't add docstrings/comments to code you didn't change.** They aren't free; they pollute diffs.
- **Don't update unrelated imports.** Even if they're stylistically "wrong."

## When you're tempted to clean up

Ask: "is the cleanup what I was asked to do?"
- Yes → do it
- No → resist; if it really matters, mention it in the response and let the user decide

## Bug fixes don't need cleanup

A bug fix should be the smallest change that fixes the bug. Surrounding code that "could be cleaner" stays. The PR that cleans it up is a separate PR.

## Feature additions don't need refactors

If a feature could be simpler "if we just refactored this first," the right move is usually:
1. Build the feature in the existing structure (ugly but works)
2. Ship
3. Refactor in a separate PR if it still seems worth it later (often it doesn't)

## Anti-patterns

- "While I'm in here, let me also..." → no
- "Let me modernize this real quick" → no
- "This would be cleaner with X pattern" → maybe; not in this commit
- Reformatting a whole file because you changed three lines in it → no
- Adding type annotations to functions you didn't modify → no
```

- [ ] **Step 2: Run skills test + commit**

```bash
bun test test/skills.test.ts
git add skills/surgical-editing/
git commit -m "feat(skills): add surgical-editing"
```

---

## Phase 5: Brain Skill

### Task 5.1: `memory-protocol`

**Files:**
- Create: `skills/memory-protocol/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
---
name: memory-protocol
description: Compiled-truth + timeline brain-page format and placement protocol
when-to-use: When writing to ./brain/, when creating a new brain page, when responding to /remember
---

# Memory Protocol

## The page format

Every brain page has the same shape: **compiled truth above, timeline below.**

```markdown
---
type: concept | person | company | task | decision | error | reference
title: <subject>
tags: [...]
---

<Compiled truth: your current best understanding of this subject. Rewritable.>

---

- YYYY-MM-DD: <evidence entry>
- YYYY-MM-DD: <another entry>
```

Above the second `---`: **compiled truth.** Edit freely as understanding improves.
Below: **timeline.** Append-only. Never edit; only add.

## Where pages live

Decision protocol — the **primary subject** determines the directory, not the format:

- About a person → `./brain/people/<slug>.md`
- About a company → `./brain/companies/<slug>.md`
- About a concept → `./brain/concepts/<slug>.md`
- About a project decision → `./brain/decisions/<slug>.md`
- About a recurring error → `./brain/errors/<slug>.md`
- About an external reference → `./brain/references/<slug>.md`

A meeting with Alice about the cache redesign is not in `meetings/` — it's in `decisions/cache-redesign.md` (with Alice mentioned in the timeline) and `people/alice.md` (with the meeting in her timeline).

## Slug rules

- Lowercase, kebab-case
- No dates (dates go in the timeline)
- No version numbers (those go in the body)
- Singular when possible (`user-auth` not `user-auths`)

## When to create vs. update

- **Create** when no existing page covers the subject (verify via `brain-first` first)
- **Update** the compiled truth when new evidence changes the picture
- **Append** to timeline always; never edit historical entries

## Compiled-truth rewriting

Compiled truth is your *current best model*. When evidence contradicts it:

1. Add the contradicting evidence to the timeline
2. Rewrite the compiled truth to match the new model
3. Don't keep the old version "for reference" — it's in git history if you need it

## With gbrain

If `gbrain` is the storage backend, the file format is identical (gbrain reads markdown), but the agent should also call `gbrain sync` after writes so the retrieval index updates. The Stop hook handles this automatically.
```

- [ ] **Step 2: Run skills test + commit**

```bash
bun test test/skills.test.ts
git add skills/memory-protocol/
git commit -m "feat(skills): add memory-protocol"
```

---

## Phase 6: Toolchain Skills

### Task 6.1: `uv-python`

**Files:**
- Create: `skills/uv-python/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
---
name: uv-python
description: uv-first Python workflow — uv run, uv add, uv sync; no pip install by default
when-to-use: When working in any Python project (pyproject.toml or *.py present)
---

# uv-python

## The defaults

| Need | Use | Don't use |
|---|---|---|
| Run a script | `uv run script.py` | `python script.py` |
| Add a dependency | `uv add <pkg>` | `pip install <pkg>` |
| Add a dev dep | `uv add --dev <pkg>` | `pip install <pkg>` |
| Sync env to lockfile | `uv sync` | `pip install -r requirements.txt` |
| Run tests | `uv run pytest` | `pytest` |
| New project | `uv init` | `mkdir && touch setup.py` |

## Why uv

- ~10–100× faster than pip
- Replaces pip + virtualenv + pip-tools + pyenv with one tool
- Lockfile (`uv.lock`) is reproducible across machines
- Same project shape as pyproject.toml (PEP 621); no lock-in

## Install (once per machine)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Bootstrap on a fresh machine

```bash
cd <repo>
uv sync          # installs from uv.lock
uv run pytest    # everything goes through uv run
```

## When uv isn't installed

If `uv` isn't on PATH:
1. Detect: `command -v uv >/dev/null || ...`
2. Offer to install via the curl one-liner
3. If user declines, fall back to `pip` with a one-line note

Never silently use pip when uv would work.

## Standalone scripts (PEP 723)

For one-off scripts with deps, use uv's inline metadata:

```python
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx"]
# ///

import httpx
print(httpx.get("https://example.com").status_code)
```

Run with `uv run script.py` — no virtualenv setup required.

## Anti-patterns

- `pip install` in a uv project → corrupts the lockfile; use `uv add`
- `python` directly when `uv run python` would use the right env
- Hand-editing `pyproject.toml` deps when `uv add` would update both deps and lock
```

- [ ] **Step 2: Run skills test + commit**

```bash
bun test test/skills.test.ts
git add skills/uv-python/
git commit -m "feat(skills): add uv-python"
```

---

### Task 6.2: `bun-javascript`

**Files:**
- Create: `skills/bun-javascript/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
---
name: bun-javascript
description: bun-first JS/TS workflow — bun as runtime, package manager, bundler, and test runner; no npm install by default
when-to-use: When working in any JS/TS project (package.json or *.ts present)
---

# bun-javascript

## The defaults

| Need | Use | Don't use |
|---|---|---|
| Run a script | `bun run script.ts` | `node script.js`, `ts-node`, `tsx` |
| Install deps | `bun install` | `npm install`, `yarn`, `pnpm install` |
| Add a dep | `bun add <pkg>` | `npm install <pkg>` |
| Add a dev dep | `bun add -D <pkg>` | `npm install -D <pkg>` |
| Run tests | `bun test` | `jest`, `vitest`, `mocha` |
| Build | `bun build` | `webpack`, `esbuild` (directly), `rollup` |
| Init project | `bun init` | `npm init` |

## Why bun

- Native TS execution (no transpile step in dev)
- ~10–30× faster install than npm
- Built-in test runner with the Jest-compatible API
- One binary replaces node + npm + jest + esbuild

## Install (once per machine)

```bash
curl -fsSL https://bun.sh/install | bash
```

## Bootstrap on a fresh machine

```bash
cd <repo>
bun install
bun test
```

## TypeScript

`bun` runs `.ts` files directly. No `tsc` build step needed for dev; use `bun build` (or `tsc --noEmit` for type-only checks) for production builds.

A minimal `tsconfig.json` is enough:

```json
{
  "compilerOptions": {
    "lib": ["ESNext"],
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "types": ["bun-types"]
  }
}
```

## When bun isn't installed

If `bun` isn't on PATH:
1. Detect: `command -v bun >/dev/null || ...`
2. Offer to install via the curl one-liner
3. If user declines, fall back to `npm` with a one-line note

## Anti-patterns

- `npm install` in a bun project → use `bun install`; `package-lock.json` shouldn't be in the repo
- Adding `ts-node` or `tsx` as a dep → bun runs `.ts` natively
- Adding `jest` or `vitest` → use `bun test` unless you genuinely need their features
```

- [ ] **Step 2: Run skills test + commit**

```bash
bun test test/skills.test.ts
git add skills/bun-javascript/
git commit -m "feat(skills): add bun-javascript"
```

---

## Phase 7: Ship Skill

### Task 7.1: `taste`

**Files:**
- Create: `skills/taste/SKILL.md`

- [ ] **Step 1: Write the skill**

```markdown
---
name: taste
description: Ship gate — invoked before any commit, PR, or release; one question, then act
when-to-use: Before `git commit`, `gh pr create`, `npm publish`, version-tag pushes; invoked by /ship command
---

# Taste

## The one question

> *Is this the version you'd be proud to have your name on?*

If yes: ship. Don't gold-plate.
If no: name **the specific thing** that's wrong, fix **only that**, and re-ask.

## What this is NOT

- A code review checklist (those exist elsewhere)
- An invitation to refactor unrelated code
- A reason to add tests for things outside the change
- A "while we're here, let's also..." gate

## What this IS

A 30-second pause before publishing that catches:
- The variable name you knew was wrong but kept
- The error message that says "error" instead of what failed
- The TODO you left in
- The console.log you forgot
- The case the diff doesn't handle but obviously should
- The test that's actually testing the wrong thing

## The flow

1. `/ship` is invoked.
2. Read the diff (`git diff --staged` or `git diff main...HEAD`).
3. Ask the one question.
4. If yes:
   - Print the diff summary
   - Hand off to git/gh — never auto-commit
5. If no:
   - State the **specific** thing wrong (one sentence)
   - Fix that one thing
   - Re-read the diff
   - Re-ask

## Anti-patterns

- Punting decisions ("we can fix it later") — fix it now or note it explicitly in the PR description
- Cleaning up things outside the diff — that's a separate PR
- Adding "more tests" without a specific case — name the case or skip
- Asking the user "should I clean up X?" — decide; they trusted you with `/ship`

## The Tan rule

Ship the version you'd be **proud** of, not the version you'd merely **defend**. Big difference.
```

- [ ] **Step 2: Run skills test (all 10 skills should now pass)**

```bash
bun test test/skills.test.ts
```

Expected: PASS for all 10 skills.

- [ ] **Step 3: Commit**

```bash
git add skills/taste/
git commit -m "feat(skills): add taste — ship gate"
```

---

## Phase 8: Commands

### Task 8.1: `/sc init`

**Files:**
- Create: `commands/sc-init.md`
- Create: `templates/SOUL.md`
- Create: `templates/USER.md`
- Create: `templates/brain-page.md`
- Create: `templates/settings.json`

- [ ] **Step 1: Write the templates**

`templates/SOUL.md`:
```markdown
---
type: identity
title: Agent Soul
tags: [identity, claude-mind]
---

# Agent Soul

The agent's identity, operating principles, and access policies. Edit freely.

## Operating principles

1. **Brain-first** — consult `./brain/` before any external lookup.
2. **Think-first** — produce a `<thinking>` block before file modifications.
3. **Minimalist by default** — reject new deps; smallest version.
4. **Surgical edits** — patch don't rewrite.
5. **Taste before ship** — invoke `/ship` before commit/PR.

## Voice

- Concise, technical, zero-fluff.
- Names tradeoffs explicitly.
- Asks before destructive actions.

---

- 2026-04-15: Soul scaffolded by `/sc init`
```

`templates/USER.md`:
```markdown
---
type: identity
title: User Profile
tags: [identity, user]
---

# User Profile

Your profile as the agent will use it. Edit freely.

## Role

<your role>

## Working style

<how you like to collaborate>

## Active focus

<what you're working on right now>

---

- 2026-04-15: Profile scaffolded by `/sc init`
```

`templates/brain-page.md`:
```markdown
---
type: concept
title: <Title>
tags: []
---

<Compiled truth: your current best understanding. Rewritable.>

---

- YYYY-MM-DD: <first evidence entry>
```

`templates/settings.json`:
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

- [ ] **Step 2: Write the command**

`commands/sc-init.md`:
```markdown
---
name: sc-init
description: Bootstrap ./brain/ in the current repo with SOUL.md, USER.md, settings, and the directory structure
---

# /sc init

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
```

- [ ] **Step 3: Commit**

```bash
git add commands/sc-init.md templates/
git commit -m "feat(commands): /sc init + templates"
```

---

### Task 8.2: `/remember`

**Files:**
- Create: `commands/remember.md`

- [ ] **Step 1: Write the command**

```markdown
---
name: remember
description: Append a compiled-truth note to the appropriate brain page; create the page if needed
arguments: <note>
---

# /remember <note>

Explicit mid-session capture. Use when you want to lock something into memory before the session ends.

## Behavior

1. Parse the note — extract the **subject** (entity, concept, decision).
2. Run `brain-first` to find an existing page for the subject.
3. If a page exists:
   - Append a timeline entry with date + note.
   - If the note materially updates the compiled truth, rewrite it.
4. If no page exists:
   - Determine the page type and directory (per `memory-protocol`).
   - Create the page using `templates/brain-page.md`.
   - Compiled truth = one-sentence summary of the note.
   - Timeline = one entry with the note verbatim.

## Output

Print the path of the page and a one-line summary of what changed:

```
brain/decisions/auth-rewrite.md
+ timeline: 2026-04-15 — Decided to use the new token store; old one had a thread-safety bug
```

## Anti-patterns

- Vague notes ("look into this later") → reject; ask for a concrete subject
- Notes that are really tasks → suggest using a task tracker, not the brain
- Notes that duplicate an existing entry → flag and merge, don't append
```

- [ ] **Step 2: Commit**

```bash
git add commands/remember.md
git commit -m "feat(commands): /remember"
```

---

### Task 8.3: `/recall`

**Files:**
- Create: `commands/recall.md`

- [ ] **Step 1: Write the command**

```markdown
---
name: recall
description: Brain-first lookup before starting a task; surfaces relevant pages
arguments: [query]
---

# /recall [query]

Query the brain before reaching externally.

## Behavior

If `query` is provided:
1. If `gbrain` MCP is available and `gbrain_bridge_enabled: true` → call `gbrain.search` with the query.
2. Else → grep `./brain/` for the query (case-insensitive, with fuzzy matching on the title field).
3. Return up to 5 matches with: title, page type, last-updated date, and the compiled-truth excerpt (first 200 chars).

If `query` is omitted:
1. Print the top-5 most-recently-updated pages.
2. Print pending items from `_signals.md` and `_errors.log` (last 10 of each).

## Output format

```
3 hits for "auth":

1. brain/decisions/auth-rewrite.md (decision, updated 2026-04-15)
   Decided to use the new token store; old one had a thread-safety bug.

2. brain/concepts/jwt-signing.md (concept, updated 2026-03-22)
   We sign with HS256; rotation handled by the secret-mgr cron.

3. brain/people/alice.md (person, updated 2026-02-10)
   Lead on the auth rewrite. Prefers async over Slack.
```

## When the brain is empty

Print: `no brain in this repo — run /sc init to enable` and exit 0.
```

- [ ] **Step 2: Commit**

```bash
git add commands/recall.md
git commit -m "feat(commands): /recall"
```

---

### Task 8.4: `/ship`

**Files:**
- Create: `commands/ship.md`

- [ ] **Step 1: Write the command**

```markdown
---
name: ship
description: Invoke the taste skill on the staged diff, then hand off to git/gh — never auto-commits
---

# /ship

The ship gate. Run before any commit, PR, or release.

## Behavior

1. Determine the diff:
   - If staged changes exist → `git diff --staged`
   - Else if on a branch with upstream → `git diff <upstream>...HEAD`
   - Else → `git diff HEAD` (working tree)
2. Invoke the `taste` skill with the diff as context.
3. The skill answers the one question.
4. If the answer is "yes":
   - Print a one-line summary of what's about to ship
   - Print the exact `git commit` (or `gh pr create`) command for the user to run
   - **Never auto-execute.** The user runs the final command.
5. If the answer is "no":
   - State the specific thing wrong
   - Offer to fix that one thing
   - On user OK → fix → re-run `/ship` recursively

## Why no auto-commit

`/ship` is a thinking gate, not an executor. The user retains the muscle memory of typing `git commit`. This also prevents the failure mode where the gate "passes" something the user wouldn't have shipped.

## Anti-patterns

- Combining `/ship` with `--no-verify` style bypasses → if you need to bypass, you don't need `/ship`
- Running `/ship` after the commit is already pushed → the gate is before, not after
- Treating `/ship` as a code review → see `taste` skill: it's not a checklist
```

- [ ] **Step 2: Commit**

```bash
git add commands/ship.md
git commit -m "feat(commands): /ship"
```

---

## Phase 9: Hooks

### Task 9.1: Synthesis prompt for `stop.sh`

**Files:**
- Create: `hooks/prompts/synthesis.md`

- [ ] **Step 1: Write the synthesis prompt**

```markdown
You are reading a Claude Code session transcript. Extract the deltas worth keeping in long-term memory.

Output a single markdown block in this format — nothing else:

```
## Session synthesis — YYYY-MM-DD HH:MM

### New compiled-truth entries
- <subject>: <one-sentence current best model>

### Timeline entries
- brain/<dir>/<slug>.md: <date> — <evidence>

### Errors encountered
- <one-line summary>: <root cause if known> (file: <path>)

### Decisions
- <decision>: <reason>
```

Rules:
- If a section has nothing, omit the heading.
- Be concrete. "Discussed auth" is not useful; "Switched from JWT to opaque tokens because of revocation requirements" is.
- One line per entry.
- No commentary, no preamble, no closing remarks.
- Do not include code from the transcript.

If the transcript contains no meaningful deltas (e.g., pure read operations), output:

```
## Session synthesis — YYYY-MM-DD HH:MM

(no deltas)
```
```

- [ ] **Step 2: Commit**

```bash
git add hooks/prompts/synthesis.md
git commit -m "feat(hooks): synthesis prompt for stop.sh"
```

---

### Task 9.2: `stop.sh` (TDD — make the red test pass)

**Files:**
- Create: `hooks/stop.sh`

- [ ] **Step 1: Write `stop.sh`**

```bash
#!/usr/bin/env bash
# Claude Mind — Stop hook
# Synthesizes the session transcript into ./brain/_journal.md
# Fails closed: never errors the user's session.

set -uo pipefail

LOG_TO_BRAIN_ERRORS() {
  if [ -d ./brain ]; then
    printf '[%s] stop.sh: %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$1" >> ./brain/_errors.log
  fi
}

# Exit silently if nothing to do
[ -z "${CLAUDE_TRANSCRIPT_PATH:-}" ] && exit 0
[ ! -r "${CLAUDE_TRANSCRIPT_PATH}" ] && exit 0
[ ! -d ./brain ] && exit 0
command -v claude >/dev/null 2>&1 || exit 0

PROMPT_FILE="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}/hooks/prompts/synthesis.md"
[ ! -r "$PROMPT_FILE" ] && {
  LOG_TO_BRAIN_ERRORS "missing synthesis prompt: $PROMPT_FILE"
  exit 0
}

# Run synthesis. Combine prompt + transcript on stdin so we don't need shell-arg juggling.
SYNTHESIS_INPUT="$(cat "$PROMPT_FILE"; printf '\n\n--- TRANSCRIPT ---\n\n'; cat "$CLAUDE_TRANSCRIPT_PATH")"

if ! OUTPUT=$(printf '%s' "$SYNTHESIS_INPUT" | claude -p "Synthesize per the instructions above." 2>/dev/null); then
  LOG_TO_BRAIN_ERRORS "claude CLI failed during synthesis"
  exit 0
fi

printf '\n%s\n' "$OUTPUT" >> ./brain/_journal.md
exit 0
```

- [ ] **Step 2: Make executable**

```bash
chmod +x hooks/stop.sh
```

- [ ] **Step 3: Run hook tests — expect them to pass**

```bash
bun test test/hooks.test.ts
```

Expected: PASS for all three stop.sh test cases.

- [ ] **Step 4: Commit**

```bash
git add hooks/stop.sh
git commit -m "feat(hooks): stop.sh — session synthesis (green)"
```

---

### Task 9.3: `pre-tool-use.sh`

**Files:**
- Create: `hooks/pre-tool-use.sh`
- Modify: `test/hooks.test.ts` — add tests

- [ ] **Step 1: Add failing tests for pre-tool-use.sh**

Append to `test/hooks.test.ts`:

```typescript
describe("pre-tool-use.sh", () => {
  let tmp: string;

  beforeEach(() => {
    tmp = mkdtempSync(join(tmpdir(), "sc-pre-"));
  });

  afterEach(() => {
    rmSync(tmp, { recursive: true, force: true });
  });

  test("warns when tool is Edit and no <thinking> in recent context", () => {
    const transcript = "User: do the thing\nAssistant: ok let me read the file";
    const transcriptFile = join(tmp, "transcript.txt");
    require("node:fs").writeFileSync(transcriptFile, transcript);

    const result = spawnSync("bash", [join(HOOK_DIR, "pre-tool-use.sh")], {
      cwd: tmp,
      env: { ...process.env, CLAUDE_TRANSCRIPT_PATH: transcriptFile, CLAUDE_TOOL_NAME: "Edit" },
    });
    expect(result.status).toBe(0); // never blocks
    expect(result.stderr.toString()).toContain("think-first");
  });

  test("silent when <thinking> present in recent context", () => {
    const transcript = "User: do the thing\nAssistant: <thinking>plan</thinking>\nlet's edit";
    const transcriptFile = join(tmp, "transcript.txt");
    require("node:fs").writeFileSync(transcriptFile, transcript);

    const result = spawnSync("bash", [join(HOOK_DIR, "pre-tool-use.sh")], {
      cwd: tmp,
      env: { ...process.env, CLAUDE_TRANSCRIPT_PATH: transcriptFile, CLAUDE_TOOL_NAME: "Edit" },
    });
    expect(result.status).toBe(0);
    expect(result.stderr.toString()).not.toContain("think-first");
  });

  test("silent for read-only tools", () => {
    const result = spawnSync("bash", [join(HOOK_DIR, "pre-tool-use.sh")], {
      cwd: tmp,
      env: { ...process.env, CLAUDE_TOOL_NAME: "Read" },
    });
    expect(result.status).toBe(0);
    expect(result.stderr.toString()).toBe("");
  });
});
```

- [ ] **Step 2: Run tests — expect failures**

```bash
bun test test/hooks.test.ts
```

Expected: FAIL — `pre-tool-use.sh` doesn't exist.

- [ ] **Step 3: Write `pre-tool-use.sh`**

```bash
#!/usr/bin/env bash
# Claude Mind — PreToolUse hook
# Warns if Edit/Write happens without a recent <thinking> block. Never blocks.

set -uo pipefail

GUARDED_TOOLS="Edit|Write|MultiEdit"
TOOL="${CLAUDE_TOOL_NAME:-}"

# Skip non-mutating tools
[[ ! "$TOOL" =~ ^(${GUARDED_TOOLS})$ ]] && exit 0

# No transcript? Can't check; silent.
[ -z "${CLAUDE_TRANSCRIPT_PATH:-}" ] && exit 0
[ ! -r "${CLAUDE_TRANSCRIPT_PATH}" ] && exit 0

# Look at the last ~50 lines of the transcript for a recent <thinking> block
RECENT=$(tail -n 50 "$CLAUDE_TRANSCRIPT_PATH" 2>/dev/null || true)

if ! grep -q "<thinking>" <<<"$RECENT"; then
  printf 'claude-mind: think-first reminder — no <thinking> block in the last 50 lines before this %s\n' "$TOOL" >&2
fi

exit 0
```

- [ ] **Step 4: Make executable + run tests**

```bash
chmod +x hooks/pre-tool-use.sh
bun test test/hooks.test.ts
```

Expected: PASS for all pre-tool-use.sh tests.

- [ ] **Step 5: Commit**

```bash
git add hooks/pre-tool-use.sh test/hooks.test.ts
git commit -m "feat(hooks): pre-tool-use.sh — think-first reminder"
```

---

### Task 9.4: `user-prompt-submit.sh` + signal-detector prompt

**Files:**
- Create: `hooks/prompts/signal-detector.md`
- Create: `hooks/user-prompt-submit.sh`
- Modify: `test/hooks.test.ts` — add tests

- [ ] **Step 1: Write the signal-detector prompt**

`hooks/prompts/signal-detector.md`:
```markdown
You are processing a single user prompt to extract signal for an agent's long-term memory.

Output ONLY a JSON object on one line, in this exact shape:

{"signals": [{"subject": "<entity-or-concept>", "type": "<person|company|concept|decision|constraint|error>", "summary": "<one-line>"}]}

Rules:
- Up to 5 signals per prompt; pick the highest-value ones.
- subject is the brain page slug (lowercase, kebab-case).
- If the prompt has no signal (pure tool request, conversational filler), output: {"signals": []}
- No commentary outside the JSON. No code fences.
```

- [ ] **Step 2: Add failing tests**

Append to `test/hooks.test.ts`:

```typescript
describe("user-prompt-submit.sh", () => {
  let tmp: string;

  beforeEach(() => {
    tmp = mkdtempSync(join(tmpdir(), "sc-ups-"));
    mkdirSync(join(tmp, "brain"));
  });

  afterEach(() => {
    rmSync(tmp, { recursive: true, force: true });
  });

  test("returns immediately (non-blocking) and spawns subprocess", () => {
    const start = Date.now();
    const result = spawnSync("bash", [join(HOOK_DIR, "user-prompt-submit.sh")], {
      cwd: tmp,
      input: "Let's switch from JWT to opaque tokens",
      env: {
        ...process.env,
        CLAUDE_PLUGIN_ROOT: join(import.meta.dir, ".."),
        PATH: `${join(import.meta.dir, "fixtures", "bin")}:${process.env.PATH}`,
      },
    });
    const elapsed = Date.now() - start;
    expect(result.status).toBe(0);
    expect(elapsed).toBeLessThan(1000); // returns fast; doesn't wait for subprocess
  });

  test("exits 0 silently when ./brain/ missing", () => {
    rmSync(join(tmp, "brain"), { recursive: true });
    const result = spawnSync("bash", [join(HOOK_DIR, "user-prompt-submit.sh")], {
      cwd: tmp,
      input: "anything",
      env: { ...process.env },
    });
    expect(result.status).toBe(0);
  });
});
```

- [ ] **Step 3: Run tests — expect failures**

```bash
bun test test/hooks.test.ts
```

Expected: FAIL — `user-prompt-submit.sh` doesn't exist.

- [ ] **Step 4: Write the hook**

```bash
#!/usr/bin/env bash
# Claude Mind — UserPromptSubmit hook
# Spawns signal-detector subprocess; returns immediately. Never blocks.

set -uo pipefail

# Skip if no brain in this repo
[ ! -d ./brain ] && exit 0

# Skip if signal-detector model unavailable
command -v claude >/dev/null 2>&1 || exit 0

PROMPT_FILE="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}/hooks/prompts/signal-detector.md"
[ ! -r "$PROMPT_FILE" ] && exit 0

# Read user prompt from stdin
USER_PROMPT=$(cat)

# Spawn subprocess; redirect output; disown so this hook returns immediately.
{
  COMBINED="$(cat "$PROMPT_FILE"; printf '\n\n--- USER PROMPT ---\n\n%s\n' "$USER_PROMPT")"
  if SIGNAL_JSON=$(printf '%s' "$COMBINED" | claude -p --model claude-haiku-4-5 "Extract signals." 2>/dev/null); then
    printf '%s | %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$SIGNAL_JSON" >> ./brain/_signals.md
  else
    printf '[%s] signal-detector failed\n' "$(date '+%Y-%m-%dT%H:%M:%S')" >> ./brain/_errors.log
  fi
} >/dev/null 2>&1 &

disown
exit 0
```

- [ ] **Step 5: Make executable + run tests**

```bash
chmod +x hooks/user-prompt-submit.sh
bun test test/hooks.test.ts
```

Expected: PASS for all user-prompt-submit.sh tests.

- [ ] **Step 6: Commit**

```bash
git add hooks/user-prompt-submit.sh hooks/prompts/signal-detector.md test/hooks.test.ts
git commit -m "feat(hooks): user-prompt-submit.sh + signal-detector prompt"
```

---

## Phase 10: Documentation

### Task 10.1: `PHILOSOPHY.md`

**Files:**
- Create: `PHILOSOPHY.md`

- [ ] **Step 1: Write the long-form philosophy doc**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add PHILOSOPHY.md
git commit -m "docs: PHILOSOPHY.md — five-thinker synthesis"
```

---

### Task 10.2: `docs/brain-format.md`

**Files:**
- Create: `docs/brain-format.md`

- [ ] **Step 1: Write the brain-format spec**

```markdown
# Brain Page Format

Every Claude Mind brain page follows the **compiled-truth + timeline** pattern, borrowed from [`garrytan/gbrain`](https://github.com/garrytan/gbrain).

## Structure

```markdown
---
type: <type>
title: <title>
tags: [<tag>, <tag>]
---

<Compiled truth: your current best understanding. Rewritable.>

---

- YYYY-MM-DD: <evidence entry>
- YYYY-MM-DD: <evidence entry>
```

## Frontmatter fields

| Field | Required | Values |
|---|---|---|
| `type` | yes | `concept`, `person`, `company`, `decision`, `task`, `error`, `reference`, `identity` |
| `title` | yes | Human-readable title |
| `tags` | no | Array of lowercase strings |

## Compiled truth (above the second `---`)

- Your **current best model** of the subject.
- Rewritable. Replace freely as understanding improves.
- Length: a few sentences to a few paragraphs.
- Past versions live in git history if you need them.

## Timeline (below the second `---`)

- **Append-only.** Never edit; never reorder.
- One line per entry. Date prefix in `YYYY-MM-DD` format.
- Format: `- YYYY-MM-DD: <evidence>`
- Optional details sub-bullets: `  - <detail>`

## File placement

The **primary subject** determines the directory:

| Subject | Directory |
|---|---|
| Person | `brain/people/` |
| Company | `brain/companies/` |
| Concept | `brain/concepts/` |
| Project decision | `brain/decisions/` |
| Recurring error | `brain/errors/` |
| External reference | `brain/references/` |
| Agent or user identity | `brain/` (root) |

A meeting with Alice about the cache redesign goes in **two** pages: `decisions/cache-redesign.md` and `people/alice.md`. Each page links the other in its compiled truth.

## Slug rules

- Lowercase, kebab-case
- No dates (those go in the timeline)
- No version numbers (those go in the body)
- Singular when possible

## When compiled truth changes

1. Add the contradicting evidence to the timeline
2. Rewrite the compiled truth to match
3. Don't keep the old version "for reference" — it's in git

## Cross-references

Use markdown links between brain pages:

```markdown
Lead on the auth rewrite (see [decisions/auth-rewrite](../decisions/auth-rewrite.md)).
```
```

- [ ] **Step 2: Commit**

```bash
git add docs/brain-format.md
git commit -m "docs: brain-page format spec"
```

---

### Task 10.3: `docs/integrations/gbrain-bridge.md`

**Files:**
- Create: `docs/integrations/gbrain-bridge.md`

- [ ] **Step 1: Write the gbrain bridge doc**

```markdown
# gbrain Bridge

Claude Mind can delegate brain operations to [`garrytan/gbrain`](https://github.com/garrytan/gbrain) when it's installed. The two are complementary: Claude Mind provides the persona/loop/taste; gbrain provides the production-grade brain.

## Enabling the bridge

In your repo's `settings.json` (or via `/sc init` if gbrain was detected):

```json
{
  "claude-mind": {
    "gbrain_bridge_enabled": true
  }
}
```

The bridge requires:
- `gbrain` MCP server registered with Claude Code
- Claude Mind v0.1+

## What changes when the bridge is on

| Without bridge | With bridge |
|---|---|
| `/recall` — greps `./brain/` | `/recall` — calls `gbrain.search` (hybrid vector + keyword) |
| `brain-first` — five-step grep protocol | `brain-first` — gbrain hybrid search + the same five-step protocol as fallback |
| `Stop` hook — appends to `./brain/_journal.md` | `Stop` hook — also calls `gbrain.sync` after appending |
| `/remember` — writes markdown to `./brain/` | `/remember` — writes markdown + calls `gbrain.sync` |

The markdown brain pages remain the source of truth. gbrain reads them.

## When NOT to enable the bridge

- You're working on a one-off project where the brain doesn't matter long-term
- You don't have the time to set up gbrain (~30 minutes per the gbrain README)
- You're cost-sensitive about gbrain's recurring jobs

## Known limitations

- The bridge is one-way: Claude Mind → gbrain. We don't ingest gbrain's voice/email/calendar streams.
- `/sc init` does not install gbrain; you have to do that separately.
- Tested against gbrain commits up through 2026-04-15. Newer gbrain may require bridge updates.
```

- [ ] **Step 2: Commit**

```bash
git add docs/integrations/gbrain-bridge.md
git commit -m "docs: gbrain bridge integration"
```

---

### Task 10.4: `docs/resolver.md`

**Files:**
- Create: `docs/resolver.md`

- [ ] **Step 1: Write the resolver doc**

```markdown
# RESOLVER.md — How Routing Works

`skills/RESOLVER.md` is the single entry point for skill discovery. The agent reads it before any non-trivial task.

## Why a single file

Skills are designed to be discovered by description, but a routing layer makes the priority explicit:

- **Always-on skills** must fire regardless of intent (`signal-detector`, `brain-first`)
- **Gated skills** must fire before specific tools (`think-first` before Edit)
- **Toolchain skills** must fire when their ecosystem is detected (`uv-python` for Python projects)
- **Ship gate** must fire before commit/PR (`taste`)

A flat skill index can't express priority; RESOLVER.md does.

## Format

The file is human-readable markdown with sections grouped by trigger:

```markdown
## Always-on (every turn)
- skill-name — short description

## Before any file modification
- skill-name — when

## Brain operations
- skill-name — when
```

The agent reads top-to-bottom; earlier sections take precedence.

## Adding a new skill

1. Add `skills/<new-skill>/SKILL.md` with valid frontmatter
2. Add a one-line entry under the appropriate section in RESOLVER.md
3. The skills test will fail if RESOLVER.md doesn't reference the new skill

## Borrowed from gbrain

This pattern is lifted directly from gbrain's `skills/RESOLVER.md`. Credit Garry Tan.
```

- [ ] **Step 2: Commit**

```bash
git add docs/resolver.md
git commit -m "docs: resolver routing explanation"
```

---

## Phase 11: CI & Release

### Task 11.1: CI workflow

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Write CI workflow**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Bun
        uses: oven-sh/setup-bun@v1
        with:
          bun-version: latest

      - name: Install deps
        run: bun install --frozen-lockfile

      - name: Lint shell hooks
        run: |
          sudo apt-get update && sudo apt-get install -y shellcheck
          shellcheck hooks/*.sh

      - name: Run tests
        run: bun test

      - name: Verify hooks executable
        run: |
          for h in hooks/*.sh; do
            test -x "$h" || { echo "$h is not executable"; exit 1; }
          done
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: bun tests + shellcheck on PRs"
```

---

### Task 11.2: Release workflow

**Files:**
- Create: `.github/workflows/release.yml`

- [ ] **Step 1: Write release workflow (placeholder publish step)**

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags: ["v*.*.*"]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Verify version matches tag
        run: |
          TAG=${GITHUB_REF#refs/tags/v}
          PKG=$(grep -m1 '"version"' plugin.json | sed -E 's/.*"([^"]+)".*/\1/')
          test "$TAG" = "$PKG" || { echo "tag $TAG != plugin.json version $PKG"; exit 1; }

      - name: Generate release notes from CHANGELOG
        id: notes
        run: |
          TAG=${GITHUB_REF#refs/tags/}
          awk -v tag="$TAG" '
            /^## / { in_section = ($0 ~ tag); next }
            in_section { print }
          ' CHANGELOG.md > /tmp/notes.md
          echo "notes_path=/tmp/notes.md" >> "$GITHUB_OUTPUT"

      - name: Create GitHub release
        uses: softprops/action-gh-release@v1
        with:
          body_path: ${{ steps.notes.outputs.notes_path }}

      # Marketplace publish step:
      # Once Claude Code's marketplace API is documented, add the publish step here.
      # Tracked in TODO: spec §7.1.
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "ci: release workflow on tag push"
```

---

### Task 11.3: Issue templates

**Files:**
- Create: `.github/ISSUE_TEMPLATE/bug.yml`
- Create: `.github/ISSUE_TEMPLATE/feature.yml`

- [ ] **Step 1: Write bug template**

```yaml
# .github/ISSUE_TEMPLATE/bug.yml
name: Bug report
description: Something doesn't work as documented
labels: [bug]
body:
  - type: textarea
    id: what-happened
    attributes:
      label: What happened?
      description: One paragraph. Include the skill/command/hook that misbehaved.
    validations:
      required: true
  - type: textarea
    id: expected
    attributes:
      label: What did you expect?
    validations:
      required: true
  - type: textarea
    id: repro
    attributes:
      label: Minimal reproduction
      description: Steps. Include any relevant `settings.json` keys.
    validations:
      required: true
  - type: input
    id: version
    attributes:
      label: Claude Mind version
    validations:
      required: true
```

- [ ] **Step 2: Write feature template**

```yaml
# .github/ISSUE_TEMPLATE/feature.yml
name: Feature proposal
description: Propose a new skill, command, or hook
labels: [enhancement]
body:
  - type: textarea
    id: problem
    attributes:
      label: What problem does this solve?
    validations:
      required: true
  - type: textarea
    id: proposal
    attributes:
      label: Proposed shape
      description: What's the smallest version that solves the problem?
    validations:
      required: true
  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives considered
      description: Why not just use an existing skill or another plugin?
```

- [ ] **Step 3: Commit**

```bash
git add .github/ISSUE_TEMPLATE/
git commit -m "chore: issue templates"
```

---

## Phase 12: Polish & Ship v0.1.0

### Task 12.1: Final README pass

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace skeleton with real README**

```markdown
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
/sc init        # scaffold ./brain/ and settings
/recall         # check what the brain knows about your topic
/remember <note>  # capture mid-session
/ship           # taste gate before commit/PR
```

## What's inside

**10 skills.** [`signal-detector`](./skills/signal-detector/SKILL.md), [`brain-first`](./skills/brain-first/SKILL.md), [`think-first`](./skills/think-first/SKILL.md), [`minimalism`](./skills/minimalism/SKILL.md), [`surgical-editing`](./skills/surgical-editing/SKILL.md), [`memory-protocol`](./skills/memory-protocol/SKILL.md), [`uv-python`](./skills/uv-python/SKILL.md), [`bun-javascript`](./skills/bun-javascript/SKILL.md), [`taste`](./skills/taste/SKILL.md), [`using-claude-mind`](./skills/using-claude-mind/SKILL.md).

**3 hooks.** UserPromptSubmit (signal capture), PreToolUse (think-first reminder), Stop (session synthesis).

**4 commands.** `/sc init`, `/remember`, `/recall`, `/ship`.

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

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: final README"
```

---

### Task 12.2: `CONTRIBUTING.md` and `CHANGELOG.md`

**Files:**
- Create: `CONTRIBUTING.md`
- Create: `CHANGELOG.md`

- [ ] **Step 1: Write `CONTRIBUTING.md`**

```markdown
# Contributing

Thanks for your interest. Claude Mind is opinionated — read the [PHILOSOPHY.md](./PHILOSOPHY.md) before proposing changes.

## Local setup

```bash
git clone https://github.com/<user>/claude-mind.git
cd claude-mind
bun install
bun test
```

## Adding a skill

1. Read [PHILOSOPHY.md](./PHILOSOPHY.md) to confirm the skill aligns
2. Open a feature issue first; we'll discuss whether the skill earns its place
3. If approved:
   - Add `skills/<name>/SKILL.md` with valid frontmatter
   - Add an entry to `skills/RESOLVER.md`
   - Run `bun test` — the skills test should pass
   - PR with the issue link

## Scope guidelines

We will likely **reject** PRs that:
- Add language-specific skills beyond Python (uv) and JS/TS (bun)
- Add agents (none in v1)
- Bundle MCP servers (we bridge to `gbrain`; we don't ship our own)
- Add features that duplicate `gbrain`'s functionality

We will likely **accept** PRs that:
- Tighten existing skills
- Improve hook robustness or fix edge cases
- Improve cross-platform support (especially native Windows)
- Add tests for things currently covered manually

## Style

- Markdown: 80-col soft wrap; ATX headings; reference-style links for long URLs
- Bash: shellcheck-clean; `set -uo pipefail` (not `-e` in hooks — they fail closed)
- TypeScript: strict mode; no `any`

## Reviews

PRs are reviewed against the [`taste`](./skills/taste/SKILL.md) skill — *"is this the version we'd be proud of?"*
```

- [ ] **Step 2: Write `CHANGELOG.md`**

```markdown
# Changelog

All notable changes to Claude Mind. Hand-written; written for users, not machines.

## v0.1.0 — 2026-04-15

Initial release.

- 10 skills: signal-detector, brain-first, think-first, minimalism, surgical-editing, memory-protocol, uv-python, bun-javascript, taste, using-claude-mind
- 3 hooks: UserPromptSubmit, PreToolUse, Stop
- 4 commands: /sc init, /remember, /recall, /ship
- Compiled-truth + timeline brain page format
- Optional bridge to garrytan/gbrain for hybrid retrieval
- macOS + Linux + WSL supported
```

- [ ] **Step 3: Commit**

```bash
git add CONTRIBUTING.md CHANGELOG.md
git commit -m "docs: CONTRIBUTING and CHANGELOG"
```

---

### Task 12.3: Naming decision

This is a **decision task**, not an implementation task. Per spec §1.2, the working name `claude-mind` collides with `NomenAK/SuperClaude_Framework`.

- [ ] **Step 1: Confirm the final name with the user**

Options to present:
- Keep `claude-mind` (accept collision)
- Rename to one of: `claude-mind`, `synthesis`, `pentad`, `atelier`, `claw`, `minima`, or a user-suggested name

Once decided:

- [ ] **Step 2: If rename, update name everywhere**

```bash
# Replace in all files
NEW="claude-mind"  # or whatever was chosen
git grep -l "claude-mind" | xargs sed -i.bak "s/claude-mind/$NEW/g"
git grep -l "Claude Mind" | xargs sed -i.bak "s/Claude Mind/$(echo $NEW | sed 's/-/ /g' | python3 -c 'import sys; print(sys.stdin.read().title())')/g"
find . -name "*.bak" -delete
mv "$(pwd)" "$(dirname "$(pwd)")/$NEW"
```

Then re-run all tests:

```bash
cd ../$NEW
bun test
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: rename to $NEW (resolves spec §1.2)"
```

---

### Task 12.4: Beta dogfood

- [ ] **Step 1: Install in your own `~/.claude/plugins/`**

```bash
ln -s "$(pwd)" ~/.claude/plugins/claude-mind
```

- [ ] **Step 2: Run `/sc init` in a real project and use Claude Mind for one full session**

Validate the success criteria from spec §10:
1. `./brain/` populated with real entries
2. Smaller-than-baseline diffs (eyeball this)
3. `<thinking>` blocks before non-trivial edits
4. `/ship`'s taste gate catches at least one gold-plating moment
5. Zero hook failures

- [ ] **Step 3: Note observations in CHANGELOG.md or a `docs/dogfood.md`**

If anything breaks: fix it; bump patch version; re-test before tagging.

---

### Task 12.5: Tag and release v0.1.0

- [ ] **Step 1: Create the tag**

```bash
git tag -a v0.1.0 -m "v0.1.0 — initial release"
git push origin v0.1.0
```

- [ ] **Step 2: Verify release workflow ran successfully**

```bash
gh run list --workflow=release.yml
gh release view v0.1.0
```

- [ ] **Step 3: Marketplace submission (manual)**

Follow Claude Code's plugin marketplace submission process. Update `README.md` install instructions with the canonical install command once approved.

- [ ] **Step 4: Final commit**

```bash
git commit --allow-empty -m "release: v0.1.0 published"
git push
```

---

## Plan complete

All 38 tasks across 12 phases. Each task ends with a commit. The repo is publishable when Phase 12 completes.

## Self-Review Notes

- **Spec coverage:** Every section of the spec maps to at least one task:
  - §2.2 plugin layout → Phase 0 + every subsequent phase
  - §3.1 skills (10) → Phases 2–7 (one task per skill)
  - §3.2 hooks (3) → Phase 9 (one task per hook)
  - §3.3 commands (4) → Phase 8
  - §3.4 RESOLVER.md → Task 2.1
  - §3.5 brain format → Task 10.2
  - §3.6 storage tiers → Task 10.3 (gbrain bridge)
  - §3.7 settings → Task 8.1 (templates/settings.json)
  - §4 data flow → covered by hook implementations
  - §5 error handling → covered by hook implementations (`set -uo pipefail`, fail-closed)
  - §6 testing → Phase 1 + 9 (TDD in Phase 9)
  - §7 distribution → Phase 11 + 12.5
  - §10 success criteria → Task 12.4 (dogfood validates)
- **Naming decision** is correctly deferred to Task 12.3 (an explicit task, not a TODO buried in code).
- **Marketplace publish** is correctly noted as manual in Task 12.5 because the marketplace submission process isn't fully scriptable yet.
