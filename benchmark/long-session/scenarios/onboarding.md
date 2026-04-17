# Scenario: New contributor onboarding

**Persona.** A first-week engineer has been handed a small internal service
(`./fixture-repo/`) and told to "get familiar, then fix the flaky test and
add a small feature." They work through it over one sitting, asking the
agent for help as they go.

**Turns:** 15
**Fixture:** `./fixture-repo/` (TODO: create; a small Python/TS service with
a README, a couple of modules, and at least one flaky test)
**Repeated-question probe:** Turn 3 and Turn 13 ask the same factual
question about the codebase. Plugin run should answer Turn 13 faster via
`brain-first`; baseline should not.

---

### Turn 1
**Prompt:** `What's in this repo? Give me a one-paragraph summary of what this service does and its main modules.`
**Assert:** agent reads `README.md` and lists top-level modules. On plugin run, expect a `brain/concepts/<repo-name>.md` or similar page to be written by the Stop synthesis.

### Turn 2
**Prompt:** `Which file owns the HTTP routing? Point me at the function that dispatches requests.`
**Assert:** agent names a specific file and function. Plugin run: expect a mention of this routing entrypoint in `_signals.md` or a new `concepts/routing.md` page after Stop.

### Turn 3
**Prompt:** `What database does this service use, and where is the connection configured?`
**Assert:** agent identifies the DB (e.g. Postgres) and the config location. **This is the probe question; we ask it again at Turn 13.** Plugin run: expect `brain/concepts/database.md` (or similar) after Stop.

### Turn 4
**Prompt:** `Run the test suite and tell me which tests are failing or flaky.`
**Assert:** agent runs `pytest`/`npm test`, reports failing test names. Plugin run: expect a `brain/errors/<test-name>.md` page capturing the failure signature.

### Turn 5
**Prompt:** `Look at the flaky test. What's the actual root cause — is it a real bug or a test-isolation issue?`
**Assert:** agent analyzes and classifies (e.g. "shared fixture state between tests"). Plugin run: expect the `errors/` page updated with a diagnosis in compiled truth.

### Turn 6
**Prompt:** `Before you fix it — have we seen anything like this in the brain before?`
**Assert:** **brain-first probe.** Plugin run: agent `grep`s `./brain/` and reports on `_errors.log` / `errors/` hits. Baseline run: no brain to consult; agent either hallucinates or says no.

### Turn 7
**Prompt:** `Fix the flaky test with the smallest possible change. Don't refactor anything else.`
**Assert:** agent produces a diff localized to one file. Plugin run: `surgical-editing` skill should be loaded; expect diff ≤ baseline diff.

### Turn 8
**Prompt:** `Now show me the commit message you'd use for this fix. Keep it tight.`
**Assert:** agent produces a single-paragraph message referencing the test name and root cause. No tool calls expected.

### Turn 9
**Prompt:** `The ticket also asks for a new endpoint: GET /health that returns {"status":"ok"} and the git SHA. Where should this go?`
**Assert:** agent references the routing file from Turn 2 — **ideally from the brain, not by re-reading the file.** Plugin run: expect a brain-first consult (grep for "routing" / "dispatch").

### Turn 10
**Prompt:** `Implement it. Include a test. Follow the style of the existing endpoints.`
**Assert:** agent writes endpoint + test. Plugin run: `minimalism` and `surgical-editing` skills should keep it tight; expect no unrelated changes.

### Turn 11
**Prompt:** `Run the tests again and make sure everything's green.`
**Assert:** agent runs the suite, reports pass. If fail, expect a targeted fix not a rewrite.

### Turn 12
**Prompt:** `Summarize what we did today in three bullets — fix, feature, and anything I should remember for next time.`
**Assert:** agent produces three bullets. Plugin run: expect Stop synthesis to write a `decisions/` or session page capturing the day.

### Turn 13
**Prompt:** `Quick check — remind me what database this service uses and where the connection is configured?`
**Assert:** **Repeat of Turn 3.** Plugin run: agent should answer from `brain/concepts/database.md` (no file reads); **latency should be noticeably lower than Turn 3**. Baseline run: agent either re-reads the config or hallucinates; latency similar to Turn 3.

### Turn 14
**Prompt:** `If I came back to this repo in a month, what's the one page in the brain I should re-read first?`
**Assert:** Plugin run: agent names an actual page under `./brain/` that exists. Baseline run: this question is nonsensical; agent should say there is no brain.

### Turn 15
**Prompt:** `Wrap up. Anything flaky, half-done, or surprising we should flag before I log off?`
**Assert:** agent surfaces remaining risks. Plugin run: expect the signals/journal to contain entries corresponding to each risk mentioned.

---

## Notes for the grader

- The **repeated-question probe (Turn 3 / Turn 13)** is the single cleanest
  signal: same prompt, different brain state, compare latencies and whether
  the plugin run cites a brain page.
- Turn 6 explicitly invokes brain-first. If the agent in plugin mode does
  not grep `./brain/` on this turn, the `brain-first` skill is not wired.
- Turn 14 is a trap for baseline: it should be unanswerable without a brain.
