#!/usr/bin/env bash
# Claude Mind — Stop hook
# Synthesizes the session transcript into ./brain/_journal.md
# Fails closed: never errors the user's session.

set -uo pipefail

LOG_TO_BRAIN_ERRORS() {
  if [ -d ./brain ]; then
    printf '[%s] stop.sh: %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$1" >> ./brain/_errors.log
  fi
}

# Exit silently if nothing to do
[ -z "${CLAUDE_TRANSCRIPT_PATH:-}" ] && exit 0
[ ! -r "${CLAUDE_TRANSCRIPT_PATH}" ] && exit 0
[ ! -d ./brain ] && exit 0
command -v claude >/dev/null 2>&1 || exit 0

PROMPT_FILE="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}/hooks/prompts/synthesis.md"
[ ! -r "$PROMPT_FILE" ] && {
  LOG_TO_BRAIN_ERRORS "missing synthesis prompt: $PROMPT_FILE"
  exit 0
}

# Run synthesis. Combine prompt + transcript on stdin so we don't need shell-arg juggling.
SYNTHESIS_INPUT="$(cat "$PROMPT_FILE"; printf '\n\n--- TRANSCRIPT ---\n\n'; cat "$CLAUDE_TRANSCRIPT_PATH")"

if ! OUTPUT=$(printf '%s' "$SYNTHESIS_INPUT" | claude -p "Synthesize per the instructions above." 2>/dev/null); then
  LOG_TO_BRAIN_ERRORS "claude CLI failed during synthesis"
  exit 0
fi

printf '\n%s\n' "$OUTPUT" >> ./brain/_journal.md
exit 0
