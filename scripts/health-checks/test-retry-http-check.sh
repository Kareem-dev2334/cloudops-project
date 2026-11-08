#!/bin/bash
set -euo pipefail

test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT

cp scripts/health-checks/retry-http-check.sh "$test_dir/"

cat > "$test_dir/check-http.sh" <<'EOF'
#!/bin/bash
printf '%s\n' 'called' >> "$TEST_CALLS_FILE"

if [ "$(wc -l < "$TEST_CALLS_FILE")" -eq 1 ]; then
    printf '%s\n' 'HTTP 000 | Total: 0.010000s'
    exit 1
fi

printf '%s\n' 'HTTP 200 | Total: 0.125000s'
exit 0
EOF

TEST_CALLS_FILE="$test_dir/calls.log" \
RETRY_LOG_FILE="$test_dir/retry.log" \
    bash "$test_dir/retry-http-check.sh" "http://127.0.0.1:8080/health" 2> "$test_dir/stderr.log"

test "$(wc -l < "$test_dir/calls.log")" -eq 2
grep -E 'HTTP 200 \| Total: 0\.125000s \| Result: 0 +Attempt: 2 *$' "$test_dir/retry.log"
grep -Fx 'Warning: healthy response took 0.125000s (threshold: 0.100s)' "$test_dir/stderr.log"
echo "Retry recovery test passed"
