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
