# Scenario file format

A scenario is a single markdown file describing a scripted multi-turn
conversation. `run.sh` reads it, extracts the turns in order, and replays
them against `claude -p` (see `../README.md`).

## Structure

```markdown
# Scenario: <short title>

<free-form preamble: persona, fixture path, turn count, probe notes>

---

### Turn 1
**Prompt:** `<literal user prompt, in backticks>`
**Assert:** <what we expect; free-form; consumed by the grader, not the runner>

### Turn 2
**Prompt:** `<prompt>`
**Assert:** <expectation>

...
```

## Rules

- Exactly one `### Turn N` heading per turn, numbered from 1.
- Exactly one `**Prompt:**` line per turn, with the prompt wrapped in
  single backticks. The runner extracts the text inside the backticks
  verbatim — no substitutions. Keep prompts on one line.
- `**Assert:**` is free-form prose. It is **not** executed. It is read by
  the LLM-as-judge grader (TODO) and by humans reviewing transcripts.
- Preamble and trailing notes are ignored by the runner.

## Conventions

- Reference the fixture repo as `./fixture-repo/` so scenarios are
  relocatable.
- If your scenario needs a **repeated-question probe**, ask the identical
  question at two well-separated turns and call it out in the preamble.
- Keep scenarios 10–15 turns. Shorter does not exercise compounding;
  longer is hard to run reproducibly.

## Adding a scenario

1. Write `scenarios/<name>.md` following the format above.
2. If the scenario needs a new fixture, add it under
   `benchmark/long-session/fixture-repo/` (TODO: path may move).
3. Smoke-test with `./run.sh --scenario <name> --dry-run` (TODO flag).
