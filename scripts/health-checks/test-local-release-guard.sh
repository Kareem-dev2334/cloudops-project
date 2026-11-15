#!/bin/bash
set -euo pipefail

test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT

cat > "$test_dir/sudo" <<'MOCK'
#!/bin/bash
printf '%s\n' "$*" >> "$CALLS_LOG"

if [ "$*" = "docker compose -p cloudops-release-lab ps -aq" ]; then
    printf '%s\n' 'existing-container'
    exit 0
fi

echo "Unexpected command: $*" >&2
exit 97
MOCK
chmod u+x "$test_dir/sudo"

status=0
PATH="$test_dir:$PATH" CALLS_LOG="$test_dir/calls.log" \
    bash scripts/health-checks/local-release-check.sh \
    > "$test_dir/output.log" 2>&1 || status=$?

test "$status" -eq 1
grep -Fx 'Lab containers already exist; refusing to remove them' "$test_dir/output.log"
test "$(cat "$test_dir/calls.log")" = 'docker compose -p cloudops-release-lab ps -aq'

echo "Safety guard test passed"
