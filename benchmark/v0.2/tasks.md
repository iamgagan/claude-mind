# v0.2 task set

Seven tasks, graded toy → realistic → multi-turn. Each task lives at
`benchmark/v0.2/tasks/<id>/` with the same interface as v0.1:
`problem.md`, `starter/` (or a `fetch.sh` that produces one), and a
`test.sh` that exits 0 on pass.

Runtime budgets are upper bounds for a single iteration; the harness
enforces them as `timeout` on the `claude` invocation.

---

## 01-fizzbuzz (carryover control)

- **id**: `01-fizzbuzz`
- **source**: synthetic — copied verbatim from `benchmark/tasks/01-fizzbuzz/`
- **difficulty**: trivial
- **multi-turn**: no
- **success criteria**: `test.sh` asserts output matches the canonical
  fizzbuzz sequence 1..100.
- **runtime budget**: 60 s
- **why**: sanity control. v0.2 numbers must match v0.1 within 1σ or
  the harness changed something.

## 02-bug-fix-surgical (carryover control)

- **id**: `02-bug-fix-surgical`
- **source**: synthetic — copied verbatim from `benchmark/tasks/02-bug-fix-surgical/`
- **difficulty**: easy
- **multi-turn**: no
- **success criteria**: 1-line bug fix lands; `test.sh` asserts the
  targeted assertion passes AND the diff is ≤ 5 lines (new in v0.2:
  test itself enforces surgicality, where v0.1 only measured it).
- **runtime budget**: 90 s

## 03-slugify-issue (realistic, single-shot)

- **id**: `03-slugify-issue`
- **source**: real — `github.com/sindresorhus/slugify` issue #TBD at
  pinned SHA (placeholder: `SHA_TBD_SLUGIFY`). The v0.2 `tasks/03-.../fetch.sh`
  does `git clone --depth=50 && git checkout <SHA>`, then applies a
  failing regression test pulled from the issue's minimal repro.
- **difficulty**: medium
- **multi-turn**: no
- **success criteria**: `npm test` inside the fixture returns 0. The
  regression test added by `fetch.sh` is included and must pass.
- **runtime budget**: 180 s
- **why**: small (< 500 LOC), deterministic, MIT-licensed, and the
  issues are self-contained.

## 04-attrs-bug (realistic, single-shot)

- **id**: `04-attrs-bug`
- **source**: real — `github.com/python-attrs/attrs` issue #TBD at
  pinned SHA (placeholder: `SHA_TBD_ATTRS`).
- **difficulty**: medium-hard
- **multi-turn**: no
- **success criteria**: `pytest tests/test_<module>.py::<new_test>`
  returns 0; no existing test regresses (full suite runs green).
- **runtime budget**: 300 s
- **why**: exercises the "don't touch unrelated code" claim on a
  medium-sized library.

## 05-click-subcommand (realistic, single-shot, bigger)

- **id**: `05-click-subcommand`
- **source**: real — subset of `github.com/pallets/click` at pinned SHA
  (placeholder: `SHA_TBD_CLICK`). `fetch.sh` copies only
  `src/click/core.py`, `src/click/decorators.py`, and their tests into
  the starter so context fits.
- **difficulty**: hard
- **multi-turn**: no
- **success criteria**: new subcommand behavior implemented; targeted
  tests pass; rest of click's test suite on the copied subset stays
  green.
- **runtime budget**: 420 s
- **why**: stress-tests the "smaller diff" claim on a task big enough
  that a model might over-edit.

## 06-multi-turn-feature (multi-turn)

- **id**: `06-multi-turn-feature`
- **source**: synthetic — Python module with a stubbed API and a
  deliberately missing feature (e.g. add caching to a function with
  tests covering expected cache hits).
- **difficulty**: medium
- **multi-turn**: **yes — 4 turns (scope / plan / implement / review)**
- **success criteria**: at end of turn 3, `pytest` exits 0. At end of
  turn 4, the review output mentions at least one specific
  follow-up; harness greps for non-empty review content.
- **runtime budget**: 600 s for the full 4-turn session
- **why**: minimum honest test of whether multi-turn state (session
  resume, hook-driven signal capture) changes behavior.

## 07-multi-turn-debugging (multi-turn, real-ish)

- **id**: `07-multi-turn-debugging`
- **source**: semi-synthetic — a small Flask-ish app with a bug that
  only surfaces via the test suite; turn 1 is "reproduce", turn 2 is
  "diagnose", turn 3 is "fix", turn 4 is "write a regression test".
- **difficulty**: hard
- **multi-turn**: **yes — 4 turns**
- **success criteria**: turn 3 makes the original failing test pass;
  turn 4 adds a new test covering the fix that also passes; diff to
  non-test files ≤ 15 lines.
- **runtime budget**: 900 s
- **why**: the closest thing in v0.2 to the "long session" scenario
  the plugin is actually designed for.

---

## Runtime totals

With n = 10 per (task × mode):

| Task | Budget | × 20 runs | Total |
|---|---|---|---|
| 01-fizzbuzz | 60 s | 20 | 20 min |
| 02-bug-fix-surgical | 90 s | 20 | 30 min |
| 03-slugify-issue | 180 s | 20 | 60 min |
| 04-attrs-bug | 300 s | 20 | 100 min |
| 05-click-subcommand | 420 s | 20 | 140 min |
| 06-multi-turn-feature | 600 s | 20 | 200 min |
| 07-multi-turn-debugging | 900 s | 20 | 300 min |
| **Total** |  |  | **~14 hours** |

So a full v0.2 sweep is an overnight run, not a coffee break. The
runner supports `--task` filters so partial sweeps are cheap.

## Pinned SHAs (to fill in before first run)

- `SHA_TBD_SLUGIFY` — resolve before 03-slugify-issue is promoted out of scaffold.
- `SHA_TBD_ATTRS` — same for 04-attrs-bug.
- `SHA_TBD_CLICK` — same for 05-click-subcommand.

These belong in `benchmark/v0.2/tasks/<id>/fetch.sh` as a constant so
the fixture state is reproducible across runs.
