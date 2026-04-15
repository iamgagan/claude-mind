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
