#!/bin/bash
set -euo pipefail

test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT

cp scripts/health-checks/retry-http-check.sh "$test_dir/"

cat > "$test_dir/check-http.sh" <<'EOF'
#!/bin/bash
printf '%s\n' 'called' >> "$TEST_CALLS_FILE"
if [ "$(wc -l < "$TEST_CALLS_FILE")" -eq 1 ]; then
    exit 1
fi
exit 0
EOF

TEST_CALLS_FILE="$test_dir/calls.log" \
RETRY_LOG_FILE="$test_dir/retry.log" \
    bash "$test_dir/retry-http-check.sh" "http://127.0.0.1:8080/health"

test "$(wc -l < "$test_dir/calls.log")" -eq 2
grep -E 'Result: 0 +Attempt: 2 *$' "$test_dir/retry.log"
echo "Retry recovery test passed"
