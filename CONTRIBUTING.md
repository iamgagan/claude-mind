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
