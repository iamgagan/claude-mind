#!/usr/bin/env bash
# Aggregate benchmark/results/*.json into a markdown comparison table.
#
# Usage:
#   ./benchmark/report.sh > BENCHMARK.md
#
# For each (task_id, mode) pair, only the LATEST result is kept (so a
# re-run replaces a prior run). Requires jq and awk.
#
# This script avoids bash 4 features (associative arrays) so it runs on
# the system bash that ships with macOS (3.2).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: report.sh requires jq. Install with 'brew install jq'." >&2
  exit 1
fi

shopt -s nullglob
result_files=( "$RESULTS_DIR"/*.json )
shopt -u nullglob

if [[ ${#result_files[@]} -eq 0 ]]; then
  echo "# Benchmark Report"
  echo
  echo "_No results found in \`benchmark/results/\`. Run \`./benchmark/run.sh --mode baseline\` and \`./benchmark/run.sh --mode plugin\` first._"
  exit 0
fi

# --- load + dedupe (keep latest per task_id × mode) ---------------------------
# Each line: task_id<TAB>mode<TAB>timestamp<TAB>duration<TAB>passed<TAB>diff
records="$(
  jq -r '
    [.task_id, .mode, .timestamp,
     (.duration_seconds|tostring),
     (.test_passed|tostring),
     (.diff_lines|tostring)]
    | @tsv
  ' "${result_files[@]}"
)"

# Sort by timestamp ascending; awk keeps the LAST seen per (task,mode);
# then sort the surviving rows for stable output.
latest="$(
  printf '%s\n' "$records" \
    | sort -t $'\t' -k3,3 \
    | awk -F'\t' '{ key = $1 "|" $2; rec[key] = $0 } END { for (k in rec) print rec[k] }' \
    | sort -t $'\t' -k1,1 -k2,2
)"

# --- build per-task lookup using temp files (no bash 4 assoc arrays) ---------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Write one file per (task,mode) so we can shell-lookup by filename.
while IFS=$'\t' read -r task mode ts dur passed diff; do
  [[ -z "$task" ]] && continue
  printf '%s\t%s\t%s\n' "$dur" "$passed" "$diff" > "$TMP/${task}__${mode}.tsv"
done <<< "$latest"

# All task ids in stable order.
all_tasks="$(printf '%s\n' "$latest" | awk -F'\t' '{print $1}' | sort -u)"

format_cell() {
  # $1 = path to .tsv (or empty if missing)
  local path="$1"
  if [[ ! -s "$path" ]]; then
    echo "(no run)"
    return
  fi
  local dur passed diff marker
  IFS=$'\t' read -r dur passed diff < "$path"
  marker="FAIL"
  if [[ "$passed" == "true" ]]; then
    marker="PASS"
  fi
  echo "$marker / ${dur}s / ${diff} lines"
}

generated_at="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

# --- header -------------------------------------------------------------------
cat <<EOF
# Benchmark Report

Generated: $generated_at

| Task | Baseline (pass / time / diff) | Plugin (pass / time / diff) | Δ Diff |
|------|-------------------------------|------------------------------|--------|
EOF

# --- per-task rows + running totals ------------------------------------------
baseline_runs=0
plugin_runs=0
baseline_pass_count=0
plugin_pass_count=0
baseline_dur_sum="0"
plugin_dur_sum="0"
baseline_diff_sum=0
plugin_diff_sum=0

while IFS= read -r task; do
  [[ -z "$task" ]] && continue

  bpath="$TMP/${task}__baseline.tsv"
  ppath="$TMP/${task}__plugin.tsv"

  baseline_cell="$(format_cell "$bpath")"
  plugin_cell="$(format_cell "$ppath")"

  # Δ Diff column: plugin diff − baseline diff. Only computed if both ran.
  if [[ -s "$bpath" && -s "$ppath" ]]; then
    bdiff="$(awk -F'\t' '{print $3}' < "$bpath")"
    pdiff="$(awk -F'\t' '{print $3}' < "$ppath")"
    delta=$((pdiff - bdiff))
    if [[ $delta -gt 0 ]]; then
      delta_cell="+${delta}"
    else
      delta_cell="$delta"
    fi
  else
    delta_cell="-"
  fi

  echo "| $task | $baseline_cell | $plugin_cell | $delta_cell |"

  # Tally aggregates.
  if [[ -s "$bpath" ]]; then
    baseline_runs=$((baseline_runs + 1))
    IFS=$'\t' read -r dur passed diff < "$bpath"
    [[ "$passed" == "true" ]] && baseline_pass_count=$((baseline_pass_count + 1))
    baseline_dur_sum="$(python3 -c "print(${baseline_dur_sum} + ${dur})")"
    baseline_diff_sum=$((baseline_diff_sum + diff))
  fi
  if [[ -s "$ppath" ]]; then
    plugin_runs=$((plugin_runs + 1))
    IFS=$'\t' read -r dur passed diff < "$ppath"
    [[ "$passed" == "true" ]] && plugin_pass_count=$((plugin_pass_count + 1))
    plugin_dur_sum="$(python3 -c "print(${plugin_dur_sum} + ${dur})")"
    plugin_diff_sum=$((plugin_diff_sum + diff))
  fi
done <<< "$all_tasks"

# --- aggregate block ----------------------------------------------------------
echo
echo "## Aggregate"
echo

if [[ $baseline_runs -gt 0 ]]; then
  baseline_pct=$((100 * baseline_pass_count / baseline_runs))
  baseline_avg_dur="$(python3 -c "print(f'{${baseline_dur_sum} / ${baseline_runs}:.1f}')")"
  baseline_avg_diff="$(python3 -c "print(f'{${baseline_diff_sum} / ${baseline_runs}:.1f}')")"
  echo "- **Baseline**: ${baseline_pct}% pass (${baseline_pass_count}/${baseline_runs}), avg duration ${baseline_avg_dur}s, avg diff ${baseline_avg_diff} lines"
else
  echo "- **Baseline**: no runs recorded"
fi

if [[ $plugin_runs -gt 0 ]]; then
  plugin_pct=$((100 * plugin_pass_count / plugin_runs))
  plugin_avg_dur="$(python3 -c "print(f'{${plugin_dur_sum} / ${plugin_runs}:.1f}')")"
  plugin_avg_diff="$(python3 -c "print(f'{${plugin_diff_sum} / ${plugin_runs}:.1f}')")"
  echo "- **Plugin**:   ${plugin_pct}% pass (${plugin_pass_count}/${plugin_runs}), avg duration ${plugin_avg_dur}s, avg diff ${plugin_avg_diff} lines"
else
  echo "- **Plugin**: no runs recorded"
fi

if [[ $baseline_runs -eq 0 || $plugin_runs -eq 0 ]]; then
  echo
  echo "> **Note**: results for one mode are missing. Run both \`./benchmark/run.sh --mode baseline\` and \`./benchmark/run.sh --mode plugin\` to enable comparison."
fi

# --- disclaimer ---------------------------------------------------------------
cat <<'EOF'

## Disclaimer

- **Sample size**: 3 tasks is not statistically significant. Treat differences smaller than ~5 percentage points (or a handful of diff lines) as noise.
- **Variance**: a single run per (task, mode) is high-variance. Re-run multiple times before drawing conclusions.
- **Coverage**: this harness measures task success, wall-clock time, and diff size. It does NOT measure token usage, "taste", or hook firing in non-interactive mode.
- **Baseline integrity**: results are only meaningful if the plugin was actually disabled for `--mode baseline`. Verify with `claude plugins list` before each run.
EOF
