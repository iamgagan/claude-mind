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
