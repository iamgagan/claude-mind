#!/usr/bin/env bash
# SDK probe runner. Seeds an isolated ./brain/ in a tmp dir, runs probe.ts
# in that dir, waits for async hook subprocesses, then reports whether the
# claude-mind plugin's hooks wrote anything to brain/_signals.md (UserPromptSubmit)
# or brain/_journal.md (Stop).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set up isolated test brain
TMP="$(mktemp -d -t sdk-probe-XXXXXX)"
mkdir -p "$TMP/brain"/{people,companies,concepts,decisions,errors,references}
touch "$TMP/brain/_journal.md" "$TMP/brain/_signals.md" "$TMP/brain/_errors.log"

echo "=== probe setup ==="
echo "tmp dir:      $TMP"
echo "brain seeded:"
ls "$TMP/brain/"

echo ""
echo "=== running probe ==="
cd "$TMP"
bun run "$SCRIPT_DIR/probe.ts"

echo ""
echo "=== waiting 30s for async hooks (UserPromptSubmit signal-detector is disowned) ==="
sleep 30

echo ""
echo "=== HOOK FIRING REPORT ==="
echo ""
echo "_signals.md (UserPromptSubmit hook should write here):"
if [ -s "$TMP/brain/_signals.md" ]; then
  echo "  [PASS] NOT EMPTY -- hook fired!"
  echo "  --- contents ---"
  cat "$TMP/brain/_signals.md"
  echo "  --- end ---"
else
  echo "  [FAIL] EMPTY -- UserPromptSubmit hook did not fire"
fi

echo ""
echo "_journal.md (Stop hook should write here):"
if [ -s "$TMP/brain/_journal.md" ]; then
  echo "  [PASS] NOT EMPTY -- hook fired!"
  echo "  --- contents (first 60 lines) ---"
  head -60 "$TMP/brain/_journal.md"
  echo "  --- end ---"
else
  echo "  [FAIL] EMPTY -- Stop hook did not fire"
fi

echo ""
echo "_errors.log (any errors during hook execution):"
if [ -s "$TMP/brain/_errors.log" ]; then
  cat "$TMP/brain/_errors.log"
else
  echo "  (empty)"
fi

echo ""
echo "tmp dir preserved at: $TMP"
echo "(rm -rf when done inspecting)"
