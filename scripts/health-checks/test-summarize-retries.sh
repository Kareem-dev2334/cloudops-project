#!/bin/bash
set -euo pipefail

test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT

printf '%s\n' 'Result: 0' 'Result: 1' 'Result: 0' > "$test_dir/input.log"

SUMMARY_LOG_FILE="$test_dir/summary.log" \
    bash scripts/health-checks/summarize-retries.sh "$test_dir/input.log"

grep -F 'Total: 3 | Passed: 2 | Failed: 1' "$test_dir/summary.log"
echo "Summary test passed"
