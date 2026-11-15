#!/bin/bash
set -euo pipefail

test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT

mkdir -p "$test_dir/bin" "$test_dir/scripts/health-checks"
cp scripts/health-checks/local-release-check.sh "$test_dir/scripts/health-checks/"

cat > "$test_dir/bin/sudo" <<'MOCK'
#!/bin/bash
case "$*" in
    'docker compose -p cloudops-release-lab ps -aq') exit 0 ;;
    'docker compose -p cloudops-release-lab up -d') exit 0 ;;
    'docker compose -p cloudops-release-lab down')
        echo "Simulated Compose teardown failure" >&2
        exit 42
        ;;
    *) echo "Unexpected command: $*" >&2; exit 97 ;;
esac
MOCK
chmod u+x "$test_dir/bin/sudo"

cat > "$test_dir/scripts/health-checks/release-gate.sh" <<'MOCK'
#!/bin/bash
echo "Fake gate accepted"
exit 0
MOCK

status=0
(
    cd "$test_dir"
    PATH="$test_dir/bin:$PATH" bash scripts/health-checks/local-release-check.sh
) > "$test_dir/output.log" 2>&1 || status=$?

cat "$test_dir/output.log"
printf 'Workflow exit code: %s\n' "$status"

test "$status" -eq 1
grep -Fxq 'Fake gate accepted' "$test_dir/output.log"
grep -Fxq 'Simulated Compose teardown failure' "$test_dir/output.log"
grep -Fxq 'Compose cleanup failed' "$test_dir/output.log"

echo "Cleanup failure test passed"
