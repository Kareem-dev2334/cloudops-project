#!/bin/bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT

check_case() {
    local expected_code="$1"
    local expected_message="$2"
    shift 2

    local status=0
    bash "$script_dir/verify-paused-rollback.sh" "$@" \
        > "$test_dir/output.log" 2>&1 || status=$?

    if [ "$status" -ne "$expected_code" ]; then
        cat "$test_dir/output.log"
        echo "Expected exit $expected_code, got $status" >&2
        return 1
    fi

    grep -Fx -- "$expected_message" "$test_dir/output.log"
}

check_case 0 \
    "Rollback configuration verified; live recovery not tested" \
    6 6 0 0 0 COMPLETED

check_case 1 \
    "Keep the change open: missing or invalid revision or task count" \
    6 6 0 0 "" COMPLETED

check_case 1 \
    "Keep the change open: expected revision 6, found 7" \
    6 7 0 0 0 COMPLETED

check_case 1 \
    "Keep the change open: rollout state is FAILED" \
    6 6 0 0 0 FAILED

check_case 1 \
    "Keep the change open: 1 task(s) still pending" \
    6 6 0 0 1 COMPLETED

check_case 1 \
    "Keep the change open: desired=0, running=1" \
    6 6 0 1 0 COMPLETED

check_case 1 \
    "Keep the change open: desired=1, running=0" \
    6 6 1 0 0 COMPLETED

echo "Paused rollback tests passed"
