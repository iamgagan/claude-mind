#!/usr/bin/env bash
# Signal-detector component eval.
#
# For each labeled prompt in fixtures.jsonl:
#   1. Feed it to the production signal-detector prompt via `claude -p`.
#   2. Parse the JSON response.
#   3. Compare predicted (signal? category?) to expected.
#   4. Accumulate TP/FP/FN/TN and emit precision / recall / F1.
#
# Usage:
#   ./benchmark/components/signal-detector/eval.sh
#
# Requires: claude CLI on PATH, jq (or python3) for JSON parsing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

FIXTURES="$SCRIPT_DIR/fixtures.jsonl"
PROMPT_FILE="$REPO_ROOT/hooks/prompts/signal-detector.md"

# --- pre-flight ---------------------------------------------------------------

if [ ! -r "$FIXTURES" ]; then
  echo "fixtures not found: $FIXTURES" >&2
  exit 1
fi

if [ ! -r "$PROMPT_FILE" ]; then
  echo "signal-detector prompt not found: $PROMPT_FILE" >&2
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "claude CLI not on PATH" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
  echo "need jq or python3 to parse fixtures" >&2
  exit 1
fi

# --- helpers ------------------------------------------------------------------

# Read one JSON field out of a single-line JSON object.
# Usage: json_get '<json>' '.field'
json_get() {
  local blob="$1"
  local path="$2"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$blob" | jq -r "$path // empty"
  else
    # Fallback: very small python3 shim.
    printf '%s' "$blob" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
# Translate '.foo' / '.foo.bar' into dict traversal.
path = '''$path'''.lstrip('.').split('.')
cur = d
for p in path:
    if isinstance(cur, dict) and p in cur:
        cur = cur[p]
    else:
        cur = ''
        break
print(cur if cur is not None else '')
"
  fi
}

# TODO: map the model's finer-grained signal types (person / company / concept /
# constraint / error) onto the coarse eval categories (preference / decision /
# fact / rabbit-hole / none). For v0 we only check signal present/absent.
predicted_signal_from_response() {
  local response="$1"
  # The prompt promises: {"signals": [...]} on one line, no code fences.
  # TODO: strip any stray whitespace / accidental prose the model emits, then
  # jq -r '.signals | length' and return true iff >0.
  local count
  count=$(printf '%s' "$response" | jq -r '.signals | length' 2>/dev/null || echo "0")
  if [ "$count" -gt 0 ] 2>/dev/null; then
    echo "true"
  else
    echo "false"
  fi
}

# --- main loop ----------------------------------------------------------------

TP=0; FP=0; FN=0; TN=0
TOTAL=0

while IFS= read -r line; do
  [ -z "$line" ] && continue

  PROMPT=$(json_get "$line" '.prompt')
  # `// empty` treats boolean false as empty, so round-trip through tostring.
  EXPECTED=$(json_get "$line" '.expected_signal | tostring')

  if [ -z "$PROMPT" ] || [ "$EXPECTED" = "null" ] || [ -z "$EXPECTED" ]; then
    echo "skipping malformed fixture line: $line" >&2
    continue
  fi

  # Combine the production prompt with the user prompt on stdin.
  INPUT="$(cat "$PROMPT_FILE"; printf '\n\n--- USER PROMPT ---\n\n%s\n' "$PROMPT")"

  if ! RESPONSE=$(printf '%s' "$INPUT" | claude -p "Emit the JSON per the instructions above." 2>/dev/null); then
    echo "claude CLI failed on prompt: $PROMPT" >&2
    continue
  fi

  PREDICTED=$(predicted_signal_from_response "$RESPONSE")

  TOTAL=$((TOTAL + 1))
  if [ "$EXPECTED" = "true" ] && [ "$PREDICTED" = "true" ]; then
    TP=$((TP + 1))
  elif [ "$EXPECTED" = "false" ] && [ "$PREDICTED" = "true" ]; then
    FP=$((FP + 1))
  elif [ "$EXPECTED" = "true" ] && [ "$PREDICTED" = "false" ]; then
    FN=$((FN + 1))
  else
    TN=$((TN + 1))
  fi

  printf 'expected=%-5s predicted=%-5s prompt=%s\n' "$EXPECTED" "$PREDICTED" "${PROMPT:0:70}"
done < "$FIXTURES"

# --- metrics ------------------------------------------------------------------

# Guard against division-by-zero; print N/A when denominator is 0.
if [ $((TP + FP)) -gt 0 ]; then
  PRECISION=$(awk "BEGIN {printf \"%.3f\", $TP / ($TP + $FP)}")
else
  PRECISION="N/A"
fi

if [ $((TP + FN)) -gt 0 ]; then
  RECALL=$(awk "BEGIN {printf \"%.3f\", $TP / ($TP + $FN)}")
else
  RECALL="N/A"
fi

if [ "$PRECISION" != "N/A" ] && [ "$RECALL" != "N/A" ] && [ "$(awk "BEGIN {print ($PRECISION + $RECALL > 0)}")" = "1" ]; then
  F1=$(awk "BEGIN {p=$PRECISION; r=$RECALL; printf \"%.3f\", (2*p*r)/(p+r)}")
else
  F1="N/A"
fi

printf '\n'
printf '=== signal-detector eval ===\n'
printf 'total:     %d\n' "$TOTAL"
printf 'TP / FP:   %d / %d\n' "$TP" "$FP"
printf 'FN / TN:   %d / %d\n' "$FN" "$TN"
printf 'precision: %s\n' "$PRECISION"
printf 'recall:    %s\n' "$RECALL"
printf 'F1:        %s\n' "$F1"
