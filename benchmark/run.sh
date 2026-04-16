#!/usr/bin/env bash
# Benchmark runner for claude-mind.
#
# Usage:
#   ./benchmark/run.sh --mode <baseline|plugin> [--task <task-id>]
#
# Runs each task by spinning up an isolated copy of its starter/ directory
# under benchmark/.tmp/, invoking `claude -p` non-interactively against it,
# then running the task's test.sh and recording a JSON result file in
# benchmark/results/.
#
# This script does not enable or disable the claude-mind plugin — that is
# the operator's responsibility (see benchmark/README.md).

set -euo pipefail

# --- locate ourselves ---------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASKS_DIR="$SCRIPT_DIR/tasks"
RESULTS_DIR="$SCRIPT_DIR/results"
TMP_ROOT="$SCRIPT_DIR/.tmp"

mkdir -p "$RESULTS_DIR" "$TMP_ROOT"

# --- arg parsing --------------------------------------------------------------
MODE=""
TASK_FILTER=""

usage() {
  echo "Usage: $0 --mode <baseline|plugin> [--task <task-id>]" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --task)
      TASK_FILTER="${2:-}"
      shift 2
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

if [[ -z "$MODE" ]]; then
  usage
fi
if [[ "$MODE" != "baseline" && "$MODE" != "plugin" ]]; then
  echo "--mode must be 'baseline' or 'plugin' (got: $MODE)" >&2
  exit 2
fi

# --- prerequisites ------------------------------------------------------------
if ! command -v claude >/dev/null 2>&1; then
  echo "ERROR: 'claude' CLI not found on PATH" >&2
  exit 1
fi

HAVE_JQ=0
if command -v jq >/dev/null 2>&1; then
  HAVE_JQ=1
fi

# --- helpers ------------------------------------------------------------------

# Compose a JSON object. If jq is available, use it for proper escaping;
# otherwise hand-format and rely on the values being shell-safe (they are
# constructed by us from numbers, booleans, fixed strings, and short ids).
emit_json() {
  local task_id="$1"
  local mode="$2"
  local timestamp="$3"
  local duration_seconds="$4"
  local exit_code="$5"
  local test_passed="$6"
  local diff_lines="$7"
  local notes="$8"
  if [[ "$HAVE_JQ" -eq 1 ]]; then
    jq -n \
      --arg task_id "$task_id" \
      --arg mode "$mode" \
      --arg timestamp "$timestamp" \
      --argjson duration_seconds "$duration_seconds" \
      --argjson exit_code "$exit_code" \
      --argjson test_passed "$test_passed" \
      --argjson diff_lines "$diff_lines" \
      --arg notes "$notes" \
      '{task_id: $task_id, mode: $mode, timestamp: $timestamp, duration_seconds: $duration_seconds, claude_exit_code: $exit_code, test_passed: $test_passed, diff_lines: $diff_lines, notes: $notes}'
  else
    cat <<EOF
{
  "task_id": "$task_id",
  "mode": "$mode",
  "timestamp": "$timestamp",
  "duration_seconds": $duration_seconds,
  "claude_exit_code": $exit_code,
  "test_passed": $test_passed,
  "diff_lines": $diff_lines,
  "notes": "$notes"
}
EOF
  fi
}

# Compute a duration in seconds with one decimal place. Uses python3 because
# `date +%s.%N` and `bc` are not portable across BSD/GNU.
duration_seconds() {
  local start="$1"
  local end="$2"
  python3 -c "print(f'{${end} - ${start}:.1f}')"
}

# --- task runner --------------------------------------------------------------

run_task() {
  local task_id="$1"
  local task_dir="$TASKS_DIR/$task_id"
  local prompt_file="$task_dir/problem.md"
  local starter_dir="$task_dir/starter"
  local test_script="$task_dir/test.sh"

  if [[ ! -f "$prompt_file" || ! -d "$starter_dir" || ! -x "$test_script" ]]; then
    echo "SKIP $task_id (missing problem.md / starter/ / executable test.sh)" >&2
    return
  fi

  local work_dir="$TMP_ROOT/${task_id}-${MODE}"
  rm -rf "$work_dir"
  mkdir -p "$work_dir"
  # Copy starter contents (not the directory itself) into the work dir.
  cp -R "$starter_dir/." "$work_dir/"

  local prompt
  prompt="$(cat "$prompt_file")"

  # --- invoke claude ---
  local start_ts end_ts duration exit_code=0
  start_ts="$(python3 -c 'import time; print(time.time())')"

  # Run claude non-interactively from inside the work dir so all relative
  # paths resolve inside the sandbox copy. We allow common edit/read tools
  # explicitly so --print mode does not block on permission prompts.
  set +e
  ( cd "$work_dir" && claude \
      -p "$prompt" \
      --permission-mode acceptEdits \
      --output-format text \
      >"$work_dir/.claude-stdout.log" \
      2>"$work_dir/.claude-stderr.log"
  )
  exit_code=$?
  set -e

  end_ts="$(python3 -c 'import time; print(time.time())')"
  duration="$(duration_seconds "$start_ts" "$end_ts")"

  # --- run test.sh against the work dir ---
  # We copy test.sh into the work dir so that its `cd "$(dirname "$0")"`
  # resolves to the agent's solution rather than the original starter.
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

  # --- diff size ---
  # Count changed lines (added + removed) between starter and final work dir,
  # ignoring our own scratch files. Note: `diff` returns 1 when files differ
  # (not an error), and `grep` returns 1 when nothing matches (also not an
  # error here) — so we shield this whole pipeline from `set -o pipefail`.
  local diff_lines=0
  set +e +o pipefail
  diff_lines="$(
    diff -ruN \
      --exclude='.claude-stdout.log' \
      --exclude='.claude-stderr.log' \
      --exclude='.test.sh' \
      --exclude='.test-output.log' \
      "$starter_dir" "$work_dir" 2>/dev/null \
      | grep -E '^[+-]' \
      | grep -vE '^(\+\+\+|---)' \
      | wc -l \
      | tr -d ' '
  )"
  set -e -o pipefail
  if [[ -z "$diff_lines" ]]; then
    diff_lines=0
  fi

  # --- record ---
  local timestamp run_id result_file notes=""
  timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  run_id="$(date -u +'%Y%m%dT%H%M%SZ')"
  result_file="$RESULTS_DIR/${task_id}-${MODE}-${run_id}.json"

  if [[ $exit_code -ne 0 ]]; then
    notes="claude exited non-zero; see $work_dir/.claude-stderr.log"
  fi

  emit_json \
    "$task_id" \
    "$MODE" \
    "$timestamp" \
    "$duration" \
    "$exit_code" \
    "$test_passed_bool" \
    "$diff_lines" \
    "$notes" \
    > "$result_file"

  # --- one-line summary ---
  local pass_marker="FAIL"
  if [[ "$test_passed_bool" == "true" ]]; then
    pass_marker="PASS"
  fi
  printf '%-28s mode=%-8s %s  duration=%6ss  diff=%4s  claude_exit=%d\n' \
    "$task_id" "$MODE" "$pass_marker" "$duration" "$diff_lines" "$exit_code"
}

# --- main loop ----------------------------------------------------------------

if [[ -n "$TASK_FILTER" ]]; then
  if [[ ! -d "$TASKS_DIR/$TASK_FILTER" ]]; then
    echo "ERROR: task '$TASK_FILTER' not found under $TASKS_DIR" >&2
    exit 1
  fi
  run_task "$TASK_FILTER"
else
  # Sorted iteration so 01- runs before 02- before 03-.
  while IFS= read -r task_path; do
    task_id="$(basename "$task_path")"
    run_task "$task_id"
  done < <(find "$TASKS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
fi
