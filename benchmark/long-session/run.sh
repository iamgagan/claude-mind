#!/usr/bin/env bash
# Long-session benchmark runner (SCAFFOLD).
#
# Usage:
#   ./benchmark/long-session/run.sh --scenario <name> --mode <baseline|plugin>
#
# Reads a scenario file (benchmark/long-session/scenarios/<name>.md), extracts
# each `### Turn N` prompt, and replays them as a single multi-turn
# conversation. After every turn it snapshots ./brain/ and records a per-turn
# metrics row (duration + token usage).
#
# STATUS: This is a scaffold. Conversation-state wiring, token parsing, and
# deterministic-replay seeding are all stubbed. Running this today will
# produce directories and timing numbers, but NOT a valid benchmark.
# The parent README.md calls out every TODO.
#
# Design notes live in benchmark/long-session/README.md.

set -euo pipefail

# --- locate ourselves ---------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCENARIOS_DIR="$SCRIPT_DIR/scenarios"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_ROOT="$REPO_ROOT/benchmark/results/long-session"
FIXTURE_DIR="$SCRIPT_DIR/fixture-repo"   # TODO: fixture repo not yet created

# --- arg parsing --------------------------------------------------------------
SCENARIO=""
MODE=""
DRY_RUN=0

usage() {
  cat <<EOF >&2
Usage: $0 --scenario <name> --mode <baseline|plugin> [--dry-run]

  --scenario   name of a file under scenarios/ (without .md)
  --mode       baseline (plugin disabled) or plugin (plugin enabled)
  --dry-run    parse the scenario and print the turns; do not invoke claude
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scenario) SCENARIO="${2:-}"; shift 2 ;;
    --mode)     MODE="${2:-}"; shift 2 ;;
    --dry-run)  DRY_RUN=1; shift ;;
    -h|--help)  usage ;;
    *) echo "Unknown argument: $1" >&2; usage ;;
  esac
done

[[ -z "$SCENARIO" || -z "$MODE" ]] && usage
if [[ "$MODE" != "baseline" && "$MODE" != "plugin" ]]; then
  echo "--mode must be 'baseline' or 'plugin' (got: $MODE)" >&2
  exit 2
fi

SCENARIO_FILE="$SCENARIOS_DIR/${SCENARIO}.md"
if [[ ! -r "$SCENARIO_FILE" ]]; then
  echo "ERROR: scenario file not found: $SCENARIO_FILE" >&2
  exit 1
fi

# --- prerequisites ------------------------------------------------------------
if [[ "$DRY_RUN" -eq 0 ]] && ! command -v claude >/dev/null 2>&1; then
  echo "ERROR: 'claude' CLI not found on PATH" >&2
  exit 1
fi

# --- helpers ------------------------------------------------------------------

# Extract turn prompts from the scenario file.
# Expected format (see scenarios/README.md):
#   ### Turn N
#   **Prompt:** `literal prompt text`
# Emits one line per turn: "<N>\t<prompt>"
extract_turns() {
  local file="$1"
  # awk walks the file in order; when it sees a `### Turn N` heading it records
  # N, and the next `**Prompt:**` line's backticked content becomes that turn's
  # prompt. Non-greedy single-backtick match. Newlines inside a prompt are not
  # supported (scenarios/README.md says keep prompts on one line).
  awk '
    /^### Turn [0-9]+/ {
      match($0, /[0-9]+/)
      turn = substr($0, RSTART, RLENGTH)
      next
    }
    turn && /^\*\*Prompt:\*\*/ {
      # strip everything before the first backtick and after the last backtick
      line = $0
      sub(/^[^`]*`/, "", line)
      sub(/`[^`]*$/, "", line)
      printf "%s\t%s\n", turn, line
      turn = ""
    }
  ' "$file"
}

# Snapshot ./brain/ into results/<scenario>/<mode>/turn-<n>-brain.tar.gz.
snapshot_brain() {
  local turn="$1"
  local out_dir="$2"
  local out_file
  out_file="$(printf '%s/turn-%02d-brain.tar.gz' "$out_dir" "$turn")"
  if [[ -d "$REPO_ROOT/brain" ]]; then
    tar -C "$REPO_ROOT" -czf "$out_file" brain 2>/dev/null || true
  else
    # Still write an empty marker so turns align 1:1 with files.
    : > "${out_file%.tar.gz}.absent"
  fi
}

# Record a per-turn metrics row. Schema is CSV so downstream tooling can load
# it without jq: turn,duration_seconds,input_tokens,output_tokens,exit_code.
record_turn_metrics() {
  local out_file="$1" turn="$2" duration="$3" input_tokens="$4" output_tokens="$5" exit_code="$6"
  printf '%s,%s,%s,%s,%s\n' \
    "$turn" "$duration" "$input_tokens" "$output_tokens" "$exit_code" \
    >> "$out_file"
}

# Wall-clock seconds with one decimal.
now_seconds() {
  python3 -c 'import time; print(time.time())'
}
fmt_duration() {
  python3 -c "print(f'{${2} - ${1}:.2f}')"
}

# --- reset fixture + brain to a known state -----------------------------------
# Between (scenario, mode) runs, everything the agent can mutate must be reset.
# The harness enforces this; getting it wrong silently contaminates results.
reset_state() {
  # TODO(fixture): create benchmark/long-session/fixture-repo/ and make it a
  # git repo so `git reset --hard` + `git clean -fdx` below is meaningful.
  if [[ -d "$FIXTURE_DIR/.git" ]]; then
    ( cd "$FIXTURE_DIR" && git reset --hard >/dev/null 2>&1 || true )
    ( cd "$FIXTURE_DIR" && git clean -fdx  >/dev/null 2>&1 || true )
  fi

  # Wipe the brain so each run starts empty. Only touches the plugin-managed
  # top-level brain dir at REPO_ROOT; never recurses into user data elsewhere.
  if [[ -d "$REPO_ROOT/brain" ]]; then
    # TODO: switch to a snapshot-and-restore model so we can seed a non-empty
    # brain for "warm start" experiments. For now: cold start only.
    find "$REPO_ROOT/brain" -mindepth 1 -maxdepth 1 \
      \( -name '_journal.md' -o -name '_signals.md' -o -name '_errors.log' \) \
      -delete 2>/dev/null || true
  fi
}

# --- conversation driver (STUB) -----------------------------------------------
# This is the core of the harness and it is NOT yet implemented correctly.
#
# A long-session benchmark must replay all N turns as ONE conversation so
# earlier turns remain in-context and the Stop hook runs with a real
# transcript. `claude -p` is one-shot by default. Two plausible paths:
#
#   (a) Agent SDK (python or ts): hold a Session object across turns.
#       Cleanest, but adds a Python/Node dependency to the benchmark harness.
#   (b) CLI with `--continue` / `--resume <session-id>`: the CLI supports
#       resuming a prior session. Needs careful session-id threading and
#       may interact oddly with hooks that also shell out to `claude`.
#
# Until one of those is wired up, each turn below is invoked in isolation,
# which means: no cross-turn memory beyond what the brain itself captures,
# and the Stop hook sees only the current turn's transcript. That is still
# useful for shaking out the harness plumbing, but it is NOT the experiment
# described in README.md. The flag below makes this honest.
CONVERSATION_STATE_IMPLEMENTED=0

run_turn_stub() {
  local turn="$1" prompt="$2" work_log="$3"
  local start end duration exit_code=0

  start="$(now_seconds)"

  # TODO(conversation-state): replace this one-shot call with an SDK session
  # or `claude --resume <session-id>` so prior turns stay in-context.
  # TODO(determinism): pin model version; pass --seed if/when supported.
  # TODO(fixture cwd): cd into "$FIXTURE_DIR" once the fixture exists, so the
  # plugin's hooks see a real ./brain/ relative to the agent's workdir.
  set +e
  claude -p "$prompt" \
    --permission-mode acceptEdits \
    --output-format json \
    >"$work_log" 2>>"${work_log%.log}.stderr"
  exit_code=$?
  set -e

  end="$(now_seconds)"
  duration="$(fmt_duration "$start" "$end")"

  # TODO(tokens): parse input/output tokens from the JSON output. The exact
  # field names depend on --output-format json's schema for the installed
  # claude version; we leave the extraction as jq-pending. For now, -1 means
  # "not parsed".
  local input_tokens="-1" output_tokens="-1"
  if command -v jq >/dev/null 2>&1 && [[ -s "$work_log" ]]; then
    # Best-effort: try a few likely field paths. Empty/missing -> keep -1.
    input_tokens="$(jq -r '(.usage.input_tokens // .input_tokens // -1)' "$work_log" 2>/dev/null || echo -1)"
    output_tokens="$(jq -r '(.usage.output_tokens // .output_tokens // -1)' "$work_log" 2>/dev/null || echo -1)"
    [[ -z "$input_tokens"  || "$input_tokens"  == "null" ]] && input_tokens=-1
    [[ -z "$output_tokens" || "$output_tokens" == "null" ]] && output_tokens=-1
  fi

  printf '%s\t%s\t%s\t%s\n' "$duration" "$input_tokens" "$output_tokens" "$exit_code"
}

# --- main ---------------------------------------------------------------------

OUT_DIR="$RESULTS_ROOT/$SCENARIO/$MODE"
mkdir -p "$OUT_DIR"
METRICS_FILE="$OUT_DIR/metrics.csv"
: > "$METRICS_FILE"
printf 'turn,duration_seconds,input_tokens,output_tokens,exit_code\n' >> "$METRICS_FILE"

echo "scenario: $SCENARIO"
echo "mode:     $MODE"
echo "out:      $OUT_DIR"
echo

# Parse turns up-front so a malformed scenario fails fast.
TURNS_TSV="$(extract_turns "$SCENARIO_FILE")"
if [[ -z "$TURNS_TSV" ]]; then
  echo "ERROR: no turns parsed from $SCENARIO_FILE" >&2
  exit 1
fi

TURN_COUNT="$(printf '%s\n' "$TURNS_TSV" | wc -l | tr -d ' ')"
echo "parsed $TURN_COUNT turns"

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf '%s\n' "$TURNS_TSV" | while IFS=$'\t' read -r n p; do
    printf '  turn %s: %s\n' "$n" "$p"
  done
  exit 0
fi

reset_state

if [[ "$CONVERSATION_STATE_IMPLEMENTED" -eq 0 ]]; then
  echo "WARNING: conversation-state driver is STUBBED. Each turn runs in" >&2
  echo "         isolation; this is not the real experiment. See run.sh" >&2
  echo "         TODOs and long-session/README.md before trusting results." >&2
fi

while IFS=$'\t' read -r turn prompt; do
  work_log="$OUT_DIR/turn-$(printf '%02d' "$turn").log"
  result="$(run_turn_stub "$turn" "$prompt" "$work_log")"
  IFS=$'\t' read -r duration in_tok out_tok exit_code <<<"$result"
  record_turn_metrics "$METRICS_FILE" "$turn" "$duration" "$in_tok" "$out_tok" "$exit_code"
  snapshot_brain "$turn" "$OUT_DIR"
  printf '  turn %2s  dur=%6ss  in=%s  out=%s  exit=%s\n' \
    "$turn" "$duration" "$in_tok" "$out_tok" "$exit_code"
done <<<"$TURNS_TSV"

echo
echo "done. metrics: $METRICS_FILE"
echo "      brain snapshots: $OUT_DIR/turn-*-brain.tar.gz"
