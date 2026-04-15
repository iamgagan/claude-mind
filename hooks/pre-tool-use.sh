#!/usr/bin/env bash
# Claude Mind — PreToolUse hook
# Warns if Edit/Write happens without a recent <thinking> block. Never blocks.

set -uo pipefail

GUARDED_TOOLS="Edit|Write|MultiEdit"
TOOL="${CLAUDE_TOOL_NAME:-}"

# Skip non-mutating tools
[[ ! "$TOOL" =~ ^(${GUARDED_TOOLS})$ ]] && exit 0

# No transcript? Can't check; silent.
[ -z "${CLAUDE_TRANSCRIPT_PATH:-}" ] && exit 0
[ ! -r "${CLAUDE_TRANSCRIPT_PATH}" ] && exit 0

# Look at the last ~50 lines of the transcript for a recent <thinking> block
RECENT=$(tail -n 50 "$CLAUDE_TRANSCRIPT_PATH" 2>/dev/null || true)

if ! grep -q "<thinking>" <<<"$RECENT"; then
  printf 'claude-mind: think-first reminder — no <thinking> block in the last 50 lines before this %s\n' "$TOOL" >&2
fi

exit 0
