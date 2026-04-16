#!/usr/bin/env bash
# Claude Mind — Stop hook
# Synthesizes the session transcript into ./brain/_journal.md
# Fails closed: never errors the user's session.
#
# Reads hook input as JSON on stdin (Claude Code passes hook payloads this way).
# Schema: { session_id, transcript_path, cwd, stop_hook_active }

set -uo pipefail

LOG_TO_BRAIN_ERRORS() {
  if [ -d ./brain ]; then
    printf '[%s] stop.sh: %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$1" >> ./brain/_errors.log
  fi
}

# Read hook input (JSON on stdin)
INPUT=$(cat)

# Parse transcript_path from JSON. Prefer jq; fall back to python3.
if command -v jq >/dev/null 2>&1; then
  TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
  TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
  d=json.load(sys.stdin)
  print(d.get("transcript_path",""))
except Exception:
  pass' 2>/dev/null)
else
  TRANSCRIPT_PATH=""
fi

# Fail closed: silent exit if anything missing
[ -z "${TRANSCRIPT_PATH:-}" ] && exit 0
[ ! -r "$TRANSCRIPT_PATH" ] && exit 0
[ ! -d ./brain ] && exit 0
command -v claude >/dev/null 2>&1 || exit 0

PROMPT_FILE="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}/hooks/prompts/synthesis.md"
[ ! -r "$PROMPT_FILE" ] && {
  LOG_TO_BRAIN_ERRORS "missing synthesis prompt: $PROMPT_FILE"
  exit 0
}

# Run synthesis. Combine prompt + transcript on stdin so we don't need shell-arg juggling.
SYNTHESIS_INPUT="$(cat "$PROMPT_FILE"; printf '\n\n--- TRANSCRIPT ---\n\n'; cat "$TRANSCRIPT_PATH")"

if ! OUTPUT=$(printf '%s' "$SYNTHESIS_INPUT" | claude -p "Synthesize per the instructions above." 2>/dev/null); then
  LOG_TO_BRAIN_ERRORS "claude CLI failed during synthesis"
  exit 0
fi

printf '\n%s\n' "$OUTPUT" >> ./brain/_journal.md
exit 0
