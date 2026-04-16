#!/usr/bin/env bash
# Claude Mind — PreToolUse hook
# Warns if Edit/Write/MultiEdit happens without a recent <thinking> block. Never blocks.
#
# Reads hook input as JSON on stdin (Claude Code passes hook payloads this way).
# Schema: { session_id, transcript_path, cwd, tool_name, tool_input }

set -uo pipefail

GUARDED_TOOLS="Edit|Write|MultiEdit"

# Read hook input (JSON on stdin)
INPUT=$(cat)

# Parse tool_name + transcript_path from JSON. Prefer jq; fall back to python3.
if command -v jq >/dev/null 2>&1; then
  TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
  TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
  TOOL=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
  d=json.load(sys.stdin)
  print(d.get("tool_name",""))
except Exception:
  pass' 2>/dev/null)
  TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
  d=json.load(sys.stdin)
  print(d.get("transcript_path",""))
except Exception:
  pass' 2>/dev/null)
else
  TOOL=""
  TRANSCRIPT_PATH=""
fi

# Skip non-mutating tools
[[ ! "$TOOL" =~ ^(${GUARDED_TOOLS})$ ]] && exit 0

# No transcript? Can't check; silent.
[ -z "${TRANSCRIPT_PATH:-}" ] && exit 0
[ ! -r "${TRANSCRIPT_PATH}" ] && exit 0

# Look at the last ~50 lines of the transcript for a recent <thinking> block
RECENT=$(tail -n 50 "$TRANSCRIPT_PATH" 2>/dev/null || true)

if ! grep -q "<thinking>" <<<"$RECENT"; then
  printf 'claude-mind: think-first reminder — no <thinking> block in the last 50 lines before this %s\n' "$TOOL" >&2
fi

exit 0
