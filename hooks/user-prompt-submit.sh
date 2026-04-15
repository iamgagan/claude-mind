#!/usr/bin/env bash
# Claude Mind — UserPromptSubmit hook
# Spawns signal-detector subprocess; returns immediately. Never blocks.

set -uo pipefail

# Skip if no brain in this repo
[ ! -d ./brain ] && exit 0

# Skip if signal-detector model unavailable
command -v claude >/dev/null 2>&1 || exit 0

PROMPT_FILE="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}/hooks/prompts/signal-detector.md"
[ ! -r "$PROMPT_FILE" ] && exit 0

# Read user prompt from stdin
USER_PROMPT=$(cat)

# Spawn subprocess; redirect output; disown so this hook returns immediately.
{
  COMBINED="$(cat "$PROMPT_FILE"; printf '\n\n--- USER PROMPT ---\n\n%s\n' "$USER_PROMPT")"
  if SIGNAL_JSON=$(printf '%s' "$COMBINED" | claude -p --model claude-haiku-4-5 "Extract signals." 2>/dev/null); then
    printf '%s | %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$SIGNAL_JSON" >> ./brain/_signals.md
  else
    printf '[%s] signal-detector failed\n' "$(date '+%Y-%m-%dT%H:%M:%S')" >> ./brain/_errors.log
  fi
} >/dev/null 2>&1 &

disown
exit 0
