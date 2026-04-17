#!/usr/bin/env bash
# claude-mind benchmark v0.2 report — SCAFFOLD.
#
# Aggregates benchmark/results/v0.2/*.json into mean ± stddev, 95% CI,
# and a significance test vs the baseline mode. Stats are stubbed with
# TODO(v0.2): markers; the output shape is correct but the confidence
# intervals and p-values are placeholders until implemented.
#
# Usage:
#   ./benchmark/v0.2/report.sh [--task <task-id>] [--metric <name>]
#
# Metrics: duration_seconds (default), diff_lines, files_touched,
#          tool_call_count.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_DIR="$REPO_ROOT/benchmark/results/v0.2"

TASK_FILTER=""
METRIC="duration_seconds"

usage() {
  cat >&2 <<'EOF'
Usage: report.sh [--task <task-id>] [--metric <name>]

  --task    Restrict to one task id.
  --metric  One of: duration_seconds (default), diff_lines, files_touched,
            tool_call_count, thinking_block_count.
  -h, --help
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task)
      TASK_FILTER="${2:-}"
      shift 2
      ;;
    --metric)
      METRIC="${2:-}"
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

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: report.sh requires jq" >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: report.sh requires python3" >&2
  exit 1
fi

if [[ ! -d "$RESULTS_DIR" ]]; then
  echo "# v0.2 Benchmark Report"
  echo
  echo "_No v0.2 results directory at \`$RESULTS_DIR\`. Run \`./benchmark/v0.2/run.sh\` first._"
  exit 0
fi

shopt -s nullglob
result_files=( "$RESULTS_DIR"/*.json )
shopt -u nullglob

if [[ ${#result_files[@]} -eq 0 ]]; then
  echo "# v0.2 Benchmark Report"
  echo
  echo "_No result JSONs in \`$RESULTS_DIR\`._"
  exit 0
fi

# --- filter + flatten ---------------------------------------------------------
# Emit TSV: task<TAB>mode<TAB>value
TSV="$(mktemp)"
trap 'rm -f "$TSV"' EXIT

for f in "${result_files[@]}"; do
  jq -r --arg metric "$METRIC" --arg task_filter "$TASK_FILTER" '
    select(($task_filter == "") or (.task_id == $task_filter))
    | [.task_id, .mode, (.[$metric] | tostring)]
    | @tsv
  ' "$f" >> "$TSV"
done

if [[ ! -s "$TSV" ]]; then
  echo "# v0.2 Benchmark Report"
  echo
  echo "_No rows matched filter task='$TASK_FILTER'._"
  exit 0
fi

# --- per-(task,mode) stats ---------------------------------------------------
# Defer to python3 for mean/stddev/CI/significance; the output structure is
# stable regardless of whether the TODO stats are filled in.
python3 - "$TSV" "$METRIC" <<'PY'
import sys, csv, math, statistics
from collections import defaultdict

_, tsv_path, metric = sys.argv

groups = defaultdict(list)
with open(tsv_path) as fh:
    for row in csv.reader(fh, delimiter="\t"):
        if len(row) != 3:
            continue
        task, mode, raw = row
        try:
            groups[(task, mode)].append(float(raw))
        except ValueError:
            # Non-numeric metric (e.g. boolean test_passed). Skip.
            pass

print(f"# v0.2 Benchmark Report — metric: {metric}")
print()
print("| Task | Mode | n | mean | stddev | 95% CI | p vs baseline |")
print("|---|---|---|---|---|---|---|")

tasks = sorted({t for (t, _m) in groups})

for task in tasks:
    baseline = groups.get((task, "baseline"), [])
    plugin   = groups.get((task, "plugin"),   [])

    for mode, vals in (("baseline", baseline), ("plugin", plugin)):
        n = len(vals)
        if n == 0:
            print(f"| {task} | {mode} | 0 | - | - | - | - |")
            continue
        mean = statistics.fmean(vals)
        sd   = statistics.stdev(vals) if n >= 2 else 0.0

        # TODO(v0.2): real 95% CI. Options:
        #   (a) t-distribution CI: mean ± t_{0.975, n-1} · sd / sqrt(n)
        #   (b) bootstrap CI: resample vals 10_000x with replacement.
        # Placeholder: +/- sd (roughly 68% CI), clearly labeled.
        ci_lo = mean - sd
        ci_hi = mean + sd
        ci_str = f"[{ci_lo:.2f}, {ci_hi:.2f}] (TODO real CI)"

        # TODO(v0.2): Welch's two-sample t-test baseline vs plugin.
        # scipy is not guaranteed available; implement by hand:
        #   t = (m1 - m2) / sqrt(s1^2/n1 + s2^2/n2)
        #   df via Welch-Satterthwaite, p from t-dist survival function.
        # For now, only report a p-value when this row is the plugin row
        # and a baseline row exists for the same task.
        p_str = "-"
        if mode == "plugin" and baseline:
            # TODO(v0.2): compute p. Placeholder NaN-marker.
            p_str = "TODO"

        print(f"| {task} | {mode} | {n} | {mean:.2f} | {sd:.2f} | {ci_str} | {p_str} |")

print()
print("## Notes")
print()
print("- **TODO(v0.2)**: replace placeholder CI (mean ± sd) with either a")
print("  t-distribution CI or a bootstrap CI (10k resamples).")
print("- **TODO(v0.2)**: implement Welch's t-test for the p-value column.")
print("- Minimum n for detecting a 20% duration delta at alpha=0.05 with")
print("  80% power is roughly 12-15 on low-variance tasks and ~60 on the")
print("  highest-variance v0.1 task. See `benchmark/v0.2/README.md`.")
PY
