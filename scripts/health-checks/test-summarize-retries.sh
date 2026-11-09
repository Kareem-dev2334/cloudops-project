#!/bin/bash
set -euo pipefail

test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT

printf '%s\n' \
    'Result: 0  Attempt: 1' \
    'Result: 1  Attempt: 3' \
    'Result: 0  Attempt: 2' > "$test_dir/input.log"

SUMMARY_LOG_FILE="$test_dir/summary.log" \
    bash scripts/health-checks/summarize-retries.sh "$test_dir/input.log"

grep -E 'Total: 3 \| Passed: 2 \| Failed: 1 .* \| Passed after retry: 1$' "$test_dir/summary.log"
echo "Summary test passed"
