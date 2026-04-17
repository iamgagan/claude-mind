#!/usr/bin/env bash
# claude-mind benchmark v0.2 runner — SCAFFOLD.
#
# This is a scaffold. Core metric capture is stubbed with `# TODO(v0.2):`
# markers. Do not use the numbers this emits to make decisions yet.
#
# Usage:
#   ./benchmark/v0.2/run.sh --task <task-id> --mode <baseline|plugin> \
#                           [--iter N] [--multi-turn]
#
# Differences from v0.1 (`benchmark/run.sh`):
#   - --iter loops N runs in a single invocation (default 10).
#   - --multi-turn drives a 4-turn session (scope/plan/implement/review)
#     via the Agent SDK; one-shot otherwise.
#   - Results land under benchmark/results/v0.2/ to keep v0.1 aggregation
#     untouched, and carry a richer JSON schema (token_usage, tool_calls,
#     files_touched, thinking_block_count, hook_invocations).
#
# v0.2 itself does not implement every metric yet. Each stub is a
# TODO(v0.2): so a follow-up PR knows exactly what's left.

set -euo pipefail

# --- locate ourselves ---------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
V01_RUNNER="$REPO_ROOT/benchmark/run.sh"
TASKS_DIR_V02="$SCRIPT_DIR/tasks"
TASKS_DIR_V01="$REPO_ROOT/benchmark/tasks"
RESULTS_DIR="$REPO_ROOT/benchmark/results/v0.2"
TMP_ROOT="$REPO_ROOT/benchmark/.tmp/v0.2"

mkdir -p "$RESULTS_DIR" "$TMP_ROOT"

# --- arg parsing --------------------------------------------------------------
MODE=""
TASK=""
ITER=10
MULTI_TURN=0

usage() {
  cat >&2 <<'EOF'
Usage: run.sh --task <task-id> --mode <baseline|plugin> [--iter N] [--multi-turn]

  --task         Task id under benchmark/v0.2/tasks/ (or benchmark/tasks/
                 for v0.1 carryovers). Required.
  --mode         'baseline' or 'plugin'. Required.
  --iter N       Number of iterations per (task, mode). Default: 10.
  --multi-turn   Drive a 4-turn SDK session instead of one-shot claude -p.
  -h, --help     This help.
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task)
      TASK="${2:-}"
      shift 2
      ;;
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --iter)
      ITER="${2:-}"
      shift 2
      ;;
    --multi-turn)
      MULTI_TURN=1
      shift 1
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      ;;
  esac
done

if [[ -z "$TASK" || -z "$MODE" ]]; then
  usage
fi
if [[ "$MODE" != "baseline" && "$MODE" != "plugin" ]]; then
  echo "--mode must be 'baseline' or 'plugin' (got: $MODE)" >&2
  exit 2
fi
if ! [[ "$ITER" =~ ^[0-9]+$ ]] || [[ "$ITER" -lt 1 ]]; then
  echo "--iter must be a positive integer (got: $ITER)" >&2
  exit 2
fi

# --- prerequisites ------------------------------------------------------------
if ! command -v claude >/dev/null 2>&1; then
  echo "ERROR: 'claude' CLI not found on PATH" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: v0.2 harness requires jq (emits richer JSON than v0.1)" >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: v0.2 harness requires python3" >&2
  exit 1
fi

# Resolve task directory: prefer v0.2, fall back to v0.1 carryover.
TASK_DIR=""
if [[ -d "$TASKS_DIR_V02/$TASK" ]]; then
  TASK_DIR="$TASKS_DIR_V02/$TASK"
elif [[ -d "$TASKS_DIR_V01/$TASK" ]]; then
  TASK_DIR="$TASKS_DIR_V01/$TASK"
else
  echo "ERROR: task '$TASK' not found under $TASKS_DIR_V02 or $TASKS_DIR_V01" >&2
  exit 1
fi

# --- helpers ------------------------------------------------------------------

now_iso() {
  date -u +'%Y-%m-%dT%H:%M:%SZ'
}

now_compact() {
  date -u +'%Y%m%dT%H%M%SZ'
}

# Parse claude JSON output for metrics. TODO(v0.2) stubs below.
# Each returns a plain integer (or 0) on stdout. They all accept the
# path to a JSON stream file as $1.
parse_token_usage() {
  # TODO(v0.2): claude -p --output-format json emits a stream of events;
  # sum input_tokens + output_tokens + cache_read_input_tokens +
  # cache_creation_input_tokens across message events. For now, emit 0
  # so the JSON stays well-formed.
  # Expected final shape: {"input":N,"output":N,"cache_read":N,"cache_write":N}
  local _json="${1:-}"
  echo '{"input":0,"output":0,"cache_read":0,"cache_write":0}'
}

parse_tool_call_count() {
  # TODO(v0.2): count tool_use blocks in JSON output. Placeholder 0.
  local _json="${1:-}"
  echo 0
}

parse_thinking_block_count() {
  # TODO(v0.2): count thinking blocks in JSON output. Placeholder 0.
  local _json="${1:-}"
  echo 0
}

count_files_touched() {
  # Count distinct files that differ between starter and work dir.
  local starter="$1"
  local work="$2"
  local n=0
  set +e +o pipefail
  n="$(
    diff -ruN \
      --exclude='.claude-stdout.log' \
      --exclude='.claude-stderr.log' \
      --exclude='.claude-stream.json' \
      --exclude='.test.sh' \
      --exclude='.test-output.log' \
      "$starter" "$work" 2>/dev/null \
      | grep -E '^(\+\+\+|---) ' \
      | awk '{print $2}' \
      | grep -v '^/dev/null$' \
      | sort -u \
      | wc -l \
      | tr -d ' '
  )"
  set -e -o pipefail
  if [[ -z "$n" ]]; then
    n=0
  fi
  echo "$n"
}

count_diff_lines() {
  local starter="$1"
  local work="$2"
  local n=0
  set +e +o pipefail
  n="$(
    diff -ruN \
      --exclude='.claude-stdout.log' \
      --exclude='.claude-stderr.log' \
      --exclude='.claude-stream.json' \
      --exclude='.test.sh' \
      --exclude='.test-output.log' \
      "$starter" "$work" 2>/dev/null \
      | grep -E '^[+-]' \
      | grep -vE '^(\+\+\+|---)' \
      | wc -l \
      | tr -d ' '
  )"
  set -e -o pipefail
  if [[ -z "$n" ]]; then
    n=0
  fi
  echo "$n"
}

snapshot_brain_lines() {
  # Snapshot wc -l of brain/_journal.md and brain/_signals.md so we can
  # detect whether hooks wrote anything during the run. Missing files
  # count as 0. Emits "<journal>,<signals>".
  local brain_dir="$REPO_ROOT/brain"
  local j=0 s=0
  if [[ -f "$brain_dir/_journal.md" ]]; then
    j="$(wc -l < "$brain_dir/_journal.md" | tr -d ' ')"
  fi
  if [[ -f "$brain_dir/_signals.md" ]]; then
    s="$(wc -l < "$brain_dir/_signals.md" | tr -d ' ')"
  fi
  echo "${j},${s}"
}

# --- single iteration ---------------------------------------------------------

# Runs one iteration of the task and writes a result JSON. Returns 0 on
# successful harness execution (NOT on test pass).
run_one_iter() {
  local iter_idx="$1"

  local prompt_file="$TASK_DIR/problem.md"
  local starter_dir="$TASK_DIR/starter"
  local test_script="$TASK_DIR/test.sh"

  if [[ ! -f "$prompt_file" || ! -d "$starter_dir" || ! -x "$test_script" ]]; then
    echo "SKIP $TASK iter=$iter_idx (missing problem.md / starter/ / executable test.sh)" >&2
    return 0
  fi

  local work_dir="$TMP_ROOT/${TASK}-${MODE}-${iter_idx}"
  rm -rf "$work_dir"
  mkdir -p "$work_dir"
  cp -R "$starter_dir/." "$work_dir/"

  local prompt
  prompt="$(cat "$prompt_file")"

  local stream_json="$work_dir/.claude-stream.json"
  local brain_before brain_after
  brain_before="$(snapshot_brain_lines)"

  local start_ts end_ts duration exit_code=0
  start_ts="$(python3 -c 'import time; print(time.time())')"

  if [[ "$MULTI_TURN" -eq 1 ]]; then
    # TODO(v0.2): drive a 4-turn SDK session (scope / plan / implement /
    # review). For now, fall through to one-shot so the scaffold runs
    # end-to-end without the SDK bindings being present.
    #
    # Sketch:
    #   python3 "$SCRIPT_DIR/multi_turn_driver.py" \
    #     --work-dir "$work_dir" \
    #     --task "$TASK" \
    #     --turns scope,plan,implement,review \
    #     --out-json "$stream_json"
    echo "WARN multi-turn not yet implemented; running one-shot (TODO v0.2)" >&2
  fi

  set +e
  (
    cd "$work_dir" && claude \
      -p "$prompt" \
      --permission-mode acceptEdits \
      --output-format json \
      >"$stream_json" \
      2>"$work_dir/.claude-stderr.log"
  )
  exit_code=$?
  set -e

  end_ts="$(python3 -c 'import time; print(time.time())')"
  duration="$(python3 -c "print(f'{${end_ts} - ${start_ts}:.1f}')")"

  brain_after="$(snapshot_brain_lines)"

  # --- run test.sh against the work dir ---
  local test_in_work="$work_dir/.test.sh"
  cp "$test_script" "$test_in_work"
  chmod +x "$test_in_work"

  local test_passed_bool="false"
  local test_log="$work_dir/.test-output.log"
  set +e
  "$test_in_work" >"$test_log" 2>&1
  local test_rc=$?
  set -e
  if [[ $test_rc -eq 0 ]]; then
    test_passed_bool="true"
  fi

  # --- collect metrics ---
  local diff_lines files_touched token_usage_json tool_calls thinking_blocks
  diff_lines="$(count_diff_lines "$starter_dir" "$work_dir")"
  files_touched="$(count_files_touched "$starter_dir" "$work_dir")"
  token_usage_json="$(parse_token_usage "$stream_json")"
  tool_calls="$(parse_tool_call_count "$stream_json")"
  thinking_blocks="$(parse_thinking_block_count "$stream_json")"

  # Brain snapshot diff (lines added during this run).
  local j_before s_before j_after s_after j_delta s_delta
  IFS=',' read -r j_before s_before <<< "$brain_before"
  IFS=',' read -r j_after  s_after  <<< "$brain_after"
  j_delta=$((j_after - j_before))
  s_delta=$((s_after - s_before))

  # --- record ---
  local timestamp run_id result_file notes=""
  timestamp="$(now_iso)"
  run_id="$(now_compact)-${iter_idx}"
  result_file="$RESULTS_DIR/${TASK}-${MODE}-${run_id}.json"

  if [[ $exit_code -ne 0 ]]; then
    notes="claude exited non-zero; see $work_dir/.claude-stderr.log"
  fi

  jq -n \
    --arg task_id "$TASK" \
    --arg mode "$MODE" \
    --arg timestamp "$timestamp" \
    --arg harness_version "v0.2" \
    --argjson iter "$iter_idx" \
    --argjson multi_turn "$MULTI_TURN" \
    --argjson duration_seconds "$duration" \
    --argjson claude_exit_code "$exit_code" \
    --argjson test_passed "$test_passed_bool" \
    --argjson diff_lines "$diff_lines" \
    --argjson files_touched "$files_touched" \
    --argjson tool_call_count "$tool_calls" \
    --argjson thinking_block_count "$thinking_blocks" \
    --argjson journal_lines_added "$j_delta" \
    --argjson signals_lines_added "$s_delta" \
    --argjson token_usage "$token_usage_json" \
    --arg notes "$notes" \
    '{
      task_id: $task_id,
      mode: $mode,
      harness_version: $harness_version,
      timestamp: $timestamp,
      iter: $iter,
      multi_turn: ($multi_turn == 1),
      duration_seconds: $duration_seconds,
      claude_exit_code: $claude_exit_code,
      test_passed: $test_passed,
      diff_lines: $diff_lines,
      files_touched: $files_touched,
      tool_call_count: $tool_call_count,
      thinking_block_count: $thinking_block_count,
      hook_invocations: {
        journal_lines_added: $journal_lines_added,
        signals_lines_added: $signals_lines_added
      },
      token_usage: $token_usage,
      notes: $notes
    }' \
    > "$result_file"

  local pass_marker="FAIL"
  if [[ "$test_passed_bool" == "true" ]]; then
    pass_marker="PASS"
  fi
  printf '%-28s mode=%-8s iter=%2d/%-2d %s  dur=%6ss  diff=%4s  files=%3s  exit=%d\n' \
    "$TASK" "$MODE" "$iter_idx" "$ITER" "$pass_marker" "$duration" "$diff_lines" "$files_touched" "$exit_code"
}

# --- main loop ----------------------------------------------------------------

echo "v0.2 run: task=$TASK mode=$MODE iter=$ITER multi_turn=$MULTI_TURN"
echo "results -> $RESULTS_DIR"

for i in $(seq 1 "$ITER"); do
  run_one_iter "$i"
done

echo "done. $ITER iteration(s) recorded under $RESULTS_DIR"

# TODO(v0.2): wire `benchmark/v0.2/report.sh` to read $RESULTS_DIR.
# TODO(v0.2): implement --multi-turn via Agent SDK driver.
# TODO(v0.2): implement token/tool/thinking parsing from JSON stream.
# TODO(v0.2): optionally call into "$V01_RUNNER" for direct carryover
#             tasks instead of re-implementing the one-shot path here.
:
